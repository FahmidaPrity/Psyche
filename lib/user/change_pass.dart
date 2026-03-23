import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ChangePassScreen extends StatefulWidget {
  const ChangePassScreen({super.key});

  @override
  State<ChangePassScreen> createState() => _ChangePassScreenState();
}

class _ChangePassScreenState extends State<ChangePassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _showEmailStep = true;
  String? _resetEmail;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp passwordRegex = RegExp(
    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$',
  );

  @override
  void initState() {
    super.initState();
    _checkForActiveSession();
  }

  void _checkForActiveSession() {
    final session = supabase.auth.currentSession;
    if (session != null) {
      // User has an active session, skip email step
      setState(() {
        _showEmailStep = false;
      });
    }
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://zaiqirqjdwdaxboqciab.supabase.co/auth/v1/callback',
      );

      setState(() {
        _resetEmail = _emailController.text.trim();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New reset email sent! Click the link and come back."),
          duration: Duration(seconds: 4),
        ),
      );
    } on AuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _tryWithSessionRecovery() async {
    setState(() => _isLoading = true);

    try {
      // Try to recover session by checking current user
      await supabase.auth.refreshSession();
      final session = supabase.auth.currentSession;

      if (session != null) {
        setState(() {
          _showEmailStep = false;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Session recovered! You can now change your password.",
            ),
          ),
        );
      } else {
        throw Exception("No active session found");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No active reset session. Please click the reset link in your email first.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // First try to refresh the session
      await supabase.auth.refreshSession();

      final response = await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      if (!mounted) return;

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Password updated successfully! Please sign in with your new password.",
            ),
            duration: Duration(seconds: 4),
          ),
        );

        // Clear controllers
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Sign out user so they can login with new password
        await supabase.auth.signOut();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      } else {
        throw Exception("Failed to update password");
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      String message = e.message;

      if (e.message.contains('not authenticated') ||
          e.message.contains('JWT') ||
          e.message.contains('session')) {
        // Session expired, show email step again
        setState(() {
          _showEmailStep = true;
        });
        message = "Reset session expired. Please request a new reset email.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted && !_showEmailStep) setState(() => _isLoading = false);
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
            "assets/images/backgrounds/bg_login.jpg",
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
                          if (_showEmailStep)
                            ..._buildEmailStep()
                          else
                            ..._buildPasswordStep(),
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

  List<Widget> _buildEmailStep() {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);

    return [
      const Text(
        "Reset Password",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
      ),
      const SizedBox(height: 15),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
        ),
        child: const Text(
          "We need to send you a fresh reset link since the previous session expired.",
          textAlign: TextAlign.center,
          style: TextStyle(color: darkGreen, fontSize: 14),
        ),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _emailController,
        style: const TextStyle(color: darkGreen),
        decoration: InputDecoration(
          labelText: "Email",
          labelStyle: const TextStyle(color: darkGreen),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: darkGreen),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: darkGreen),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Enter your email";
          }
          if (!emailRegex.hasMatch(value)) {
            return "Enter a valid email address";
          }
          return null;
        },
      ),
      const SizedBox(height: 20),
      _isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _sendResetEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 11, 92, 15),
                minimumSize: const Size(double.infinity, 45),
              ),
              child: const Text(
                "Send New Reset Email",
                style: TextStyle(color: Colors.white),
              ),
            ),
      if (_resetEmail != null) ...[
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              Text(
                "Reset email sent to $_resetEmail",
                style: const TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "1. Click the link in your email\n2. You'll see the success page\n3. Come back and tap 'I Clicked the Link'",
                textAlign: TextAlign.center,
                style: TextStyle(color: darkGreen, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: _tryWithSessionRecovery,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            minimumSize: const Size(double.infinity, 45),
          ),
          child: const Text(
            "I Clicked the Link",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
      const SizedBox(height: 15),
      TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: const Text(
          "Back to Login",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.w500),
        ),
      ),
    ];
  }

  List<Widget> _buildPasswordStep() {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);

    return [
      const Text(
        "Change, and don't forget again!",
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
      ),
      const SizedBox(height: 20),
      _buildPasswordField("New Password", _passwordController),
      const SizedBox(height: 15),
      _buildConfirmPasswordField(),
      const SizedBox(height: 25),
      _isLoading
          ? const CircularProgressIndicator()
          : ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 11, 92, 15),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Update Password",
                style: TextStyle(color: Colors.white),
              ),
            ),
      const SizedBox(height: 15),
      TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: const Text(
          "Back to Login",
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.w500),
        ),
      ),
    ];
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);
    return TextFormField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: darkGreen),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: darkGreen),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkGreen),
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
          borderSide: const BorderSide(color: darkGreen),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: darkGreen),
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
