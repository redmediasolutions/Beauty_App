import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static final _remoteConfig = FirebaseRemoteConfig.instance;

  static Future<void> init() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );

    await _remoteConfig.fetchAndActivate();
  }

  static String getProductCategories() {
    return _remoteConfig.getString('productcategories');
  }
}