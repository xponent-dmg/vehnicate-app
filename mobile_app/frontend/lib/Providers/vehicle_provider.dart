import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';

class VehicleProvider extends ChangeNotifier {
  String? _vehicleId;
  String? _vehicleName;
  String? _vehicleModel;
  String? _vehicleInsurance;
  String? _vehicleRegistration;
  String? _vehiclePUC;
  bool _isLoading = false;
  Object? _error;

  String? get vehicleId => _vehicleId;
  String? get vehicleName => _vehicleName;
  String? get vehicleModel => _vehicleModel;
  String? get vehicleInsurance => _vehicleInsurance;
  String? get vehicleRegistration => _vehicleRegistration;
  String? get vehiclePUC => _vehiclePUC;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  UserProvider? _userProvider;

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
    // Listen to user changes
    _userProvider!.addListener(() {
      loadVehicleByUserId(_userProvider!.currentUser?.firebaseUid);
    });
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
      if (data != null) {
        _setVehicle(data);
      } else {
        _setVehicle(null);
      }
    } catch (e) {
      _error = e;
      _setVehicle(null);
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
    _vehiclePUC = data?['puc'];
  }
}
