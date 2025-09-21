import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDYK1XrakWoJlBEvTT-mbIQkjjcbeSP988",
      authDomain: "wissaltalbi-309e1.firebaseapp.com",
      databaseURL: "https://wissaltalbi-309e1-default-rtdb.asia-southeast1.firebasedatabase.app",
      projectId: "wissaltalbi-309e1",
      storageBucket: "wissaltalbi-309e1.firebasestorage.app",
      messagingSenderId: "382275735000",
      appId: "1:382275735000:web:b2f8961348f4529398f6ad"
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Farming',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.transparent),
      home: CapteurScreen(),
    );
  }
}

class CapteurScreen extends StatefulWidget {
  @override
  _CapteurScreenState createState() => _CapteurScreenState();
}

class _CapteurScreenState extends State<CapteurScreen> {
  final DatabaseReference dbRef = FirebaseDatabase.instance.ref("Wissal");
  final Random random = Random();

  double? temperature;
  double? humiditeAir;
  int? humiditeSol;

  final TextEditingController questionController = TextEditingController();
  String? reponseChatbot;

  @override
  void initState() {
    super.initState();
    
    // D'abord, écouter les vraies données Firebase
    dbRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        setState(() {
          temperature = double.tryParse(data["temperature"].toString());
          humiditeAir = double.tryParse(data["humidite_air"].toString());
          humiditeSol = int.tryParse(data["humidite_sol"].toString());
        });
        print("Données reçues de Firebase: Temp=$temperature, HumidAir=$humiditeAir, HumidSol=$humiditeSol");
      }
    });
    
    // Si aucune donnée n'arrive dans les 5 premières secondes, utiliser la simulation
    Timer(Duration(seconds: 5), () {
      if (temperature == null && humiditeAir == null && humiditeSol == null) {
        print("Aucune donnée Firebase reçue, passage en mode simulation");
        simulerDonnees();
      }
    });
  }

  void simulerDonnees() {
    // Générer des données réalistes toutes les 5 secondes
    Future.delayed(Duration.zero, () {
      setState(() {
        temperature = 20.0 + random.nextDouble() * 15; // 20-35°C
        humiditeAir = 40.0 + random.nextDouble() * 40; // 40-80%
        humiditeSol = 1000 + random.nextInt(800); // 1000-1800
      });
    });

    // Répéter toutes les 5 secondes
    Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        temperature = 20.0 + random.nextDouble() * 15;
        humiditeAir = 40.0 + random.nextDouble() * 40;
        humiditeSol = 1000 + random.nextInt(800);
      });
    });
  }

  Future<String> appelerChatbotSimule(String question, double? temp, double? humidAir, int? humidSol) async {
    // Simulation d'un chatbot simple sans serveur Ollama
    await Future.delayed(Duration(seconds: 2)); // Simule le temps de réponse
    
    String reponse = "";
    
    if (question.toLowerCase().contains("température")) {
      if (temp != null && temp > 30) {
        reponse = "La température est élevée (${temp.toStringAsFixed(1)}°C). Pensez à arroser vos plantes et à les protéger du soleil.";
      } else if (temp != null && temp < 15) {
        reponse = "La température est basse (${temp.toStringAsFixed(1)}°C). Protégez vos cultures sensibles au froid.";
      } else {
        reponse = "La température est normale (${temp?.toStringAsFixed(1) ?? 'N/A'}°C). Conditions favorables pour la plupart des cultures.";
      }
    } else if (question.toLowerCase().contains("humidité") && question.toLowerCase().contains("sol")) {
      if (humidSol != null && humidSol < 1300) {
        reponse = "Le sol est sec (${humidSol}). Il est temps d'arroser vos plantes !";
      } else {
        reponse = "Le sol a un bon niveau d'humidité (${humidSol ?? 'N/A'}). Pas besoin d'arroser maintenant.";
      }
    } else if (question.toLowerCase().contains("humidité") && question.toLowerCase().contains("air")) {
      if (humidAir != null && humidAir > 70) {
        reponse = "L'air est très humide (${humidAir.toStringAsFixed(1)}%). Surveillez les risques de maladies fongiques.";
      } else if (humidAir != null && humidAir < 40) {
        reponse = "L'air est sec (${humidAir.toStringAsFixed(1)}%). Vos plantes pourraient avoir besoin de plus d'arrosage.";
      } else {
        reponse = "L'humidité de l'air est correcte (${humidAir?.toStringAsFixed(1) ?? 'N/A'}%).";
      }
    } else if (question.toLowerCase().contains("arroser") || question.toLowerCase().contains("irrigation")) {
      if (humidSol != null && humidSol < 1300) {
        reponse = "Oui, il faut arroser ! Le sol est sec avec une valeur de ${humidSol}.";
      } else {
        reponse = "Pas besoin d'arroser maintenant. Le sol a suffisamment d'humidité.";
      }
    } else {
      reponse = "Voici l'état actuel : Température: ${temp?.toStringAsFixed(1) ?? 'N/A'}°C, Humidité air: ${humidAir?.toStringAsFixed(1) ?? 'N/A'}%, Humidité sol: ${humidSol ?? 'N/A'}. Posez une question plus spécifique sur la température, l'humidité ou l'arrosage !";
    }
    
    return reponse;
  }

  void envoyerQuestion() {
    String question = questionController.text.trim();
    if (question.isEmpty) return;
    setState(() => reponseChatbot = "Analyse en cours...");
    Future.microtask(() async {
      String reponse = await appelerChatbotSimule(question, temperature, humiditeAir, humiditeSol);
      setState(() => reponseChatbot = reponse);
      questionController.clear();
    });
  }

  Widget ledIndicatorBanner(int? soilHumidity) {
    if (soilHumidity == null) return SizedBox.shrink();

    final bool ledAllumee = soilHumidity <= 1500;
    final String message = ledAllumee ? " Sol sec " : " Sol humide ";
    final Color bgColor = ledAllumee ? Colors.redAccent.withOpacity(0.8) : Colors.green.withOpacity(0.7);
    final IconData icon = ledAllumee ? Icons.warning_amber_rounded : Icons.eco_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          SizedBox(width: 10),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade800,
                Colors.green.shade600,
                Colors.brown.shade400,
              ],
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.black.withOpacity(0.3),
          appBar: AppBar(
            title: Text("🤖 AgriBot Assistant"),
            backgroundColor: Colors.transparent,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: temperature == null && humiditeAir == null && humiditeSol == null
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ledIndicatorBanner(humiditeSol),

                          SemiCircleGauge(
                            title: "🌡 Température",
                            value: temperature ?? 0,
                            max: 100,
                            interval: 10,
                            unit: "°C",
                            width: 300,
                            height: 210,
                          ),
                          SizedBox(height: 30),
                          SemiCircleGauge(
                            title: "💧 Humidité Air",
                            value: humiditeAir ?? 0,
                            max: 200,
                            interval: 20,
                            unit: "%",
                            width: 300,
                            height: 210,
                          ),
                          SizedBox(height: 30),
                          SemiCircleGauge(
                            title: "🌱 Humidité Sol",
                            value: humiditeSol?.toDouble() ?? 0,
                            max: 1600,
                            interval: 200,
                            unit: "%",
                            width: 300,
                            height: 210,
                          ),
                          SizedBox(height: 30),
                          TextField(
                            controller: questionController,
                            style: TextStyle(color: Colors.white),
                            onSubmitted: (_) => envoyerQuestion(),
                            decoration: InputDecoration(
                              hintText: "Pose ta question (température, humidité, arrosage...)",
                              hintStyle: TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.send, color: Colors.white),
                                onPressed: envoyerQuestion,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          if (reponseChatbot != null && reponseChatbot!.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                reponseChatbot!,
                                style: TextStyle(fontSize: 16, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class SemiCircleGauge extends StatelessWidget {
  final String title;
  final double value;
  final double max;
  final double interval;
  final String unit;
  final double width;
  final double height;

  const SemiCircleGauge({
    required this.title,
    required this.value,
    required this.max,
    required this.interval,
    required this.unit,
    this.width = 300,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: SfRadialGauge(
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: max,
            interval: interval,
            labelFormat: '{value}',
            startAngle: 180,
            endAngle: 0,
            radiusFactor: 1,
            showTicks: true,
            showLabels: true,
            axisLineStyle: AxisLineStyle(
              thickness: 15,
              cornerStyle: CornerStyle.bothCurve,
            ),
            pointers: <GaugePointer>[
              RangePointer(
                value: value,
                width: 15,
                color: Colors.orangeAccent,
                cornerStyle: CornerStyle.bothCurve,
              ),
              NeedlePointer(
                value: value,
                enableAnimation: true,
              ),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                angle: 90,
                positionFactor: 0.5,
                widget: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, color: Colors.white)),
                    Text("${value.toStringAsFixed(1)} $unit",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}