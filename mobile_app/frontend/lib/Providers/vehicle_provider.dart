import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';
import 'package:vehnicate_frontend/models/drive_model.dart';
import 'package:vehnicate_frontend/models/vehicle_model.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  Object? _error;

  List<Drive> _drives = [];
  List<Drive> get drives => _drives;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;

  // Convenience getters for backward compatibility or easy access
  int? get vehicleId => _selectedVehicle?.id;
  String? get vehicleName => _selectedVehicle?.name;
  String? get vehicleModel => _selectedVehicle?.model;
  String? get vehicleInsurance => _selectedVehicle?.insurance;
  String? get vehicleRegistration => _selectedVehicle?.registration;
  String? get vehiclePUC => _selectedVehicle?.puc;

  bool get isLoading => _isLoading;
  Object? get error => _error;

  StreamSubscription<firebase.User?>? _authSub;

  VehicleProvider() {
    _listenAuth();
  }

  void _listenAuth() {
    _authSub?.cancel();
    _authSub = firebase.FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      if (user == null) {
        _vehicles = [];
        _selectedVehicle = null;
        _drives = [];
        return;
      }
      print('VehicleProvider: Loading vehicles for uid: ${user.uid}');
      await loadVehicleByUserId(user.uid);

      // Load drives if we have a selected vehicle
      if (_selectedVehicle != null) {
        await loadDrives();
      }
    });
  }

  Future<void> refresh() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    print('VehicleProvider(refresh): Loading vehicle data with uid: $uid');
    if (uid == null) {
      _vehicles = [];
      _selectedVehicle = null;
      _drives = [];
      return;
    }
    await loadVehicleByUserId(uid);

    if (_selectedVehicle != null) {
      await loadDrives();
    }
  }

  Future<void> loadVehicleByUserId(String? firebaseUuid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (firebaseUuid == null) {
      _vehicles = [];
      _selectedVehicle = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final data = await SupabaseService().getVehiclesByUserId(firebaseUuid);
      _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();
      print(
        'VehicleProvider(loadVehicleByUserId): Loaded ${_vehicles.length} vehicles',
      );

      // Auto-select first vehicle if none selected or selection invalid
      if (_vehicles.isNotEmpty) {
        if (_selectedVehicle == null ||
            !_vehicles.any((v) => v.id == _selectedVehicle!.id)) {
          _selectedVehicle = _vehicles.first;
        }
      } else {
        _selectedVehicle = null;
      }
    } catch (e) {
      print('VehicleProvider(loadVehicleByUserId): Error loading vehicles: $e');
      _error = e;
      _vehicles = [];
      _selectedVehicle = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectVehicle(Vehicle vehicle) {
    if (_selectedVehicle?.id != vehicle.id) {
      _selectedVehicle = vehicle;
      notifyListeners();
      loadDrives(); // Reload drives for new vehicle
    }
  }

  Future<void> loadDrives() async {
    if (_selectedVehicle == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      print(
        'VehicleProvider: Loading drives for vehicle ${_selectedVehicle!.id}',
      );
      final drivesData = await SupabaseService().fetchDrives(
        _selectedVehicle!.id,
      );
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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
