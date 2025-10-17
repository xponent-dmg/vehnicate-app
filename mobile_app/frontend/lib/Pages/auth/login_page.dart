import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vehnicate_frontend/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  // final bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    print('🔐 LoginPage initialized');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _emailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithEmail(_emailController.text.trim(), _passwordController.text);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, "/home",
          (route)=>false
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await AuthService().signInWithGoogle();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/home",(route)=>false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 Building LoginPage widget...');

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // Logo and Title
                    const Text(
                      'Vehnicate',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Calm in the Chaos',
                      style: TextStyle(fontSize: 16, color: Colors.white70, letterSpacing: 0.5),
                    ),

                    const SizedBox(height: 60),

                    // Email Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          //   return 'Please enter a valid email';
                          // }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white.withOpacity(0.6),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Sign Up/Sign In Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _emailSignIn,
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
                                : Text(
                                  'Sign in',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Toggle Sign Up/Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                         "Don't have an account? ",
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, "/signup");
                          },
                          child: Text(
                           'Sign up',
                            style: const TextStyle(color: Color(0xFF8E44AD), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or connect with',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.3))),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Google Sign In
                        GestureDetector(
                          onTap: _isLoading ? null : _googleSignIn,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.1),
                              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                            ),
                            child: const Icon(FontAwesomeIcons.google, color: Colors.white, size: 24),
                          ),
                        ),

                        // Apple Sign In (non functional)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: const Icon(FontAwesomeIcons.apple, color: Colors.white, size: 24),
                        ),

                        // Skip Sign In (temp)
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                "/home",
                                (route)=>false,
                              );
                            },
                            icon: Icon(FontAwesomeIcons.forwardStep, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
