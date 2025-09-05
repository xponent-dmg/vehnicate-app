import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _userDetails;
  Map<String, dynamic>? _vehicleDetails;

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
    _loadExistingData();
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

      // Fetch user details
      final userResponse = await Supabase.instance.client
          .from('userdetails')
          .select('*, vehicledetails(*)')
          .eq('firebaseuid', user.uid)
          .single();

      setState(() {
        _userDetails = userResponse;
        _vehicleDetails = userResponse['vehicledetails'];
        
        // Populate user controllers
        _nameController.text = _userDetails?['name'] ?? '';
        _phoneController.text = _userDetails?['phone'] ?? '';
        _emailController.text = _userDetails?['email'] ?? '';
        _addressController.text = _userDetails?['address'] ?? '';
        _usernameController.text = _userDetails?['username'] ?? '';

        // Populate vehicle controllers if vehicle details exist
        if (_vehicleDetails != null) {
          _insuranceController.text = _vehicleDetails?['insurance'] ?? '';
          _registrationController.text = _vehicleDetails?['registration'] ?? '';
          _pucController.text = _vehicleDetails?['puc']?.toString().split('T')[0] ?? '';
          _modelController.text = _vehicleDetails?['model'] ?? '';
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

      // First, update or create vehicle details
      int? vehicleId = _userDetails?['vehicleid'];
      if (_vehicleDetails == null) {
        // Create new vehicle record
        final vehicleResponse = await Supabase.instance.client
            .from('vehicledetails')
            .insert({
              'insurance': _insuranceController.text,
              'registration': _registrationController.text,
              'puc': _pucController.text,
              'model': _modelController.text,
            })
            .select()
            .single();
        vehicleId = vehicleResponse['vehicleid'];
      } else {
        // Update existing vehicle record
        await Supabase.instance.client
            .from('vehicledetails')
            .update({
              'insurance': _insuranceController.text,
              'registration': _registrationController.text,
              'puc': _pucController.text,
              'model': _modelController.text,
            })
            .eq('vehicleid', _vehicleDetails!['vehicleid']);
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print('Error saving changes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E44AD),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),        
              const SizedBox(height: 32),

              // Vehicle Details Section
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8E44AD),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle Model',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _registrationController,
                decoration: const InputDecoration(
                  labelText: 'Registration Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pucController,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
}
