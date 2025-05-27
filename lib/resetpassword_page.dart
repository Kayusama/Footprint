import 'package:flutter/material.dart';
import 'package:footprint3/auth_helper.dart';
import 'package:footprint3/login_page.dart';
import 'utils.dart';

class ResetpasswordPage extends StatefulWidget {
  const ResetpasswordPage({super.key});

  @override
  State<ResetpasswordPage> createState() => _ResetpasswordPageState();
}

class _ResetpasswordPageState extends State<ResetpasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final AuthHelper _authHelper = AuthHelper();

  @override
  void initState() {
    super.initState();
  }


  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Alert'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    //_getUser();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pop(context);
    },
  ),
        backgroundColor: backgroundColor,
      ),
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Center(
          child: Wrap(children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginForm(),
                      ],
                    )
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 100),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            "Forgot password",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w100,
              color: mainOrange,
              // fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // SvgPicture.asset(
        //   'images/undraw_forgot_password_re_hxwm.svg',
        //   width: 250,
        //   height: 250,
        // ),
        const Text(
            "Enter your email to reset your password.",
            style: TextStyle(fontSize: 20, color: Colors.black),
          ),
        const SizedBox(height: 20),
        
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
        ),
        // const SizedBox(height: 20),
        _buildResetButton(),
      ],
    );
  }
  
  Widget _buildResetButton() {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: ((){
          _authHelper.resetPassword(email: _emailController.text.trim());
          _showAlertDialog(context, "Password reset email sent. Please check your email.");
          Navigator.pushReplacement(context, 
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            mainOrange
          ),
        ),
        child: const Text(
          'Reset password',
          style: TextStyle(
            fontSize: 25,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}