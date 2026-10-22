import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gabaretor/main.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final langCode = LocaleProvider.supportedLanguageCodes
            .contains(localeProvider.locale.languageCode)
        ? localeProvider.locale.languageCode
        : 'en';
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.theme, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            DropdownButtonFormField<ThemeMode>(
              initialValue: themeProvider.themeMode,
              items: [
                DropdownMenuItem(value: ThemeMode.system, child: Text(context.l10n.system)),
                DropdownMenuItem(value: ThemeMode.light, child: Text(context.l10n.lightMode)),
                DropdownMenuItem(value: ThemeMode.dark, child: Text(context.l10n.darkMode)),
              ],
              onChanged: (ThemeMode? newMode) {
                if (newMode != null) {
                  themeProvider.toggleTheme(newMode);
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
            SizedBox(height: 8),
            Text(context.l10n.language, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: langCode,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'pt', child: Text('Português')),
              ],
              onChanged: (String? newLanguageCode) => {
                if (newLanguageCode != null) {
                  localeProvider.changeLocale(Locale(newLanguageCode))
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12)),
            ),
          ],
        ),
      ),
    );
  }
}