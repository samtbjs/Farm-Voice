import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The combined input row for [AdvisoryChatScreen]: attach-photo
/// button, a text field, and a mic button — all optional, any
/// combination can be sent together.
///
/// [photoBytes] is the real captured image (or null if none is
/// attached yet) — when present, a thumbnail preview is shown in the
/// attached-photo chip so the farmer can see exactly what they're
/// about to send.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.photoBytes,
    required this.isRecording,
    required this.enabled,
    required this.onAttachPhoto,
    required this.onRemovePhoto,
    required this.onMicTap,
    required this.onSend,
  });

  final TextEditingController controller;
  final Uint8List? photoBytes;
  final bool isRecording;

  /// False while a Gemini call, speech recognition, or image analysis
  /// is already in flight — disables all controls so the farmer can't
  /// fire off a second request on top of one that's still running.
  final bool enabled;

  final VoidCallback onAttachPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onMicTap;
  final ValueChanged<String> onSend;

  bool get hasPhoto => photoBytes != null;

  void _handleSend() {
    final text = controller.text.trim();
    if (text.isEmpty && !hasPhoto) return;
    onSend(text);
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasPhoto) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.10),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.30)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    photoBytes!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Photo attached',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  onPressed: enabled ? onRemovePhoto : null,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              _RoundIconButton(
                icon: Icons.camera_alt_rounded,
                color: AppColors.amber,
                onTap: enabled ? onAttachPhoto : null,
                size: 40,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type your question',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final bool readyToSend =
                      value.text.trim().isNotEmpty || hasPhoto;
                  final IconData icon = isRecording
                      ? Icons.stop_rounded
                      : readyToSend
                          ? Icons.send_rounded
                          : Icons.mic_rounded;
                  final Color color = isRecording
                      ? AppColors.amber
                      : AppColors.green;
                  final VoidCallback? onTap = !enabled && !isRecording
                      ? null
                      : (readyToSend ? _handleSend : onMicTap);
                  return _RoundIconButton(
                    icon: icon,
                    color: color,
                    onTap: onTap,
                    size: 44,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Every answer is read aloud automatically',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Material(
      color: disabled ? color.withValues(alpha: 0.4) : color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: size * 0.48),
        ),
      ),
    );
  }
}
