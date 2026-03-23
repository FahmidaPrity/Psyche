import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController(); // NEW
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _idNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agree = false;
  String? _selectedRole = 'student';

  final supabase = Supabase.instance.client;

  final RegExp fullNameRegex = RegExp(r'^[a-zA-Z\s]{2,50}$'); 
  final RegExp usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
  final RegExp idNoRegex = RegExp(r'^[A-Za-z0-9]{2,20}$');
  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
  );

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agree) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must agree to the terms & conditions")),
        );
        return;
      }

      if (mounted) setState(() => _isLoading = true);

      try {
        final signupData = {
          'full_name': _fullNameController.text.trim(),
          'username': _usernameController.text.trim(),
          'id_no': _idNoController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
        };

        final res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          emailRedirectTo: 'https://zaiqirqjdwdaxboqciab.supabase.co/auth/v1/callback',
          data: {
            'display_name': _fullNameController.text.trim(), 
            ...signupData, 
          },
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Registration successful! Please check your email and click the verification link, then return to Psyche.",
            ),
            duration: Duration(seconds: 4),
          ),
        );

        _fullNameController.clear(); 
        _usernameController.clear();
        _idNoController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() => _selectedRole = 'student');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );

      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $e")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/backgrounds/bg_signup.jpg",
            fit: BoxFit.cover,
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withOpacity(0.05)),
          ),
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromARGB(66, 213, 224, 202),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Join the Community",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 25),
                          _buildField("Full Name", _fullNameController, fullNameRegex,
                              "Enter your full name (2-50 characters)"),
                          const SizedBox(height: 15),
                          _buildField("Username", _usernameController, usernameRegex,
                              "3–15 chars, letters/numbers/_ only"),
                          const SizedBox(height: 15),
                          _buildField("Teacher/Student ID No", _idNoController, idNoRegex,
                              "Invalid ID format"),
                          const SizedBox(height: 15),
                          _buildRoleDropdown(),
                          const SizedBox(height: 15),
                          _buildField("Email", _emailController, emailRegex,
                              "Enter valid email"),
                          const SizedBox(height: 15),
                          _buildPasswordField(),
                          const SizedBox(height: 15),
                          _buildConfirmPasswordField(),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _agree,
                                onChanged: (val) {
                                  setState(() {
                                    _agree = val!;
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  "I agree to all the terms & conditions",
                                  style: TextStyle(color: darkGreen),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Color.fromARGB(255, 11, 92, 15),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                  onPressed: _register,
                                  child: const Text(
                                    "Register",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                          const SizedBox(height: 15),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Already have an account? Sign in here!",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: darkGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: darkGreen),
        color: Colors.white.withOpacity(0.1),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRole,
        style: const TextStyle(color: darkGreen),
        decoration: InputDecoration(
          labelText: "Role",
          labelStyle: const TextStyle(color: darkGreen),
          prefixIcon: Icon(
            _selectedRole == 'student' ? Icons.school : Icons.person,
            color: darkGreen,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: darkGreen),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: darkGreen, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        dropdownColor: Colors.white,
        items: [
          DropdownMenuItem(
            value: 'student',
            child: Row(
              children: [
                SizedBox(width: 8),
                Text('Student', style: TextStyle(color: darkGreen)),
              ],
            ),
          ),
          DropdownMenuItem(
            value: 'teacher',
            child: Row(
              children: [
                SizedBox(width: 8),
                Text('Teacher', style: TextStyle(color: darkGreen)),
              ],
            ),
          ),
        ],
        onChanged: (val) => setState(() => _selectedRole = val),
        validator: (value) => value == null ? "Select role" : null,
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      RegExp regex, String errorMsg) {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: darkGreen),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: darkGreen),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter $label";
        }
        if (!regex.hasMatch(value)) {
          return errorMsg;
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      style: const TextStyle(color: darkGreen),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: darkGreen),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter password";
        }
        if (!passwordRegex.hasMatch(value)) {
          return "Must contain 8+, 1 uppercase, 1 lowercase, 1 number, 1 special char";
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: true,
      style: const TextStyle(color: darkGreen),
      decoration: InputDecoration(
        labelText: "Confirm Password",
        labelStyle: const TextStyle(color: darkGreen),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value != _passwordController.text) {
          return "Passwords don't match";
        }
        return null;
      },
    );
  }
}
