import 'package:flutter/material.dart';

import 'app.dart';
import 'core/theme.dart';
import 'data/quran_loader.dart';
import 'services/app_storage.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

/// Loads the bundled Quran data and local storage, then shows the app.
/// If loading fails (for example a corrupted asset) an explanatory error screen
/// is shown instead of crashing.
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<AppState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AppState> _load() async {
    final data = await loadQuranData();
    final storage = await AppStorage.open();
    return AppState(data: data, storage: storage);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<AppState> snapshot) {
        final AppState? app = snapshot.data;
        if (app != null) {
          return HifzApp(app: app);
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            home: _LoadError(
              message: '${snapshot.error}',
              onRetry: () => setState(() {
                _future = _load();
              }),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          home: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 16),
              const Text(
                'The Quran data could not be loaded.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
