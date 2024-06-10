import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fp_ppb_e8/components/auth/register_button.dart';
import 'package:fp_ppb_e8/components/auth/text_field.dart';
import 'package:fp_ppb_e8/pages/auth/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // sign user in method
  void registerUser() async {
    // show loading circle
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      if(!mounted)return;
      Navigator.pop(context);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        Navigator.pop(context);
      } else if (e.code == 'email-already-in-use') {
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: ListView(
            children: [
              const SizedBox(height: 50),

              // logo
              const Icon(
                Icons.lock,
                size: 100,
              ),

              const SizedBox(height: 50),

              // email textfield
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),

              const SizedBox(height: 10),

              // password textfield
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),

              const SizedBox(height: 25),

              // sign in button
              RegisterButton(
                onTap: registerUser,
              ),

              const SizedBox(height: 50),

              // Already Have account? Login now
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already Have account?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                    ),
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
