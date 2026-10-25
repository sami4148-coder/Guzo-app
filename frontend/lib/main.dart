import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'state/auth_state.dart';
import 'state/favorite_hotels_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  runApp(const GuzoApp());
}

class GuzoApp extends StatefulWidget {
  const GuzoApp({super.key});

  @override
  State<GuzoApp> createState() => _GuzoAppState();
}

class _GuzoAppState extends State<GuzoApp> {
  late final AuthState _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthState();
    _router = createGuzoRouter(_auth);
    _auth.bootstrap();
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => FavoriteHotelsState()),
      ],
      child: MaterialApp.router(
        title: 'GUZO',
        debugShowCheckedModeBanner: false,
        theme: GuzoTheme.light(),
        routerConfig: _router,
      ),
    );
  }
}
