import 'dart:ui';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:gabaretor/core/services/vision/ocr_engine.dart';
import 'package:provider/provider.dart';
import 'core/storage_manager.dart';
import 'screens/tests_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/settings_screen.dart';

List<CameraDescription> cameras = [];

extension LocalizedBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class LocaleProvider extends ChangeNotifier {
  static const List<String> supportedLanguageCodes = ['en', 'pt'];

  Locale _locale = _initialLocale();
  Locale get locale => _locale;

  static Locale _initialLocale() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return Locale(supportedLanguageCodes.contains(code) ? code : 'en');
  }

  void changeLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await StorageManager.init();
  } catch (_) {}

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: MyApp(),
    )
  );

  _bootstrap();
}

Future<void> _bootstrap() async {
  try {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    try {
      cameras = await availableCameras();
    } catch (_) {
      cameras = [];
    }

    try {
      await OcrDetector.init();
    } catch (_) {}
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    return MaterialApp(
      title: 'Gabaretor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: [
        Locale('en', 'US'),
        Locale('pt', 'BR'),
      ],
      home: MainNavigationPage(),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      const TestsTab(),
      const ClassTab(),
      const SettingsTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: context.l10n.tests),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: context.l10n.classes),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: context.l10n.settings)
        ],
      ),
    );
  }
}

class TextPromptDialog extends StatefulWidget {
  final String title;
  final String hint;
  final String? initialValue;
  final FormFieldValidator<String> validator;
  final IconData? icon;
  final String cancelLabel;
  final String saveLabel;

  const TextPromptDialog({super.key, 
    required this.title,
    required this.hint,
    required this.validator,
    required this.cancelLabel,
    required this.saveLabel,
    this.initialValue,
    this.icon,
  });

  @override
  State<TextPromptDialog> createState() => TextPromptDialogState();
}

class TextPromptDialogState extends State<TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue ?? '');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: widget.icon != null ? Icon(widget.icon) : null,
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          maxLength: 50,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: widget.hint, counterText: ''),
          validator: widget.validator,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}