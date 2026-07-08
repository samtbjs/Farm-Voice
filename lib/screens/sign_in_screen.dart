import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import '../widgets/social_sign_in_button.dart';
import '../widgets/or_divider.dart';
import '../widgets/processing_overlay.dart';
import 'email_auth_screen.dart';
import 'home_screen.dart';
import 'phone_number_screen.dart';

/// Sign in / sign up screen shown when there's no signed-in user.
///
/// Same layout as before — only the button actions changed, from
/// "navigate straight to Home" to real Firebase sign-in.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isLoading = false;

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      if (userCredential == null) {
        // Farmer backed out of the Google account picker — not an error.
        setState(() => _isLoading = false);
        return;
      }
      _goHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message ?? 'Google sign-in failed. Please try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Google sign-in failed. Please try again.');
    }
  }

  void _goToPhoneSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
    );
  }

  void _goToEmailSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.eco_rounded,
                      size: 44,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Farm Voice',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your farming questions, answered.\nSpeak, type, or show us a photo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  SocialSignInButton(
                    label: 'Continue with Google',
                    icon: Icons.account_circle_outlined,
                    onTap: _isLoading ? () {} : _handleGoogleSignIn,
                  ),
                  const SizedBox(height: 12),
                  SocialSignInButton(
                    label: 'Continue with phone number',
                    icon: Icons.phone_iphone_rounded,
                    onTap: _isLoading ? () {} : () => _goToPhoneSignIn(context),
                  ),
                  const SizedBox(height: 20),
                  const OrDivider(label: 'or'),
                  const SizedBox(height: 20),
                  SocialSignInButton(
                    label: 'Continue with email',
                    icon: Icons.mail_outline_rounded,
                    onTap: _isLoading ? () {} : () => _goToEmailSignIn(context),
                    filled: true,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'By continuing, you agree to our Terms and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Positioned.fill(
                child: ProcessingOverlay(message: 'Signing you in…'),
              ),
          ],
        ),
      ),
    );
  }
}
