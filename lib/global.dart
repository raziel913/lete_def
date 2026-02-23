import 'package:package_info_plus/package_info_plus.dart';

class Globals {
  static String? version;  // Ora è pubblica
  static String globalAPI = "http://10.10.14.142:8069";
  static String globalToken = "acquaLete";


  static Future<void> initializeGlobals() async {
    await checkVersion();
  }

  static Future<void> checkVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    
    version =  packageInfo.version;
  }
}