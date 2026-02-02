import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

void main() {
  runApp(const ModemRestartApp());
}

class ModemRestartApp extends StatelessWidget {
  const ModemRestartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modem Restart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0a0a1a),
        fontFamily: 'Roboto',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // تنظیمات مودم
  static const String modemIP = "http://192.168.1.1";
  static const String username = "admin";
  static const String password = "admin";

  // رنگ‌ها
  static const Color neonBlue = Color(0xFF00d4ff);
  static const Color neonGreen = Color(0xFF00ff88);
  static const Color neonOrange = Color(0xFFff9500);
  static const Color neonRed = Color(0xFFff3366);
  static const Color neonYellow = Color(0xFFffee00);

  // وضعیت
  String status = "Ready for Your Command!";
  Color statusColor = neonGreen;
  String logText = "⏳ Waiting for your command...";
  Color logColor = neonYellow;
  Color buttonColor = neonBlue;
  bool isWorking = false;

  // انیمیشن‌ها
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // انیمیشن نبض
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // انیمیشن چرخش
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> restartModem() async {
    if (isWorking) return;

    setState(() {
      isWorking = true;
      buttonColor = neonOrange;
      status = "Working...";
      statusColor = neonOrange;
      logText = "🔐 Connecting to modem...";
      logColor = neonYellow;
    });

    _rotateController.repeat();

    try {
      // لاگین
      setState(() => logText = "🔐 Authenticating...");
      
      final loginResponse = await http.post(
        Uri.parse("$modemIP/authenticate.leano"),
        body: "authenticate $username $password",
        headers: {'User-Agent': 'ModemRestartPro/2.0'},
      ).timeout(const Duration(seconds: 10));

      if (loginResponse.statusCode == 200) {
        final jsonData = json.decode(loginResponse.body);
        final token = jsonData['token'];

        if (token != null) {
          setState(() => logText = "✓ Login OK\n📤 Sending reboot command...");

          // ریستارت
          final rebootResponse = await http.post(
            Uri.parse("$modemIP/api.leano"),
            body: "reboott",
            headers: {
              'User-Agent': 'ModemRestartPro/2.0',
              'Leano_Auth': token,
              'X-Requested-With': 'XMLHttpRequest',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
          ).timeout(const Duration(seconds: 10));

          if (rebootResponse.statusCode == 200) {
            _success();
          } else {
            _error("Reboot failed (${rebootResponse.statusCode})");
          }
        } else {
          _error("No token received");
        }
      } else {
        _error("Login failed (${loginResponse.statusCode})");
      }
    } on TimeoutException {
      _error("Connection timeout");
    } catch (e) {
      _error("Connection error");
    }
  }

  void _success() {
    _rotateController.stop();
    setState(() {
      isWorking = false;
      buttonColor = neonGreen;
      status = "Modem Rebooting!";
      statusColor = neonGreen;
      logText = "✅ ریستارت مودم با موفقیت انجام شد!\n⏱ حدود ۳۰ ثانیه صبر کنید...";
      logColor = neonGreen;
    });

    Future.delayed(const Duration(seconds: 5), _reset);
  }

  void _error(String message) {
    _rotateController.stop();
    setState(() {
      isWorking = false;
      buttonColor = neonRed;
      status = "Error!";
      statusColor = neonRed;
      logText = "❌ خطا: $message";
      logColor = neonRed;
    });

    Future.delayed(const Duration(seconds: 4), _reset);
  }

  void _reset() {
    setState(() {
      buttonColor = neonBlue;
      status = "Ready for Your Command!";
      statusColor = neonGreen;
      logText = "⏳ Waiting for your command...";
      logColor = neonYellow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // عنوان
            const Text(
              'Modem Restart',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'One tap to restart your modem',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            const Spacer(),
            
            // دکمه پاور نئونی
            GestureDetector(
              onTap: restartModem,
              child: AnimatedBuilder(
                animation: Listenable.merge([_pulseAnimation, _rotateController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: isWorking ? 1.0 : _pulseAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: buttonColor.withOpacity(0.2),
                            blurRadius: 80,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: buttonColor, width: 4),
                          gradient: RadialGradient(
                            colors: [
                              buttonColor.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: isWorking ? _rotateController.value * 2 * math.pi : 0,
                            child: Icon(
                              Icons.power_settings_new,
                              size: 80,
                              color: buttonColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const Spacer(),
            
            // وضعیت
            Text(
              status,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: statusColor,
              ),
            ),
            
            const SizedBox(height: 40),
            
            // لاگ
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF12122a),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                logText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: logColor,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
