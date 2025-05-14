import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    // ignore: unrelated_type_equality_checks
    return connectivityResult != ConnectivityResult.none;
  }

  static Stream<List<ConnectivityResult>> get connectivityStream {
    return Connectivity().onConnectivityChanged;
  }
}
