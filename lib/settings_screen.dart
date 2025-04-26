import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: settings.createTextStyle(TextType.title, color: textColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildThemeCard(settings, textColor),
          const SizedBox(height: 24),
          _buildFontSizeCard(settings, textColor),
          const SizedBox(height: 24),
          _buildTextPreview(settings),
        ],
      ),
    );
  }

  Widget _buildThemeCard(AppSettings settings, Color textColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Theme',
              style: settings.createTextStyle(TextType.title, color: textColor),
            ),
            const SizedBox(height: 12),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (newSelection) {
                settings.updateThemeMode(newSelection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeCard(AppSettings settings, Color textColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Sizing',
              style: settings.createTextStyle(TextType.title, color: textColor),
            ),
            const SizedBox(height: 12),
            Slider(
              value: settings.baseFontSize,
              min: 12,
              max: 24,
              divisions: 6,
              label: 'Base Size: ${settings.baseFontSize.round()}',
              onChanged: (value) {
                settings.updateBaseFontSize(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview(AppSettings settings) {
    final isDark = settings.themeMode == ThemeMode.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Card(
      color: isDark ? Colors.grey[900] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Preview',
              style: settings.createTextStyle(TextType.title, color: textColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Display Text',
              style: settings.createTextStyle(TextType.display, color: textColor),
            ),
            Text(
              'Headline Text',
              style: settings.createTextStyle(TextType.headline, color: textColor),
            ),
            Text(
              'Title Text',
              style: settings.createTextStyle(TextType.title, color: textColor),
            ),
            Text(
              'Regular Body Text',
              style: settings.createTextStyle(TextType.body, color: textColor),
            ),
            Text(
              'Small Label Text',
              style: settings.createTextStyle(TextType.label, color: isDark ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}