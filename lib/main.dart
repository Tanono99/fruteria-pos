import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

// Importamos el estado global
import 'core/app_state.dart'; 

// Importamos la navegación principal
import 'screens/main_navigation_screen.dart';

// Importamos el tema de la app
import 'theme/app_theme.dart';

void main() async {
  // Asegura que Flutter esté inicializado antes de usar async
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 AQUÍ ESTÁ LA SOLUCIÓN A LA PANTALLA BLANCA EN WEB:
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // <--- Faltaba pasarle esto
  );

  // 🔹 ESTO ES LO QUE ACTIVA EL MODO SIN INTERNET
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 🔹 ESTO ES LO QUE CONECTA TU BASE DE DATOS CON LA APP
  AppState.initListeners(); 

  // Inicia la app
  runApp(const GroceryPosApp());
}

/// Widget raíz de la aplicación
class GroceryPosApp extends StatelessWidget {
  const GroceryPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Frutería Trejo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationScreen(),
    );
  }
}