import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footprint3/utils.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool isEmailVerified = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    resendVerificationEmail();
    checkEmailVerified();
  }

  Future<void> checkEmailVerified() async {
    setState(() => isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    setState(() {
      isEmailVerified = user?.emailVerified ?? false;
      isLoading = false;
    });

    if (isEmailVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        "Email Verification",
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 40,
                          fontWeight: FontWeight.w100,
                          color: mainOrange,
                        ),
                      ),
                    ),
                    SizedBox(height: 150),
                    Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 30,
                            horizontal: 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 60,
                                color: mainOrange,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Check your email!',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'A verification link has been sent to your email. Please verify to continue.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.black54),
                              ),
                              const SizedBox(height: 25),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainOrange,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: checkEmailVerified,
                                icon: const Icon(Icons.verified, color: Colors.white,),
                                label: const Text(
                                  'I have verified',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: resendVerificationEmail,
                                child: Text(
                                  'Resend Verification Email',
                                  style: TextStyle(
                                    color: mainOrange,
                                    fontWeight: FontWeight.bold,
                                  ),  
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
