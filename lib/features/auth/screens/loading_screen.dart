/*import 'package:flutter/material.dart';
import 'dart:async';

// استيراد الشاشة المقصودة للتوجيه بعد اكتمال التحميل
import '../../dashboard/screens/dashboard_screen.dart'; // تأكدي أن هذا المسار يطابق مجلداتكِ

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  double _loadingProgress = 0.0;
  String _loadingStatus = 'INITIALIZING SYSTEM CORES...';
  Timer? _progressTimer;
  late AnimationController _rotationController; 

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _startBootSequence();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _rotationController.dispose(); 
    super.dispose();
  }

  void _startBootSequence() {
    const totalSteps = 100;
    const duration = Duration(milliseconds: 25); 

    _progressTimer = Timer.periodic(duration, (timer) {
      if (!mounted) return;

      setState(() {
        if (_loadingProgress < 1.0) {
          _loadingProgress += 1 / totalSteps;

          if (_loadingProgress > 0.25 && _loadingProgress <= 0.55) {
            _loadingStatus = 'ESTABLISHING ESP32 PROTOCOL...';
          } else if (_loadingProgress > 0.55 && _loadingProgress <= 0.85) {
            _loadingStatus = 'SYNCING SEW-EURODRIVE DIGITAL MODEL...';
          } else if (_loadingProgress > 0.85) {
            _loadingStatus = 'ALGORITHMS READY. LAUNCHING CENTER...';
          }
        } else {
          _progressTimer?.cancel();
          _navigateToDashboard(); // 🚀 استدعاء دالة الانتقال المباشر للـ Dashboard
        }
      });
    });
  }

  // 🎯 التوجيه الهندسي النظيف والمباشر للـ DashboardScreen بعد نجاح عملية الـ Boot
  void _navigateToDashboard() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgDark = isDark ? const Color(0xFF0A0F1D) : const Color(0xFF1E60D5); 
    final Color textMain = isDark ? const Color(0xFF00E5FF) : Colors.white;
    final Color progressColor = isDark ? const Color(0xFF9D4EDD) : Colors.white; 
    final Color trackColor = isDark ? const Color(0xFF9D4EDD).withOpacity(0.15) : Colors.white.withOpacity(0.25);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: _rotationController,
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: List.generate(8, (index) {
                      final double opacity = 0.2 + (index * 0.1); 
                      return Positioned.fill(
                        child: Align(
                          alignment: _getAlignmentForIndex(index),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: textMain.withOpacity(opacity), 
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                'FEEDCOM DIGITAL TWIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'CONTROL CENTER v1.0.0',
                style: TextStyle(
                  color: isDark ? Colors.grey : Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: 100, 
                height: 10,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: trackColor,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _loadingStatus,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : Colors.white.withOpacity(0.8),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${(_loadingProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _getAlignmentForIndex(int index) {
    switch (index) {
      case 0: return Alignment.topCenter;
      case 1: return const Alignment(0.7, -0.7);
      case 2: return Alignment.centerRight;
      case 3: return const Alignment(0.7, 0.7);
      case 4: return Alignment.bottomCenter;
      case 5: return const Alignment(-0.7, 0.7);
      case 6: return Alignment.centerLeft;
      case 7: return const Alignment(-0.7, -0.7);
      default: return Alignment.center;
    }
  }
}*/