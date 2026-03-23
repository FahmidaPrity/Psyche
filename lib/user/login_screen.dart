import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home_screen.dart';
import 'signup_screen.dart';
import 'forget_pass.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailOrUsernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  final supabase = Supabase.instance.client;

  Future<void> _login() async {
    final input = _emailOrUsernameController.text.trim();
    final password = _passwordController.text;

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email or username")),
      );
      return;
    }
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password cannot be empty")),
      );
      return;
    }

    try {
      String? emailToUse;

      if (emailRegex.hasMatch(input)) {
        emailToUse = input;
      } else {
        final res = await supabase
            .from('profiles')
            .select('email')
            .eq('username', input)
            .maybeSingle();

        if (res == null || res['email'] == null) {
          print("Username not found in profiles, trying as email");
          if (emailRegex.hasMatch(input)) {
            emailToUse = input;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Username not found")),
            );
            return;
          }
        } else {
          emailToUse = res['email'] as String;
        }
      }

      final response = await supabase.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed. Please try again.")),
        );
        return;
      }

      print("User logged in: ${user.id}");
      print("Email confirmed: ${user.emailConfirmedAt}");
      print("User metadata: ${user.userMetadata}");

      if (user.emailConfirmedAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please verify your email first. Check your inbox for the verification link."),
            duration: Duration(seconds: 5),
          ),
        );
        await supabase.auth.signOut();
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      print("Existing profile: $profile");

      if (profile == null) {
        print("Creating new profile...");
        final userData = user.userMetadata;
        
        try {
          final insertData = {
            'id': user.id,
            'full_name': userData?['full_name'] ?? userData?['display_name'] ?? 'User',
            'username': userData?['username'] ?? user.email?.split('@').first ?? 'user_${user.id.substring(0, 8)}',
            'id_no': userData?['id_no'] ?? '',
            'email': user.email,
            'role': userData?['role'] ?? 'student',
            'created_at': DateTime.now().toIso8601String(),
          };
          
          print("Inserting profile data: $insertData");
          
          await supabase.from('profiles').insert(insertData);
          
          print("Profile created successfully");
        } catch (insertError) {
          print("Profile insert error: $insertError");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error creating profile: $insertError")),
          );
          return;
        }
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on AuthException catch (e) {
      print("Auth error: ${e.message}");
      String message = e.message;
      if (e.message.contains('Invalid login credentials')) {
        message = "Invalid email/username or password";
      } else if (e.message.contains('Email not confirmed')) {
        message = "Please verify your email first. Check your inbox for the verification link.";
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      print("General error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unexpected error occurred: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color.fromARGB(255, 9, 36, 14);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(66, 213, 224, 202),
                            blurRadius: 6,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Welcome to",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Psyche",
                            style: TextStyle(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _emailOrUsernameController,
                            style: const TextStyle(color: darkGreen),
                            decoration: InputDecoration(
                              labelText: "Email or Username",
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
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: darkGreen),
                            decoration: InputDecoration(
                              labelText: "Password",
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
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgetPassPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: darkGreen,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 11, 92, 15),
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUpScreen()),
                              );
                            },
                            child: const Text(
                              "Don't have an account? Sign Up here!",
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
          ],
        ),
      ),
    );
  }
}
