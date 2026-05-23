import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:vehnway/services/cache_service.dart';
import 'package:vehnway/services/supabase_service.dart';
import 'package:vehnway/models/drive_model.dart';
import 'package:vehnway/models/vehicle_model.dart';

class VehicleProvider extends ChangeNotifier {
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;
  Object? _error;

  List<Drive> _drives = [];
  List<Drive> get drives => _drives;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;

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
        CacheService().clearAuthCache();
        return;
      }
      await loadVehicleByUserId(user.uid);

      if (_selectedVehicle != null) {
        await loadDrives();
      }
    });
  }

  Future<void> refresh() async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
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

    // 1. Try Cache First
    final cachedData = CacheService().getVehicles(firebaseUuid);
    if (cachedData.isNotEmpty) {
      _vehicles = cachedData.map((json) => Vehicle.fromJson(json)).toList();
      if (_selectedVehicle == null ||
          !_vehicles.any((v) => v.id == _selectedVehicle!.id)) {
        _selectedVehicle = _vehicles.first;
      }
    }

    notifyListeners();

    try {
      final data = await SupabaseService().getVehiclesByUserId();
      _vehicles = data.map((json) => Vehicle.fromJson(json)).toList();

      if (_vehicles.isNotEmpty) {
        if (_selectedVehicle == null ||
            !_vehicles.any((v) => v.id == _selectedVehicle!.id)) {
          _selectedVehicle = _vehicles.first;
        }
        // 2. Save to Cache
        await CacheService().setVehicles(firebaseUuid, data);
      } else {
        _selectedVehicle = null;
      }
    } catch (e) {
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
      loadDrives();
    }
  }

  Future<void> loadDrives() async {
    if (_selectedVehicle == null) return;

    _isLoading = true;

    // 1. Try Cache First
    final cachedData = CacheService().getTrips(_selectedVehicle!.id);
    if (cachedData.isNotEmpty) {
      _drives = cachedData.map((data) => Drive.fromJson(data)).toList();
    }

    notifyListeners();

    try {
      final drivesData = await SupabaseService().fetchDrives(
        _selectedVehicle!.id,
      );
      _drives = drivesData.map((data) => Drive.fromJson(data)).toList();

      // 2. Save to Cache
      await CacheService().setTrips(_selectedVehicle!.id, drivesData);
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addVehicle({
    required String model,
    required String registration,
    required String insurance,
    String? puc,
  }) async {
    final uid = firebase.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not logged in');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await SupabaseService().createVehicle(
        model: model,
        registration: registration,
        insurance: insurance,
        puc: puc,
      );

      // Refresh the list to include the new vehicle
      await loadVehicleByUserId(uid);
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    _isLoading = true;
    _error = null; // Also reset error here
    notifyListeners();

    try {
      await SupabaseService().deleteVehicle(vehicleId);

      _vehicles.removeWhere((v) => v.id == vehicleId);

      if (_selectedVehicle?.id == vehicleId) {
        _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
        if (_selectedVehicle != null) {
          await loadDrives();
        } else {
          _drives = [];
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e;
      rethrow;
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
