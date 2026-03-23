import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_pass.dart';
import 'login_screen.dart';

class ForgetPassPage extends StatefulWidget {
  const ForgetPassPage({super.key});

  @override
  State<ForgetPassPage> createState() => _ForgetPassPageState();
}

class _ForgetPassPageState extends State<ForgetPassPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _emailSent = false;

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await supabase.auth.resetPasswordForEmail(
          _emailController.text.trim(),
          redirectTo:
              'https://zaiqirqjdwdaxboqciab.supabase.co/auth/v1/callback',
        );

        setState(() {
          _emailSent = true;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent! Check your inbox."),
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
                          if (!_emailSent) ...[
                            const Text(
                              "At least you remember your e-mail, right?",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
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
                                  borderSide: const BorderSide(
                                    color: darkGreen,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(
                                    color: darkGreen,
                                  ),
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
                                      backgroundColor: const Color.fromARGB(
                                        255,
                                        11,
                                        92,
                                        15,
                                      ),
                                      minimumSize: const Size(
                                        double.infinity,
                                        45,
                                      ),
                                    ),
                                    child: const Text(
                                      "Send Reset Email",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Back to Login",
                                style: TextStyle(
                                  color: darkGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.email_outlined,
                              size: 80,
                              color: darkGreen,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Check Your Email",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "We've sent a password reset link to\n${_emailController.text}",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: darkGreen,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "1. Click the link in your email\n2. You'll see a success message\n3. Come back to the app and tap 'Change Password' below",
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darkGreen,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ChangePassScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  11,
                                  92,
                                  15,
                                ),
                                minimumSize: const Size(double.infinity, 45),
                              ),
                              child: const Text(
                                "Change Password",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Back to Login",
                                style: TextStyle(
                                  color: darkGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _emailSent = false;
                                  _emailController.clear();
                                });
                              },
                              child: const Text(
                                "Try different email?",
                                style: TextStyle(
                                  color: darkGreen,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
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
}
