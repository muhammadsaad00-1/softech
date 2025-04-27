// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';
//
// class ConnectivityService {
//   // Singleton pattern
//   static final ConnectivityService _instance = ConnectivityService._internal();
//   factory ConnectivityService() => _instance;
//   ConnectivityService._internal();
//
//   final Connectivity _connectivity = Connectivity();
//   final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();
//
//   Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
//   bool _isConnected = true;
//   bool get isConnected => _isConnected;
//   bool _isInitialized = false;
//
//   Future<void> initialize() async {
//     if (_isInitialized) return;
//
//     // Check initial connection status
//     await _checkConnectivity();
//
//     // Listen for connectivity changes
//     _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> resultList) {
//       // Access the first element in the list
//       ConnectivityResult result = resultList.isNotEmpty ? resultList.first : ConnectivityResult.none;
//       _isConnected = result != ConnectivityResult.none;
//       _connectionStatusController.add(_isConnected);
//     });
//
//     _isInitialized = true;
//   }
//
//   Future<void> _checkConnectivity() async {
//     try {
//       final List<ConnectivityResult> resultList = await _connectivity.checkConnectivity();
//       // Access the first element in the list
//       ConnectivityResult result = resultList.isNotEmpty ? resultList.first : ConnectivityResult.none;
//       _isConnected = result != ConnectivityResult.none;
//       _connectionStatusController.add(_isConnected);
//     } catch (e) {
//       print("Error checking connectivity: $e");
//       _isConnected = false;
//       _connectionStatusController.add(false);
//     }
//   }
//
//   void dispose() {
//     _connectionStatusController.close();
//   }
// }
