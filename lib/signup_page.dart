import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:footprint3/auth_helper.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/email_verification_page.dart';
import 'package:footprint3/homepage.dart';
import 'package:footprint3/login_page.dart';
import 'package:footprint3/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'HolderTracker_class.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final AuthHelper _authHelper = AuthHelper();

  DateTime? _selectedBirthday;
  bool termsAccepted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _signup() async {
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String firstname = _firstnameController.text.trim();
    String lastname = _lastnameController.text.trim();

    if (password == confirmPassword) {
      try {
        User? user1 = await _authHelper.signUp(email, password);
        if (user1 != null) {
          curTracker = HolderTracker.empty();
          curTracker.uid = user1.uid;
          curTracker.email = email;
          curTracker.username = username;
          curTracker.firstname = firstname;
          curTracker.lastname = lastname;

          String? curTrackerUid = await addTracker(curTracker);
          curTracker.uid = curTrackerUid!;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmailVerificationPage()),
          );
        }
      } catch (e) {
        AlertDialogHelper.showAlertDialog(context, e.toString());
      }
    } else {
      AlertDialogHelper.showAlertDialog(context, 'Password did not match');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLoginForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return SizedBox(
      width: 400,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 100),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Create Account",
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 40,
                fontWeight: FontWeight.w100,
                color: mainOrange,
              ),
            ),
          ),
          const SizedBox(height: 100),
          CustomTextField(
            controller: _usernameController,
            labelText: 'Username',
          ),
          CustomTextField(
            controller: _emailController,
            labelText: 'Email',
          ),
          CustomTextField(
            controller: _firstnameController,
            labelText: 'First Name',
          ),
          CustomTextField(
            controller: _lastnameController,
            labelText: 'Last Name',
          ),
          CustomTextField(
            controller: _addressController,
            labelText: 'Address',
          ),
          CustomTextField(
            controller: _numberController,
            labelText: 'Contact Number',
            keyboardType: TextInputType.phone,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: ListTile(
              title: Text(
                _selectedBirthday == null
                    ? 'Select Birthday'
                    : 'Birthday: ${_selectedBirthday!.toLocal().toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mainOrange,
                      fontSize: 16,
                    )
              ),
              trailing: Icon(Icons.calendar_today, color: mainOrange),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedBirthday = picked;
                  });
                }
              },
            ),
          ),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            password: true,
          ),
          CustomTextField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            password: true,
          ),
          Container(
            width: 300,
            child: CheckboxListTile(
              title: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black),
                  children: [
                    const TextSpan(text: 'I have read and agree to the '),
                    TextSpan(
                      text: 'Terms and Conditions.',
                      style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          final Uri url = Uri.parse('https://www.termsfeed.com/live/05ed6286-5473-4867-b08a-b36d2b16d578');
                          if (!await launchUrl(url)) {
                            print('Error launching URL');
                          }
                        },
                    ),
                  ],
                ),
              ),
              value: termsAccepted,
              onChanged: (bool? value) {
                setState(() {
                  termsAccepted = value ?? false;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSignUpButton(),
          const SizedBox(height: 10),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          if (termsAccepted) {
            _signup();
          } else {
            AlertDialogHelper.showAlertDialog(context, 'Please accept the terms and conditions');
          }
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(mainOrange),
        ),
        child: Text(
          'Sign up',
          style: TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 217, 217, 217),
        ),
        child: Text(
          'Login',
          style: TextStyle(
            fontSize: 25,
            color: mainOrange,
          ),
        ),
      ),
    );
  }
}
