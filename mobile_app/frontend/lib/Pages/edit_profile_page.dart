import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehnicate_frontend/Providers/user_provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  // Deprecated: now using providers
  // Map<String, dynamic>? _userDetails;
  // Map<String, dynamic>? _vehicleDetails;
  DateTime? _pucDate;

  // User Details Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _usernameController = TextEditingController();

  // Vehicle Details Controllers
  final _insuranceController = TextEditingController();
  final _registrationController = TextEditingController();
  final _pucController = TextEditingController();
  final _modelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingData();
    });
  }

  @override
  void dispose() {
    // Dispose all controllers
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _usernameController.dispose();
    _insuranceController.dispose();
    _registrationController.dispose();
    _pucController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Ensure provider data is available (trigger load if needed)
      final userProvider = context.read<UserProvider>();
      if (userProvider.currentUser == null) {
        await userProvider.loadUserByFirebaseUid(user.uid);
      }

      final vehicleProvider = context.read<VehicleProvider>();
      if (vehicleProvider.vehicleId == null) {
        print('VehicleProvider: Vehicle ID is null, refreshing...');
        await vehicleProvider.refresh();
      }

      setState(() {
        // Populate user controllers from provider
        final appUser = userProvider.currentUser;
        _nameController.text = appUser?.name ?? '';
        _phoneController.text = appUser?.phone ?? '';
        _emailController.text = appUser?.email ?? '';
        _addressController.text = appUser?.address ?? '';
        _usernameController.text = appUser?.username ?? '';

        // Populate vehicle controllers from provider
        _modelController.text = vehicleProvider.vehicleModel ?? '';
        _registrationController.text = vehicleProvider.vehicleRegistration ?? '';
        _insuranceController.text = vehicleProvider.vehicleInsurance ?? '';
        final pucRaw = vehicleProvider.vehiclePUC;
        if (pucRaw != null && pucRaw.isNotEmpty) {
          try {
            final parsed = DateTime.parse(pucRaw);
            _pucDate = DateTime(parsed.year, parsed.month, parsed.day);
            _pucController.text = _formatDate(_pucDate!);
          } catch (_) {
            _pucController.text = pucRaw.split('T').first;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // First, update or create vehicle details using provider state
      final vehicleProvider = context.read<VehicleProvider>();
      print('EditProfilePage: Vehicle id from provider: ${vehicleProvider.vehicleId}');
      int? vehicleId = vehicleProvider.vehicleId;
      print('EditProfilePage: Vehicle ID: $vehicleId');
      if (vehicleId == null) {
        // Create new vehicle record
        print('EditProfilePage: Creating new vehicle record');
        final vehicleResponse =
            await Supabase.instance.client
                .from('vehicledetails')
                .insert({
                  'insurance': _insuranceController.text,
                  'registration': _registrationController.text,
                  'puc': _pucDate != null ? _formatDate(_pucDate!) : null,
                  'model': _modelController.text,
                })
                .select()
                .single();
        vehicleId = vehicleResponse['vehicleid'];
      } else {
        // Update existing vehicle record
        print('EditProfilePage: Updating existing vehicle record');
        await Supabase.instance.client
            .from('vehicledetails')
            .update({
              'insurance': _insuranceController.text,
              'registration': _registrationController.text,
              'puc': _pucDate != null ? _formatDate(_pucDate!) : null,
              'model': _modelController.text,
            })
            .eq('vehicleid', vehicleId);
      }

      // Then update user details
      await Supabase.instance.client
          .from('userdetails')
          .update({
            'name': _nameController.text,
            'phone': _phoneController.text,
            'email': _emailController.text,
            'address': _addressController.text,
            'username': _usernameController.text,
            'vehicleid': vehicleId,
          })
          .eq('firebaseuid', user.uid);

      // Refresh providers after save
      await Provider.of<UserProvider>(context, listen: false).refresh();
      await Provider.of<VehicleProvider>(context, listen: false).refresh();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.pop(context);
    } catch (e) {
      print('Error saving changes: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile. Please try again.')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF8E44AD),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Details Section
              const Text(
                'Personal Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Vehicle Details Section
              const Text(
                'Vehicle Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF8E44AD)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(labelText: 'Vehicle Model', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(labelText: 'Registration Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceController,
                decoration: const InputDecoration(labelText: 'Insurance Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pucController,
                readOnly: true,
                onTap: _pickPucDate,
                decoration: const InputDecoration(
                  labelText: 'PUC Valid Until (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E44AD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _pickPucDate() async {
    final DateTime initialDate = _pucDate ?? DateTime.now();
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate = DateTime(2100);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        _pucDate = DateTime(picked.year, picked.month, picked.day);
        _pucController.text = _formatDate(_pucDate!);
      });
    }
  }
}
