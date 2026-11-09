import 'dart:convert';
import 'dart:io';

class UpdateInfo {
  final bool hasUpdate;
  final int remoteVersionCode;
  final String remoteVersionName;
  final String apkUrl;
  final String changelog;

  UpdateInfo({
    required this.hasUpdate,
    required this.remoteVersionCode,
    required this.remoteVersionName,
    required this.apkUrl,
    required this.changelog,
  });
}

class UpdateService {
  static const int currentVersionCode = 1;
  static const String currentVersionName = '1.0.0';
  static const String updateUrl =
      'https://raw.githubusercontent.com/hemantyadav1317-boop/Yadav-ka-alarm/main/version.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(updateUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final remoteCode = data['versionCode'] as int? ?? currentVersionCode;
        final remoteName = data['versionName'] as String? ?? currentVersionName;
        final apkUrl = data['apkUrl'] as String? ?? '';
        final changelog = data['changelog'] as String? ?? 'New version available!';

        return UpdateInfo(
          hasUpdate: remoteCode > currentVersionCode,
          remoteVersionCode: remoteCode,
          remoteVersionName: remoteName,
          apkUrl: apkUrl,
          changelog: changelog,
        );
      }
    } catch (_) {
      // Offline or network error - fail silently
    }
    return null;
  }
}

