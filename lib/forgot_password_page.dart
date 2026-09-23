import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _resendCountdown = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 1) {
          _resendCountdown--;
        } else {
          _resendCountdown = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });
    _startCountdown();
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _isLoading) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    setState(() => _isLoading = false);
    _startCountdown();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Reset link resent successfully',
          style: TextStyle(color: Colors.white, fontSize: 13),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top navigation bar
              Align(
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: InkWell(
                    key: const ValueKey('backButton'),
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox.square(
                      dimension: 42,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: _isSuccess ? _buildSuccessView() : _buildFormView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('forgotFormContent'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Crouket Brand Header
          const Text(
            'C R O U K E T',
            style: TextStyle(
              color: Color(0xFF757575),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Forgot password?',
            style: TextStyle(
              color: Color(0xFF171717),
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "No worries! Enter your registered email address and we'll send you instructions to reset your password.",
            style: TextStyle(
              color: Color(0xFF707070),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),

          // Email Input
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Email',
                style: TextStyle(
                  color: Color(0xFF353535),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              TextFormField(
                key: const ValueKey('forgotEmailField'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  hintStyle: const TextStyle(
                    color: Color(0xFFB1B1B1),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.mail_outline_rounded,
                    color: Color(0xFF8F8F8F),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  errorStyle: const TextStyle(fontSize: 10, height: 0.9),
                  enabledBorder: _border(const Color(0xFF8F8F8F), 1.25),
                  focusedBorder: _border(Colors.black, 1.6),
                  errorBorder: _border(const Color(0xFFB3261E), 1),
                  focusedErrorBorder: _border(const Color(0xFFB3261E), 1.5),
                ),
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Email is not valid';
                  }
                  return null;
                },
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            height: 52,
            child: FilledButton(
              key: const ValueKey('sendInstructionsButton'),
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isLoading
                    ? const _WaterDropLoader(
                        key: ValueKey('waterDropLoaderForgot'),
                      )
                    : const Text(
                        'Send instructions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Back to login row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remember your password? ',
                style: TextStyle(color: Color(0xFF9C9C9C), fontSize: 12),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: Color(0xFF161616),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final email = _emailController.text.trim();

    return Column(
      key: const ValueKey('successView'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF171717),
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              color: Color(0xFF707070),
              fontSize: 13,
              height: 1.5,
            ),
            children: [
              const TextSpan(
                text: 'We have sent password recovery instructions to\n',
              ),
              TextSpan(
                text: email,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),

        // Back to Login button
        SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey('backToLoginButton'),
            onPressed: () => Navigator.of(context).maybePop(),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Resend section
        Center(
          child: TextButton(
            key: const ValueKey('resendButton'),
            onPressed: (_resendCountdown > 0 || _isLoading) ? null : _resend,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF303030),
              disabledForegroundColor: const Color(0xFFA5A5A5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              _resendCountdown > 0
                  ? "Didn't receive email? Resend in ${_resendCountdown}s"
                  : "Didn't receive email? Resend now",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }

  static OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _WaterDropLoader extends StatefulWidget {
  const _WaterDropLoader({super.key});

  @override
  State<_WaterDropLoader> createState() => _WaterDropLoaderState();
}

class _WaterDropLoaderState extends State<_WaterDropLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 20,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) =>
            CustomPaint(painter: _WaterDropPainter(_controller.value)),
      ),
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  const _WaterDropPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final eased = Curves.easeInOutCubic.transform(progress);
    final centerY = size.height / 2;
    final middleX = 13 + 22 * eased;
    final swell = math.sin(progress * math.pi);

    canvas.drawCircle(Offset(middleX, centerY), 5.2 + swell, paint);
    canvas.drawCircle(
      Offset(8 + 8 * eased, centerY),
      2.8 + (1 - progress) * 1.2,
      paint,
    );
    canvas.drawCircle(
      Offset(32 + 8 * eased, centerY),
      2.8 + progress * 1.2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
