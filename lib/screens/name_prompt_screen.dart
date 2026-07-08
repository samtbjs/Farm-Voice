import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

/// Shown once, only to brand-new phone sign-ins, since a phone number
/// alone isn't a nice thing to greet someone with.
class NamePromptScreen extends StatefulWidget {
  const NamePromptScreen({super.key});

  @override
  State<NamePromptScreen> createState() => _NamePromptScreenState();
}

class _NamePromptScreenState extends State<NamePromptScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    await AuthService.instance.updateDisplayName(name);
    if (!mounted) return;
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What should we call you?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll use this to greet you on the home screen.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    hintText: 'Your name',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Continue'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : _goHome,
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}