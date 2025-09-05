import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';

class VehicleProvider extends ChangeNotifier {
  int? _vehicleId;
  String? _vehicleName;
  String? _vehicleModel;
  String? _vehicleInsurance;
  String? _vehicleRegistration;
  String? _vehiclePUC;
  bool _isLoading = false;
  Object? _error;

  int? get vehicleId => _vehicleId;
  String? get vehicleName => _vehicleName;
  String? get vehicleModel => _vehicleModel;
  String? get vehicleInsurance => _vehicleInsurance;
  String? get vehicleRegistration => _vehicleRegistration;
  String? get vehiclePUC => _vehiclePUC;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  StreamSubscription<firebase.User?>? _authSub;

  VehicleProvider() {
    _listenAuth();
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = firebase.FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _setVehicle(null);
        return;
      }
      print('VehicleProvider: Loading vehicle data with uid: ${user.uid}');
      await loadVehicleByUserId(user.uid);
      print('VehicleProvider(listenAuth): Vehicle data loaded with data: $_vehicleId');
    });
  }

  Future<void> refresh() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    print('VehicleProvider(refresh): Loading vehicle data with uid: $uid');
    if (uid == null) {
      _setVehicle(null);
      return;
    }
    await loadVehicleByUserId(uid);
    print('VehicleProvider(refresh): Vehicle data loaded with data: $_vehicleId');
  }

  Future<void> loadVehicleByUserId(String? firebaseUuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    if (firebaseUuid == null) {
      _setVehicle(null);
      return;
    }
    try {
      final data = await SupabaseService().getVehicleByUserId(firebaseUuid);
      print('VehicleProvider(loadVehicleByUserId): Vehicle data loaded with data: $data');
      _setVehicle(data);
    } catch (e) {
      print('VehicleProvider(loadVehicleByUserId): Error loading vehicle data: $e');
      _error = e;
      _setVehicle(null);
    } finally {
      _isLoading = false;
      print('VehicleProvider(loadVehicleByUserId): Vehicle data loaded with data: $_vehicleId');
      notifyListeners();
    }
  }

  void _setVehicle(Map<String, dynamic>? data) {
    _vehicleId = data?['vehicleid'];
    _vehicleName = data?['name'];
    _vehicleModel = data?['model'];
    _vehicleInsurance = data?['insurance'];
    _vehicleRegistration = data?['registration'];
    _vehiclePUC = data?['puc']?.toString();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
