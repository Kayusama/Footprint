import 'package:flutter/material.dart';
import 'package:footprint3/auth_helper.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/email_verification_page.dart';
import 'package:footprint3/homepage.dart';
import 'package:footprint3/resetpassword_page.dart';
import 'package:footprint3/signup_page.dart';
import 'HolderTracker_class.dart';
import 'utils.dart';

import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthHelper _authHelper = AuthHelper();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Future<bool> checkEmailVerified() async {
    bool isEmailVerified = false;
    setState(() => isLoading = true);
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    setState(() {
      isEmailVerified = user?.emailVerified ?? false;
      isLoading = false;
    });

    return isEmailVerified;
  }

  Future<void> getUser() async {
    bool isEmailVerified = await checkEmailVerified();
    User? user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      if (!isEmailVerified) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Notice"),
            content: Text("Please verify your email before logging in."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => EmailVerificationPage()),
                  );
                },
                child: Text("Verify Email"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
            ],
          ),
        );

        return;
      }
      try {
        getTracker(user.uid).then((tracker) {
          if (tracker != null) {
            curTracker = tracker;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DocumentTrackingScreen()),
            );
            print("User found: ${tracker.username}");
          } else {
            print("User not found in the database.");
          }
        });
      } catch (e) {
        print("Error fetching user: $e");
      }
      print("User ID: ${user.uid}");
      print("Email: ${user.email}");
      print("Display Name: ${user.displayName}");
    } else {
      print("No user is currently signed in.");
    }
  }

  Future<void> _login() async {
    try {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    List<HolderTracker> allTrackers = await getAllTrackers();
    HolderTracker tracker1 = HolderTracker.empty();
    if (allTrackers.isNotEmpty) {
      for (var tracker in allTrackers) {
        if (tracker.username == username) {
          tracker1 = tracker;
        }
      }
      if(tracker1.email!=""){
        String uid = await _authHelper.login(tracker1.email, password);
        if (uid != '') {
          getUser();
        } else {
          AlertDialogHelper.showAlertDialog(context, "Wrong email or password.");
        }
      }
      else {
        String uid = await _authHelper.login(username, password);
        if (uid != '') {
          getUser();
        } else {
          AlertDialogHelper.showAlertDialog(context, "Wrong email or password.");
        }
        AlertDialogHelper.showAlertDialog(context, "No user found with this username.");
      }
    }
    else {
      AlertDialogHelper.showAlertDialog(context, "No users found."); 
    }
  } catch (e) {
    AlertDialogHelper.showAlertDialog(context, e.toString());
  }
    }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: backgroundColor,
    resizeToAvoidBottomInset: true, // Allow automatic resizing
    body: SafeArea(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // Push content up
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
            child: Image.asset(
              'images/logo/official3.png',  
              width: 150,
              height: 150,
            ),
          ),
          // SvgPicture.asset(
          //   'images/undraw_around_the_world_re_rb1p 2.svg',
          //   width: 250,
          //   height: 250,
          // ),
          SizedBox(height: 100,),
          CustomTextField(
            controller: _usernameController,
            labelText: 'Username',
          ),
          SizedBox(height: 20,),
          CustomTextField(
            controller: _passwordController,
            labelText: 'Password',
            password: true,
          ),
          const SizedBox(height: 40),
          _buildLoginButton(),
          SizedBox(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResetpasswordPage()),
                    );
                  },
                  child: Text(
        'Forgot password',
        style: TextStyle(
      color: mainOrange,
      fontSize: 12,
      fontWeight: FontWeight.bold,
        ),
      ),
      
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSignUpButton(),
        ],
      ),
    );
  }

  

  

  Widget _buildLoginButton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          _login();
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => DocumentTrackingScreen()),
          // );
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            mainOrange,
          ),
        ),
        child: const Text(
          'Login',
          style: TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,

          ),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
  return Container(
  width: 300,
  margin: const EdgeInsets.all(10),
  child: ElevatedButton(
    onPressed: () {
     Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 217, 217, 217), // background color
    ),
    child: Text(
      'Sign up',
      style: TextStyle(
        fontSize: 25,
        color: mainOrange,

      ),
    ),
  ),
);
}
}