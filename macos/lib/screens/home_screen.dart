import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../widgets/dashboard_action_card.dart';
import 'voice_screen.dart';
import 'camera_screen.dart';

/// The entire home dashboard: a plain header and exactly two massive
/// action cards. Nothing else lives here on purpose — keep it simple
/// to build on top of.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Farm Voice')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                child: DashboardActionCard(
                  label: 'Tap & Speak',
                  icon: Icons.mic_rounded,
                  color: AppColors.green,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const VoiceScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DashboardActionCard(
                  label: 'Scan Crop',
                  icon: Icons.camera_alt_rounded,
                  color: AppColors.amber,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CameraScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
