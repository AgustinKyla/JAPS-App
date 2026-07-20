// ignore_for_file: use_build_context_synchronously, unnecessary_underscores, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import '../main.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: ''); 
  final _passCtrl = TextEditingController(text: '');
  bool _obscure = true;
  bool _loading = false;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String? _loginError;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _loginError = null;
    });

    final enteredUsername = _userCtrl.text.trim().toLowerCase();
    final enteredPassword = _passCtrl.text;
    final fakeEmail = "$enteredUsername@japs.local";

    const allowedPrefixes = ['owner', 'secretary', 'audit'];
    final isAllowed = allowedPrefixes.any((p) => enteredUsername.startsWith(p));

    if (!isAllowed) {
      setState(() {
        _loading = false;
        _loginError = (enteredUsername.startsWith('driver') || enteredUsername.startsWith('conductor'))
            ? 'This portal is for Owner, Audit Teller, and Secretary accounts. '
                'Driver and Conductor access has not been set up yet.'
            : 'This portal is for Owner, Audit Teller, and Secretary accounts only.';
      });
      return;
    }

    try {
      final authService = AuthScope.of(context);
      final user = await authService.signInWithEmailAndPassword(
        fakeEmail,
        enteredPassword,
        username: enteredUsername,
      );

      if (!mounted) return;

      if (user != null) {
        setState(() => _loading = false);
        
        // Remove the call to initUserSession that caused the error
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: const MainShell()),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          _loginError = 'No user found with that username.';
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _loginError = 'Incorrect password. Please try again.';
        } else {
          _loginError = e.message ?? 'An error occurred during sign in.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loginError = 'Connection failed. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    final formCard = FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Card(
            elevation: 8,
            shadowColor: Colors.blue.withOpacity(0.50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/logo1.png',
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    const Text('Sign in to your JAPS account', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 24),
                    const Text('Username', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), // Reverted back to Username
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: _loginInputDecoration('Enter your username'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username is required';
                        if (v.trim().contains(' ')) return 'Usernames cannot contain spaces';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: _loginInputDecoration('Enter your password').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 19),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    if (_loginError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_loginError!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text('\u00A9 2026 JAPS. All rights reserved.', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/bg (wide).png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.55), Colors.black.withOpacity(0.15), Colors.black.withOpacity(0.55)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0, 0.5, 1],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(48, 48, 48, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: const [
                              SizedBox(width: 10),
                              Text('JAPS TRANSPORT', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Easily track daily remittances, manage trips, and use smart forecasting \nto improve your operations and grow your business.',
                            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            flex: wide ? 4 : 10,
            child: Container(
              color: AppColors.bg,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(child: formCard),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _loginInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: AppColors.bg,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.danger)),
  );
}