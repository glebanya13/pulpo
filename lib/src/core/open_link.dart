import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/tr.dart';

Future<void> openAppLink(BuildContext context, Uri uri) async {
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Tr.of(context).couldNotOpenLink)),
    );
  }
}
