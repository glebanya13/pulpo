import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart' as db;
import '../../data/repositories/settings_service.dart';

const _kMaxMembers = 2;
const _kSyncedTxKey = 'household_synced_tx_ids';

class HouseholdMember {
  const HouseholdMember({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    required this.joinedAt,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final DateTime joinedAt;

  factory HouseholdMember.fromMap(String uid, Map<String, dynamic> data) {
    final joined = data['joinedAt'];
    return HouseholdMember(
      uid: uid,
      displayName: (data['displayName'] as String?)?.trim() ?? 'User',
      photoUrl: data['photoUrl'] as String?,
      joinedAt: joined is Timestamp
          ? joined.toDate()
          : (joined is String ? DateTime.tryParse(joined) : null) ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };
}

class HouseholdSnapshot {
  const HouseholdSnapshot({
    required this.id,
    required this.inviteCode,
    required this.members,
    required this.memberIds,
  });

  final String id;
  final String inviteCode;
  final Map<String, HouseholdMember> members;
  final List<String> memberIds;

  bool get isFull => memberIds.length >= _kMaxMembers;

  HouseholdMember? member(String uid) => members[uid];
}

class SharedEntry {
  const SharedEntry({
    required this.id,
    required this.uid,
    required this.amount,
    required this.currency,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.note,
    required this.date,
    this.localTxId,
  });

  final String id;
  final String uid;
  final double amount;
  final String currency;
  final String categoryName;
  final String categoryIcon;
  final int categoryColor;
  final String? note;
  final DateTime date;
  final int? localTxId;

  factory SharedEntry.fromDoc(String id, Map<String, dynamic> data) {
    final rawDate = data['date'];
    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return SharedEntry(
      id: id,
      uid: data['uid'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      currency: data['currency'] as String? ?? 'EUR',
      categoryName: data['categoryName'] as String? ?? 'other',
      categoryIcon: data['categoryIcon'] as String? ?? 'circle',
      categoryColor: data['categoryColor'] as int? ?? 0xFF8A94A6,
      note: data['note'] as String?,
      date: date,
      localTxId: data['localTxId'] as int?,
    );
  }
}

class CategorySpend {
  const CategorySpend({
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });

  final String name;
  final String icon;
  final int color;
  final double amount;
}

class PartnerSettlement {
  const PartnerSettlement({
    required this.even,
    required this.youOwe,
    required this.partnerOwesYou,
    required this.currency,
    required this.yourTotal,
    required this.partnerTotal,
  });

  final bool even;
  final double youOwe;
  final double partnerOwesYou;
  final String currency;
  final double yourTotal;
  final double partnerTotal;
}

class HouseholdService {
  HouseholdService(this._ref);

  final Ref _ref;
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  String? get _uid => _auth.currentUser?.uid;

  Future<String> _displayName() async {
    final user = _auth.currentUser;
    final settings = _ref.read(settingsControllerProvider);
    final local = settings.userName.trim();
    if (local.isNotEmpty && local.toLowerCase() != 'user') return local;
    return user?.displayName?.trim() ??
        user?.email?.split('@').first ??
        'User';
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<String?> householdIdForUser() async {
    final uid = _uid;
    if (uid == null) return null;
    final snap = await _userRef(uid).get();
    return snap.data()?['householdId'] as String?;
  }

  Stream<String?> watchHouseholdId() {
    final uid = _uid;
    if (uid == null) return Stream.value(null);
    return _userRef(uid).snapshots().map(
          (s) => s.data()?['householdId'] as String?,
        );
  }

  Stream<HouseholdSnapshot?> watchHousehold(String? householdId) {
    if (householdId == null || householdId.isEmpty) {
      return Stream.value(null);
    }
    return _households.doc(householdId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data()!;
      final membersRaw = data['members'];
      final members = <String, HouseholdMember>{};
      if (membersRaw is Map) {
        for (final e in membersRaw.entries) {
          final v = e.value;
          if (v is Map<String, dynamic>) {
            members[e.key] = HouseholdMember.fromMap(e.key, v);
          } else if (v is Map) {
            members[e.key] =
                HouseholdMember.fromMap(e.key, Map<String, dynamic>.from(v));
          }
        }
      }
      final ids = (data['memberIds'] as List?)?.cast<String>() ??
          members.keys.toList();
      return HouseholdSnapshot(
        id: snap.id,
        inviteCode: data['inviteCode'] as String? ?? '',
        members: members,
        memberIds: ids,
      );
    });
  }

  Stream<List<SharedEntry>> watchEntries(String householdId) {
    return _households
        .doc(householdId)
        .collection('entries')
        .orderBy('date', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => [
              for (final d in snap.docs)
                SharedEntry.fromDoc(d.id, d.data()),
            ]);
  }

  Future<HouseholdSnapshot> createHousehold() async {
    final uid = _uid;
    if (uid == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final existing = await householdIdForUser();
    if (existing != null) {
      throw StateError('already_in_household');
    }

    final name = await _displayName();
    final photo = _auth.currentUser?.photoURL;
    var code = _randomCode();
    for (var i = 0; i < 5; i++) {
      final clash = await _db
          .collection('household_invites')
          .doc(code)
          .get();
      if (!clash.exists) break;
      code = _randomCode();
    }

    final householdRef = _households.doc();
    final now = FieldValue.serverTimestamp();
    await householdRef.set({
      'inviteCode': code,
      'memberIds': [uid],
      'memberCount': 1,
      'members': {
        uid: {
          'displayName': name,
          if (photo != null) 'photoUrl': photo,
          'joinedAt': now,
        },
      },
      'createdAt': now,
      'createdBy': uid,
    });
    await _db.collection('household_invites').doc(code).set({
      'householdId': householdRef.id,
      'createdBy': uid,
      'createdAt': now,
    });
    await _userRef(uid).set({
      'householdId': householdRef.id,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final created = await watchHousehold(householdRef.id).first;
    if (created == null) throw StateError('household_create_failed');
    return created;
  }

  Future<HouseholdSnapshot> joinHousehold(String rawCode) async {
    final uid = _uid;
    if (uid == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) throw ArgumentError('invalid_code');

    final existing = await householdIdForUser();
    if (existing != null) {
      throw StateError('already_in_household');
    }

    final invite = await _db.collection('household_invites').doc(code).get();
    if (!invite.exists) throw StateError('invite_not_found');
    final householdId = invite.data()?['householdId'] as String?;
    if (householdId == null) throw StateError('invite_not_found');

    final householdRef = _households.doc(householdId);
    final name = await _displayName();
    final photo = _auth.currentUser?.photoURL;

    await _db.runTransaction((tx) async {
      final h = await tx.get(householdRef);
      if (!h.exists) throw StateError('household_gone');
      final data = h.data()!;
      final count = data['memberCount'] as int? ?? 0;
      final ids = (data['memberIds'] as List?)?.cast<String>() ?? [];
      if (count >= _kMaxMembers || ids.length >= _kMaxMembers) {
        throw StateError('household_full');
      }
      if (ids.contains(uid)) return;
      ids.add(uid);
      final members = Map<String, dynamic>.from(
        (data['members'] as Map?)?.map(
              (k, v) => MapEntry('$k', v),
            ) ??
            {},
      );
      members[uid] = {
        'displayName': name,
        if (photo != null) 'photoUrl': photo,
        'joinedAt': FieldValue.serverTimestamp(),
      };
      tx.update(householdRef, {
        'memberIds': ids,
        'memberCount': ids.length,
        'members': members,
      });
    });

    await _userRef(uid).set({
      'householdId': householdId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final joined = await watchHousehold(householdId).first;
    if (joined == null) throw StateError('household_join_failed');
    return joined;
  }

  Future<void> leaveHousehold(String householdId) async {
    final uid = _uid;
    if (uid == null) return;

    final householdRef = _households.doc(householdId);
    await _db.runTransaction((tx) async {
      final h = await tx.get(householdRef);
      if (!h.exists) return;
      final data = h.data()!;
      final ids = ((data['memberIds'] as List?)?.cast<String>() ?? [])
          .where((id) => id != uid)
          .toList();
      final members = Map<String, dynamic>.from(
        (data['members'] as Map?)?.map(
              (k, v) => MapEntry('$k', v),
            ) ??
            {},
      );
      members.remove(uid);
      if (ids.isEmpty) {
        tx.delete(householdRef);
      } else {
        tx.update(householdRef, {
          'memberIds': ids,
          'memberCount': ids.length,
          'members': members,
        });
      }
    });

    final code = (await householdRef.get()).data()?['inviteCode'] as String?;
    if (code != null) {
      final remaining = await householdRef.get();
      if (!remaining.exists) {
        await _db.collection('household_invites').doc(code).delete();
      }
    }

    await _userRef(uid).set({
      'householdId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addEntry({
    required String householdId,
    required double amount,
    required String currency,
    required String categoryName,
    required String categoryIcon,
    required int categoryColor,
    required DateTime date,
    String? note,
    int? localTxId,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _households.doc(householdId).collection('entries').add({
      'uid': uid,
      'amount': amount,
      'currency': currency,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon,
      'categoryColor': categoryColor,
      if (note != null && note.isNotEmpty) 'note': note,
      'date': Timestamp.fromDate(date),
      if (localTxId != null) 'localTxId': localTxId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> syncLocalExpenses({
    required String householdId,
    required List<db.Transaction> txs,
    required List<db.Category> categories,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final synced = prefs.getStringList(_kSyncedTxKey)?.toSet() ?? {};
    var pushed = 0;
    final catById = {for (final c in categories) c.id: c};

    for (final t in txs) {
      if (t.date.isBefore(monthStart) || !t.date.isBefore(monthEnd)) continue;
      if (t.type != 0) continue; // expense
      final key = '${householdId}_${t.id}';
      if (synced.contains(key)) continue;
      final cat = catById[t.categoryId];
      await addEntry(
        householdId: householdId,
        amount: t.amount,
        currency: t.currency,
        categoryName: cat?.name ?? 'other',
        categoryIcon: cat?.icon ?? 'circle',
        categoryColor: cat?.color ?? 0xFF8A94A6,
        date: t.date,
        note: t.note,
        localTxId: t.id,
      );
      synced.add(key);
      pushed++;
    }
    await prefs.setStringList(_kSyncedTxKey, synced.toList());
    return pushed;
  }

  static List<CategorySpend> topCategoriesForUser(
    List<SharedEntry> entries,
    String uid, {
    int limit = 3,
  }) {
    final byCat = <String, CategorySpend>{};
    for (final e in entries) {
      if (e.uid != uid) continue;
      final key = e.categoryName;
      final prev = byCat[key];
      byCat[key] = CategorySpend(
        name: e.categoryName,
        icon: e.categoryIcon,
        color: e.categoryColor,
        amount: (prev?.amount ?? 0) + e.amount,
      );
    }
    final sorted = byCat.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    return sorted.take(limit).toList();
  }

  static PartnerSettlement settlement({
    required List<SharedEntry> entries,
    required String myUid,
    required String partnerUid,
    required String currency,
    DateTime? monthStart,
    DateTime? monthEnd,
  }) {
    var mine = 0.0;
    var theirs = 0.0;
    for (final e in entries) {
      if (monthStart != null && e.date.isBefore(monthStart)) continue;
      if (monthEnd != null && !e.date.isBefore(monthEnd)) continue;
      if (e.uid == myUid) {
        mine += e.amount;
      } else if (e.uid == partnerUid) {
        theirs += e.amount;
      }
    }
    final diff = mine - theirs;
    if (diff.abs() < 0.01) {
      return PartnerSettlement(
        even: true,
        youOwe: 0,
        partnerOwesYou: 0,
        currency: currency,
        yourTotal: mine,
        partnerTotal: theirs,
      );
    }
    if (diff > 0) {
      return PartnerSettlement(
        even: false,
        youOwe: 0,
        partnerOwesYou: diff,
        currency: currency,
        yourTotal: mine,
        partnerTotal: theirs,
      );
    }
    return PartnerSettlement(
      even: false,
      youOwe: -diff,
      partnerOwesYou: 0,
      currency: currency,
      yourTotal: mine,
      partnerTotal: theirs,
    );
  }
}

final householdServiceProvider = Provider<HouseholdService>((ref) {
  return HouseholdService(ref);
});

final householdIdProvider = StreamProvider<String?>((ref) {
  return ref.watch(householdServiceProvider).watchHouseholdId();
});

final householdSnapshotProvider = StreamProvider<HouseholdSnapshot?>((ref) {
  final id = ref.watch(householdIdProvider).valueOrNull;
  return ref.watch(householdServiceProvider).watchHousehold(id);
});

final sharedEntriesProvider = StreamProvider<List<SharedEntry>>((ref) {
  final id = ref.watch(householdIdProvider).valueOrNull;
  if (id == null) return Stream.value(const []);
  return ref.watch(householdServiceProvider).watchEntries(id);
});
