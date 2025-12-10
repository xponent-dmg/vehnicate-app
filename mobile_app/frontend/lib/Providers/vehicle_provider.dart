import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';

class VehicleProvider extends ChangeNotifier {
  int? _vehicleId;
  String? _vehicleName;
  String? _vehicleModel;
  String? _vehicleInsurance;
  String? _vehicleRegistration;
  String? _vehiclePUC;
  bool _isLoading = false;
  Object? _error;

  List<Drive> _drives = [];
  List<Drive> get drives => _drives;

  // Existing vehicle data
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
        _drives = [];
        return;
      }
      print('VehicleProvider: Loading vehicle data with uid: ${user.uid}');
      await loadVehicleByUserId(user.uid);
      print('VehicleProvider(listenAuth): Vehicle data loaded with data: $_vehicleId');

      // Load drives after vehicle is loaded
      if (_vehicleId != null) {
        await loadDrives();
      }
    });
  }

  Future<void> refresh() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    print('VehicleProvider(refresh): Loading vehicle data with uid: $uid');
    if (uid == null) {
      _setVehicle(null);
      _drives = [];
      return;
    }
    await loadVehicleByUserId(uid);
    print('VehicleProvider(refresh): Vehicle data loaded with data: $_vehicleId');

    if (_vehicleId != null) {
      await loadDrives();
    }
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
      // Don't set loading false here if we are going to load drives next,
      // but in this flow we do it sequentially in listenAuth/refresh.
      // So we can set it false here, but loadDrives will set it true again.
      _isLoading = false;
      print('VehicleProvider(loadVehicleByUserId): Vehicle data loaded with data: $_vehicleId');
      notifyListeners();
    }
  }

  Future<void> loadDrives() async {
    if (_vehicleId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      print('VehicleProvider: Loading drives for vehicle $_vehicleId');
      final drivesData = await SupabaseService().fetchDrives(_vehicleId!);
      _drives = drivesData.map((data) => Drive.fromJson(data)).toList();
      print('VehicleProvider: Loaded ${_drives.length} drives');
    } catch (e) {
      print('VehicleProvider: Error loading drives: $e');
      _error = e;
    } finally {
      _isLoading = false;
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
