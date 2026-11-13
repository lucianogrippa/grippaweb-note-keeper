import 'package:flutter/material.dart';
import 'package:note_keeper/app/theme/theme_controller.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeControllerScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      enabled: !controller.saving,
      icon: const Icon(Icons.palette_outlined),
      onSelected: (mode) async {
        try {
          await controller.setMode(mode);
        } catch (error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not save theme: $error')),
            );
          }
        }
      },
      itemBuilder: (context) => [
        for (final (mode, label, icon) in [
          (ThemeMode.system, 'System', Icons.brightness_auto),
          (ThemeMode.light, 'Light', Icons.light_mode),
          (ThemeMode.dark, 'Dark', Icons.dark_mode),
        ])
          CheckedPopupMenuItem<ThemeMode>(
            value: mode,
            checked: controller.mode == mode,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [Icon(icon), const SizedBox(width: 8), Text(label)],
            ),
          ),
      ],
    );
  }
}
