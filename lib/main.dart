import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa Firebase antes de arrancar app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref('sensores'); 
    // este es el nodo que estamos escuchando

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Realtime DB'),
      ),
      body: Center(
        child: StreamBuilder(
          stream: dbRef.onValue, // escucha cambios en tiempo real
          builder: (context, snapshot) {
            
            if (snapshot.hasError) {
              return const Text("Error leyendo datos");
            }

            if (!snapshot.hasData ||
                snapshot.data == null ||
                snapshot.data!.snapshot.value == null) {

              return const Text("Sin datos aún...");
            }

            final data =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Peso: ${data['peso']}"),
                Text("Agua: ${data['agua']}"),
              ],
            );
          },
        ),
      ),
    );
  }
}
