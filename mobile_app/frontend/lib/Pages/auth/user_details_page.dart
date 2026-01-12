import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vehnicate_frontend/Providers/vehicle_provider.dart';
import 'package:vehnicate_frontend/services/supabase_service.dart';

class UserDetailsPage extends StatefulWidget {
  final String userId;
  final String email;

  const UserDetailsPage({super.key, required this.userId, required this.email});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehicleRegistrationController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _saveUserDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await SupabaseService().updateUserProfile(
        userId: widget.userId, // Pass the Firebase UID
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
      );
      await context.read<VehicleProvider>().refresh();
      print(
        'VehicleProvider(saveUserDetails): Vehicle data loaded with data: ${context.read<VehicleProvider>().vehicleId}',
      );

      await SupabaseService().updateVehicleDetails(
        vehicleId: context.read<VehicleProvider>().vehicleId ?? 1,
        insurance: "",
        registration: _vehicleRegistrationController.text.trim(),
        puc: null,
        model: _vehicleModelController.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/dash", (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Complete Your Profile',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us more about yourself',
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 40),

                    // Full Name Field
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Username Field
                    _buildTextField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: Icons.alternate_email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Vehicle Details Section
                    Text(
                      'Vehicle Details (Optional)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Model Field
                    _buildTextField(
                      controller: _vehicleModelController,
                      label: 'Vehicle Model',
                      icon: Icons.directions_car_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Vehicle Year Field
                    _buildTextField(
                      controller: _vehicleYearController,
                      label: 'Vehicle Year',
                      icon: Icons.calendar_today_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),
                    // Vehicle Registration Field
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _vehicleRegistrationController,
                      label: 'Vehicle Registration',
                      icon: Icons.directions_car_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveUserDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E44AD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 0,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Skip Button
                    Center(
                      child: TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  Navigator.pushNamedAndRemoveUntil(context, "/dash", (route) => false);
                                },
                        child: Text(
                          'Skip for now',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), color: Colors.white.withOpacity(0.1)),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType ?? TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
