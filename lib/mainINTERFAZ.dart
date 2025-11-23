import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PetHouseApp());
}

class PetHouseApp extends StatelessWidget {
  const PetHouseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Pet House',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Poppins',
      ),
      home: const PetHouseDashboard(),
    );
  }
}

class PetHouseDashboard extends StatefulWidget {
  const PetHouseDashboard({Key? key}) : super(key: key);

  @override
  State<PetHouseDashboard> createState() => _PetHouseDashboardState();
}

class _PetHouseDashboardState extends State<PetHouseDashboard> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Variables para almacenar datos de sensores
  double foodWeight = 0.0;
  double waterLevel = 0.0;
  double temperature = 0.0;
  double humidity = 0.0;
  double distance = 0.0;
  bool uvLightOn = false;
  bool foodDoorOpen = false;
  bool isDogInside = false;
  
  // Control de alertas mostradas
  bool lowFoodAlertShown = false;
  bool lowWaterAlertShown = false;
  bool highTempAlertShown = false;
  bool lowTempAlertShown = false;
  
  StreamSubscription? _sensorsSubscription;
  StreamSubscription? _commandsSubscription;

  @override
  void initState() {
    super.initState();
    _setupFirebaseListeners();
  }

  void _setupFirebaseListeners() {
    // Escuchar cambios en los sensores
    _sensorsSubscription = _database.child('sensores').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          foodWeight = (data['peso'] ?? 0).toDouble();
          waterLevel = (data['agua'] ?? 0).toDouble();
          temperature = (data['temperatura'] ?? 0).toDouble();
          humidity = (data['humedad'] ?? 0).toDouble();
          distance = (data['distancia'] ?? 0).toDouble();
          
          // Determinar si el perro está dentro (distancia < 27)
          isDogInside = distance < 27.0;
        });
        
        // Verificar alertas críticas
        _checkCriticalAlerts();
      }
    });

    // Escuchar cambios en los comandos
    _commandsSubscription = _database.child('comandos').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          uvLightOn = data['luz'] ?? false;
          foodDoorOpen = data['servo'] ?? false;
        });
      }
    });
  }

  void _checkCriticalAlerts() {
    // Alerta de comida baja
    if (foodWeight < 50000 && !lowFoodAlertShown) {
      lowFoodAlertShown = true;
      _showLowFoodAlert();
    } else if (foodWeight >= 50000) {
      lowFoodAlertShown = false;
    }

    // Alerta de agua baja
    if (waterLevel < 20 && !lowWaterAlertShown) {
      lowWaterAlertShown = true;
      _showLowWaterAlert();
    } else if (waterLevel >= 20) {
      lowWaterAlertShown = false;
    }

    // Alerta de temperatura alta (más de 30°C)
    if (temperature > 30 && !highTempAlertShown) {
      highTempAlertShown = true;
      _showTemperatureAlert('alta');
    } else if (temperature <= 30) {
      highTempAlertShown = false;
    }

    // Alerta de temperatura baja (menos de 15°C)
    if (temperature < 15 && !lowTempAlertShown) {
      lowTempAlertShown = true;
      _showTemperatureAlert('baja');
    } else if (temperature >= 15) {
      lowTempAlertShown = false;
    }
  }

  void _showLowFoodAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B9D), size: 30),
              SizedBox(width: 10),
              Text('Comida Baja'),
            ],
          ),
          content: const Text(
            'El nivel de comida está por debajo de 50g. Por favor, rellena el plato pronto.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showLowWaterAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF6B7FFF), size: 30),
              SizedBox(width: 10),
              Text('Agua Baja'),
            ],
          ),
          content: const Text(
            'El nivel de agua está por debajo del 20%. Por favor, rellena el bebedero.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _showTemperatureAlert(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.thermostat, color: Color(0xFFFF8A80), size: 30),
              const SizedBox(width: 10),
              Text('Temperatura ${type == 'alta' ? 'Alta' : 'Baja'}'),
            ],
          ),
          content: Text(
            type == 'alta'
                ? 'La temperatura está por encima de 30°C. Considera encender ventilación o aire acondicionado.'
                : 'La temperatura está por debajo de 15°C. Considera proporcionar calefacción.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _sensorsSubscription?.cancel();
    _commandsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateCommand(String command, bool value) async {
    try {
      await _database.child('comandos/$command').set(value);
      print('Comando actualizado: $command = $value');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                
                // Indicador de presencia del perrito
                _buildDogPresenceIndicator(),
                const SizedBox(height: 30),
                
                const Text(
                  'Zona de Alimentación',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 15),
                _buildSensorsGrid(),

                const SizedBox(height: 30),

                const Text(
                  'Controles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 15),
                _buildControlsSection(),

                const SizedBox(height: 30),

                const Text(
                  'Ambiente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 15),
                _buildEnvironmentCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Casita Inteligente',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'DomotiCan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.pets,
            color: Color(0xFF6B7FFF),
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildDogPresenceIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDogInside
              ? [const Color(0xFF81C784), const Color(0xFFA5D6A7)]
              : [const Color(0xFFE0E0E0), const Color(0xFFBDBDBD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDogInside ? const Color(0xFF81C784) : Colors.grey).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              isDogInside ? Icons.home : Icons.home_outlined,
              color: Colors.white,
              size: 35,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDogInside ? '¡Tu perrito está en casa!' : 'Perrito ausente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isDogInside
                      ? 'Detectado dentro de la casita'
                      : 'No se detecta presencia',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${distance.toStringAsFixed(1)} cm',
              style: TextStyle(
                color: isDogInside ? const Color(0xFF81C784) : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildSensorCard(
            'Comida',
            '${(foodWeight / 1000).toStringAsFixed(1)}g',
            Icons.grain,
            const Color(0xFFFF6B9D),
            const Color(0xFFFFA0BC),
            foodWeight < 50000,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildSensorCard(
            'Agua',
            '${waterLevel.toStringAsFixed(0)}%',
            Icons.water_drop,
            const Color(0xFF6B7FFF),
            const Color(0xFF9BA9FF),
            waterLevel < 20,
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    IconData icon,
    Color startColor,
    Color endColor,
    bool isLow,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [startColor, endColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: 30,
              ),
              if (isLow)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Column(
      children: [
        _buildControlCard(
          'Luz UV Desinfectante',
          'Elimina bacterias y gérmenes',
          Icons.lightbulb,
          const Color(0xFFFFB74D),
          uvLightOn,
          (value) {
            _updateCommand('luz', value);
          },
        ),
        const SizedBox(height: 15),
        _buildControlCard(
          'Compuerta de Comida',
          'Controla el acceso a la comida',
          Icons.door_sliding,
          const Color(0xFF81C784),
          foodDoorOpen,
          (value) {
            _updateCommand('servo', value);
          },
        ),
      ],
    );
  }

  Widget _buildControlCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool isActive,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isActive,
              onChanged: onChanged,
              activeColor: color,
              activeTrackColor: color.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCards() {
    return Row(
      children: [
        Expanded(
          child: _buildEnvironmentCard(
            'Temperatura',
            '${temperature.toStringAsFixed(1)}°C',
            Icons.thermostat,
            const Color(0xFFFF8A80),
            temperature / 50,
            temperature < 15 || temperature > 30,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildEnvironmentCard(
            'Humedad',
            '${humidity.toStringAsFixed(0)}%',
            Icons.water,
            const Color(0xFF64B5F6),
            humidity / 100,
            false,
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentCard(
    String title,
    String value,
    IconData icon,
    Color color,
    double progress,
    bool isWarning,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Icon(
                icon,
                color: color,
                size: 35,
              ),
              if (isWarning)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
    );
  }
}
