import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ftmithaimart/otp/phone_number/enter_number.dart';
import 'package:otp_pin_field/otp_pin_field.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final Function() function;
  final String phoneNo;

  const OtpScreen({
    Key? key,
    required this.verificationId,
    required this.function,
    required this.phoneNo,
  });

  @override
  _OtpScreenState createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String enteredOtp = "";
  late String smsOTP;
  final _otpPinFieldKey = GlobalKey<OtpPinFieldState>();
  bool isVerifyingOTP = false;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                Image.asset(
                  'assets/Logo.png',
                  width: screenWidth * 0.5,
                  fit: BoxFit.contain,
                ),
                SizedBox(
                  height: screenHeight * 0.02,
                ),
                const Text(
                  'Verification',
                  style: TextStyle(fontSize: 28, color: Colors.black),
                ),
                SizedBox(
                  height: screenHeight * 0.02,
                ),
                Text(
                  'Enter a 6 digit code that was sent to +92${widget.phoneNo}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.04,
                ),
                Container(
                  margin: EdgeInsets.symmetric(
                      horizontal: screenWidth > 600 ? screenWidth * 0.2 : 2),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.grey,
                          offset: Offset(0.0, 1.0), //(x,y)
                          blurRadius: 6.0,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: screenWidth * 0.025),
                        child: OtpPinField(
                          key: _otpPinFieldKey,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: false),
                          textInputAction: TextInputAction.done,
                          maxLength: 6,
                          fieldWidth: 30,
                          onSubmit: (String text) {},
                          onChange: (String text) {
                            setState(() {
                              enteredOtp = text;
                            });
                          },
                        ),
                      ),
                      SizedBox(
                        height: screenHeight * 0.04,
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff63131C),
                        ),
                        onPressed: isVerifyingOTP
                            ? null
                            : () async {
                                setState(() {
                                  isVerifyingOTP = true;
                                });

                                await Future.delayed(
                                    const Duration(seconds: 2));

                                if (enteredOtp == widget.verificationId) {
                                  widget.function();
                                } else {
                                  Fluttertoast.showToast(
                                      msg: ("Invalid OTP"),
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM);
                                }

                                setState(() {
                                  isVerifyingOTP = false;
                                });
                              },
                        icon: isVerifyingOTP
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.verified_outlined,
                                color: Colors.white,
                              ),
                        label: const Text(
                          "Verify OTP",
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: 10)),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EnterNumber(function: widget.function)));
                  },
                  child: const Text(
                    "Try Another Number",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff63131C),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
