import 'dart:io';

import 'package:flutter/material.dart';

import '../open_link.dart';

Future<void> openManageSubscriptions(BuildContext context) async {
  final uri = Platform.isIOS
      ? Uri.parse('https://apps.apple.com/account/subscriptions')
      : Uri.parse('https://play.google.com/store/account/subscriptions');
  await openAppLink(context, uri);
}
