import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class DigitalTwinMotorView extends StatefulWidget {
  final String currentMode; // يربط حركة الـ Twin مع أزرار المحاكاة
  final String currentLang; // 🌐 استقبال اللغة الحالية ('en' أو 'fr')
  final bool isDarkMode;    // ☀️/🌙 استقبال حالة الثيم (true للمظلم، false للمضيء)

  const DigitalTwinMotorView({
    super.key,
    required this.currentLang,
    required this.currentMode,
    required this.isDarkMode, // مريغل
  });

  @override
  State<DigitalTwinMotorView> createState() => _DigitalTwinMotorViewState();
}

class _DigitalTwinMotorViewState extends State<DigitalTwinMotorView>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  static const Map<String, Map<String, String>> _localizedTwinTexts = {
    'en': {
      'twin_title': 'DIGITAL TWIN REALTIME 3D MODEL',
      'rotor_speed': 'ROTOR SPEED',
      'flux_vector': 'FLUX VECTOR',
      'thermal_state': 'THERMAL STATE',
      'stagnant': 'STAGNANT',
      'synchronous': 'SYNCHRONOUS',
      'critical': 'CRITICAL',
      'nominal': 'NOMINAL',
    },
    'fr': {
      'twin_title': 'MODÈLE 3D DU JUMEAU NUMÉRIQUE',
      'rotor_speed': 'VITESSE DU ROTOR',
      'flux_vector': 'VECTEUR DE FLUX',
      'thermal_state': 'ÉTAT THERMIQUE',
      'stagnant': 'STAGNANT',
      'synchronous': 'SYNCHRONE',
      'critical': 'CRITIQUE',
      'nominal': 'NOMINAL',
    },
  };

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..repeat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  String _getRotationSpeed() {
    switch (widget.currentMode) {
      case 'emergency_stop': return '0deg';
      case 'overload': return '150deg';
      case 'high_vibration': return '90deg';
      case 'bearing_damage': return '20deg';
      case 'cooling_failure': return '45deg';
      case 'normal':
      default: return '40deg';
    }
  }

  Color _getTelemetryColor() {
    switch (widget.currentMode) {
      case 'normal': return const Color(0xFF00E676);
      case 'overload': return const Color(0xFFFFB300);
      case 'cooling_failure': return const Color(0xFF00C2FF);
      case 'high_vibration': return const Color(0xFFFF9800);
      case 'bearing_damage': return const Color(0xFFFF5252);
      case 'emergency_stop': return const Color(0xFFFF1744);
      default: return const Color(0xFF00E676);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color themeColor = _getTelemetryColor();
    final String rotationSpeed = _getRotationSpeed();
    final labels = _localizedTwinTexts[widget.currentLang] ?? _localizedTwinTexts['en']!;

    // 🎨 تحديد الألوان ديناميكياً حسب الـ Mode المختار (Jour / Nuit)
    final Color cardBackground = widget.isDarkMode ? const Color(0xFF141E30) : const Color(0xFFF5F7FA);
    final Color borderColor = widget.isDarkMode ? const Color(0xFF233554) : const Color(0xFFE2E8F0);
    final Color titleColor = widget.isDarkMode ? const Color(0xFFAAB6C5) : const Color(0xFF4A5568);
    final Color valueTextColor = widget.isDarkMode ? Colors.white : const Color(0xFF1A202C);
    final Color shadowColor = widget.isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // انتقال سلس عند تبديل الثيم
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // شريط الحالة العلوي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: themeColor, blurRadius: 6)],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    labels['twin_title']!,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Text(
                widget.currentMode == 'emergency_stop' ? '🔴 OFFLINE' : '⚡ ONLINE',
                style: TextStyle(
                  color: widget.currentMode == 'emergency_stop' ? Colors.red : const Color(0xFF00E676),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // منطقة عرض المحرك الـ 3D
          Expanded(
            child: AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                double shakeX = 0.0;
                if (widget.currentMode == 'high_vibration') {
                  shakeX = math.sin(_shakeController.value * math.pi * 4) * 3.5;
                } else if (widget.currentMode == 'overload') {
                  shakeX = math.sin(_shakeController.value * math.pi * 2) * 0.8;
                }

                return Transform.translate(
                  offset: Offset(shakeX, 0),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // هالة التوهج الخلفية (تظهر بوضوح أكبر في الـ Dark Mode)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                themeColor.withOpacity(widget.isDarkMode ? 0.18 : 0.12),
                                themeColor.withOpacity(0.02),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        // مجسم الـ 3D للمحرك
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: ModelViewer(
                            // نمرر الـ isDarkMode في الـ Key أيضاً ليقوم بتحديث الإضاءة فوراً عند التغيير
                            key: ValueKey('${widget.currentMode}_${widget.isDarkMode}'), 
                            src: 'assets/images/motor.glb',
                            alt: 'SEW-EURODRIVE 3D Twin',
                            autoPlay: widget.currentMode != 'emergency_stop',
                            autoRotate: widget.currentMode != 'emergency_stop', 
                            cameraControls: true,
                            rotationPerSecond: rotationSpeed, 
                            backgroundColor: const Color(0x00FFFFFF),
                            
                            // 💡 تعديل الإضاءة والظلال حسب الوضع ليظهر الموديل بوضوح احترافي
                            shadowIntensity: widget.isDarkMode ? 0.5 : 1.0,
                            exposure: widget.isDarkMode ? 1.0 : 1.2, // زيادة الإضاءة في وضع النهار
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // مؤشرات الحالة أسفل المحرك
          const SizedBox(height: 12),
          _buildStatusFooter(labels, titleColor, valueTextColor),
        ],
      ),
    );
  }

  Widget _buildStatusFooter(Map<String, String> labels, Color titleColor, Color valueTextColor) {
    String fluxState = widget.currentMode == 'emergency_stop' ? labels['stagnant']! : labels['synchronous']!;
    String thermalState = widget.currentMode == 'cooling_failure' ? labels['critical']! : labels['nominal']!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMiniIndicator(labels['rotor_speed']!, widget.currentMode == 'emergency_stop' ? '0 RPM' : widget.currentMode == 'overload' ? '2920 RPM' : widget.currentMode == 'bearing_damage' ? '850 RPM' : '1450 RPM', titleColor, valueTextColor),
        _buildMiniIndicator(labels['flux_vector']!, fluxState, titleColor, valueTextColor),
        _buildMiniIndicator(labels['thermal_state']!, thermalState, titleColor, valueTextColor),
      ],
    );
  }

  Widget _buildMiniIndicator(String title, String value, Color titleColor, Color valueTextColor) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor.withOpacity(0.7),
            fontSize: 8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueTextColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }
}