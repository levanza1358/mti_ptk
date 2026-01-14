// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> triggerDownload(Uint8List bytes, String fileName) async {
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.Url.revokeObjectUrl(url);
}
