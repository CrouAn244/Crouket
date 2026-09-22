import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _introController;
  late final AnimationController _curtainController;

  Timer? _introTimer;
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    );
    _curtainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );
    _introTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _introController.forward();
    });
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _introController.dispose();
    _curtainController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    if (_isLoading) return;
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isLoading || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    await _curtainController.forward();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _success = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _curtainController]),
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          final intro = Curves.easeInOutCubic.transform(_introController.value);
          final formProgress = const Interval(
            0.18,
            1,
            curve: Curves.easeOutBack,
          ).transform(_introController.value);
          final curtain = Curves.easeInOutCubic.transform(
            _curtainController.value,
          );

          return Stack(
            children: [
              if (_success)
                const Positioned.fill(child: _WelcomePage())
              else
                Positioned.fill(
                  child: _AuthForm(
                    formKey: _formKey,
                    nameController: _nameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    isLogin: _isLogin,
                    isLoading: _isLoading,
                    obscurePassword: _obscurePassword,
                    revealProgress: formProgress,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onSubmit: _submit,
                    onSwitchMode: _switchMode,
                  ),
                ),
              if (!_success)
                _AnimatedCurtain(
                  screenSize: size,
                  introProgress: intro,
                  closeProgress: curtain,
                ),
              if (_introController.value < 0.78 && curtain == 0)
                _SplashTitle(progress: intro),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedCurtain extends StatelessWidget {
  const _AnimatedCurtain({
    required this.screenSize,
    required this.introProgress,
    required this.closeProgress,
  });

  final Size screenSize;
  final double introProgress;
  final double closeProgress;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final collapsedHeight = math.min(screenSize.height * 0.31, 265.0);
    final openHeight = screenSize.height + 80;
    final headerHeight =
        openHeight - (openHeight - collapsedHeight) * introProgress;
    final curtainHeight =
        headerHeight + (openHeight - headerHeight) * closeProgress;
    final whiteProgress = const Interval(
      0.64,
      1,
      curve: Curves.easeInOut,
    ).transform(closeProgress);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: curtainHeight,
      child: ClipPath(
        clipper: _HeaderClipper(
          shapeProgress: introProgress * (1 - closeProgress),
        ),
        child: ColoredBox(
          color: Color.lerp(
            Colors.black,
            const Color(0xFFF8F7F5),
            whiteProgress,
          )!,
          child: Opacity(
            opacity: ((introProgress * 2 - 1) * (1 - closeProgress)).clamp(
              0.0,
              1.0,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(28, topPadding + 31, 24, 0),
              child: const Align(
                alignment: Alignment.topLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Brand(fontSize: 25),
                    SizedBox(height: 6),
                    Text(
                      'Welcome back! Log in to continue.',
                      style: TextStyle(
                        color: Color(0xFF929292),
                        fontSize: 12,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashTitle extends StatelessWidget {
  const _SplashTitle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final slide = const Interval(
      0,
      0.56,
      curve: Curves.easeInCubic,
    ).transform(progress);
    final opacity = 1 - const Interval(0.16, 0.68).transform(progress);

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(MediaQuery.sizeOf(context).width * 0.55 * slide, 0),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Brand(fontSize: 26),
                  SizedBox(height: 11),
                  Text(
                    'All your cards in one place',
                    key: ValueKey('splashSubtitle'),
                    style: TextStyle(
                      color: Color(0xFF858585),
                      fontSize: 11,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.fontSize});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'S L A T E',
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLogin,
    required this.isLoading,
    required this.obscurePassword,
    required this.revealProgress,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSwitchMode,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLogin;
  final bool isLoading;
  final bool obscurePassword;
  final double revealProgress;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final topSpacing = math.min(size.height * 0.29, 250.0);

    return Opacity(
      opacity: revealProgress.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 95 * (1 - revealProgress)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              26,
              topSpacing,
              26,
              math.max(18.0, keyboardInset + 18),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: math.max(0, size.height - topSpacing - 42),
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Text(
                          isLogin ? 'Login' : 'Create account',
                          key: ValueKey('title-$isLogin'),
                          style: const TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: isLogin
                            ? const SizedBox.shrink()
                            : Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: _LabeledField(
                                  label: 'Name',
                                  hint: 'Enter your name',
                                  controller: nameController,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) =>
                                      (value ?? '').trim().isEmpty
                                      ? 'Please enter your name'
                                      : null,
                                ),
                              ),
                      ),
                      _LabeledField(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final email = (value ?? '').trim();
                          if (email.isEmpty) return 'Please enter your email';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Email is not valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _LabeledField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => onSubmit(),
                        suffixIcon: IconButton(
                          onPressed: onTogglePassword,
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9A9A9A),
                            size: 20,
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (password.length < 6) {
                            return 'Use at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: isLoading ? null : () {},
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF303030),
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 13),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          key: const ValueKey('authButton'),
                          onPressed: isLoading ? null : onSubmit,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            disabledBackgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: isLoading
                                ? const _WaterDropLoader(
                                    key: ValueKey('waterDropLoader'),
                                  )
                                : Text(
                                    isLogin ? 'Login' : 'Sign up',
                                    key: ValueKey('button-$isLogin'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const _OrDivider(),
                      const SizedBox(height: 20),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton.facebook(),
                          SizedBox(width: 22),
                          _SocialButton.google(),
                          SizedBox(width: 22),
                          _SocialButton.apple(),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLogin
                                ? "Don't have an account? "
                                : 'Already have an account? ',
                            style: const TextStyle(
                              color: Color(0xFF9C9C9C),
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            key: const ValueKey('switchMode'),
                            onTap: onSwitchMode,
                            child: Text(
                              isLogin ? 'Sign up' : 'Login',
                              style: const TextStyle(
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF353535),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB1B1B1), fontSize: 13),
            suffixIcon: suffixIcon,
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2E0DE))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'Or',
            style: TextStyle(color: Color(0xFFB3B0AD), fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE2E0DE))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton.facebook()
    : icon = null,
      letter = 'f',
      color = const Color(0xFF1877F2);

  const _SocialButton.google()
    : icon = null,
      letter = 'G',
      color = const Color(0xFF4285F4);

  const _SocialButton.apple()
    : icon = Icons.apple,
      letter = null,
      color = Colors.black;

  final IconData? icon;
  final String? letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black12,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: icon != null
                ? Icon(icon, color: color, size: 25)
                : Text(
                    letter!,
                    style: TextStyle(
                      color: color,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
      ),
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

class _HeaderClipper extends CustomClipper<Path> {
  const _HeaderClipper({required this.shapeProgress});

  final double shapeProgress;

  @override
  Path getClip(Size size) {
    final leftY = size.height - 58 * shapeProgress;
    final centerY = size.height - 12 * shapeProgress;
    final rightY = size.height - 150 * shapeProgress;

    return Path()
      ..lineTo(0, leftY)
      ..quadraticBezierTo(
        size.width * 0.52,
        centerY + 42 * shapeProgress,
        size.width,
        rightY,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant _HeaderClipper oldClipper) {
    return oldClipper.shapeProgress != shapeProgress;
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF8F7F5),
      child: SafeArea(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.75 + value * 0.25, child: child),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.black,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Welcome to SLATE',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 7),
                Text(
                  'Everything is ready for you.',
                  style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
