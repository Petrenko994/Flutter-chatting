import 'package:ainaglam/screens/home/workspace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:ainaglam/extentions/context.dart';
import 'package:ainaglam/extentions/responsive.dart';
import 'package:ainaglam/extentions/input_field.dart';
import 'package:ainaglam/extentions/labeled_text_button.dart';
import '../../providers/auth_provider.dart';
import 'sms_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUp = false;

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedWidth.mobile(
        child: Form(
          key: _formKey,
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(0.0),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(142, 222, 220, 220),
                  blurRadius: 5.0,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: SvgPicture.asset(
                    'assets/images/logo-mark.svg',
                    fit: BoxFit.scaleDown,
                    height: 100,
                    width: 100,
                  ),
                ),
                /* Foreground content (TextFields, Buttons, etc.) */
                Padding(
                  padding: const EdgeInsets.only(
                    top: 70.0,
                    bottom: 70.0,
                    left: 30.0,
                    right: 30.0,
                  ),
                  child: Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // const Spacer(),  // full screen background set
                        Text(
                          _isSignUp ? 'アカウントを作成' : 'ログイン',
                          style: context.textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 16),
                        InputField.email(
                          controller: _emailController,
                          label: 'メールアドレス',
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }
                                  context.closeKeyboard();
                                  await authProvider.login(
                                      _emailController.text.trim(), context);
                                  if (authProvider.status == true) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SmsVerificationScreen(
                                                emailString: _emailController
                                                    .text
                                                    .trim()),
                                      ),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('SMSコードを送信する'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'or',
                          style: context.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: authProvider.isLoading
                              ? null
                              : () async {
                                  await authProvider.loginwithGoogle(context);
                                  if (authProvider.status == true) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => WorkspaceScreen(
                                            tokenString: authProvider.token!),
                                      ),
                                    );
                                  }
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/google-logo.png', // Add Google logo image to assets folder
                                height: 20.0,
                              ),
                              const SizedBox(width: 12.0),
                              const Text(
                                'Googleでログイン',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 25),
                        LabeledTextButton(
                            label: _isSignUp ? 'すでに登録済みですか？' : '新しいアカウントを作成',
                            action: _isSignUp ? 'ログイン' : 'サインアップ',
                            onTap: _toggleMode),
                        // const Spacer(),    //full screen background set
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
