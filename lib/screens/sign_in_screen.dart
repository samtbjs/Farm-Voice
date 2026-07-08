import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/social_sign_in_button.dart';
import 'email_auth_screen.dart';

/// Sign in / sign up screen shown when there's no signed-in user.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  void _goToEmailSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EmailAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                label: 'Continue with email',
                icon: Icons.mail_outline_rounded,
                onTap: () => _goToEmailSignIn(context),
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
      ),
    );
  }
}
