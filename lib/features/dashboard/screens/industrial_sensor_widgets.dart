import 'package:flutter/material.dart';
import 'dart:ui';

/// -----------------------------------------------------------------------
/// 1️⃣ البطاقة الذكية الرئيسية للحساسات الصناعية (SCADA Style Sensor Card)
/// -----------------------------------------------------------------------
class ScadaSensorCard extends StatelessWidget {
  final String title;
  final double value;
  final String unit;
  final IconData icon;
  final double minValue;
  final double maxValue;
  final double warningThreshold;
  final double criticalThreshold;

  const ScadaSensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.minValue,
    required this.maxValue,
    required this.warningThreshold,
    required this.criticalThreshold,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 جلب الألوان الأساسية المحددة في ملف الـ main / Theme ديناميكياً
    final Color cardBg = Theme.of(context).cardColor;
    final Color textMain = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final Color textSub = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    // تحديد مستوى الخطورة بناءً على القيمة الحالية لقراءة الحساس
    Color statusColor = const Color(0xFF00E5FF); // النيون العادي المستقر
    String statusText = "NOMINAL";

    if (value >= criticalThreshold) {
      statusColor = const Color(0xFFFF1744); // أحمر تحذيري شديد الخطورة
      statusText = "CRITICAL";
    } else if (value >= warningThreshold) {
      statusColor = const Color(0xFFFFEA00); // أصفر تنبيهي
      statusText = "WARNING";
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // ⚡ هنا السر: استخدام لون خلفية الكرت التابع للثيم النشط مع شفافية ذكية
            color: cardBg.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: statusColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الهيدر: الأيقونة، الاسم، ومؤشر النيون التفاعلي
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: textSub, // ☀️ يصبح رمادي داكن بالنهار ورمادي فاتح بالليل تلقائياً
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  // مؤشر النيون التفاعلي للحالة (Neon Indicator Grid)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: statusColor.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // القيمة الرقمية مع خاصية التحريك السلس عند التحديث التلقائي (Implicit Animation)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: minValue, end: value),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, animatedValue, child) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        unit == 'RPM' || unit == 'V'
                            ? animatedValue.toInt().toString()
                            : animatedValue.toStringAsFixed(1),
                        style: TextStyle(
                          color: textMain, // ☀️ يتحول لأسود/كحلي مريح بالنهار وأبيض ناصع بالليل
                          fontSize: 32,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(
                          color: statusColor.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),

              // شريط القياس الصناعي الخطي (SCADA Progress Bar)
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: ((value - minValue) / (maxValue - minValue)).clamp(
                    0.0,
                    1.0,
                  ),
                  minHeight: 5,
                  // خلفية التراك تتكيف مع مظهر لوحة القياس
                  backgroundColor: textMain.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 8),

              // حدود القياس الصغرى والعظمى بالأسفل
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "MIN: ${minValue.toInt()}",
                    style: TextStyle(color: textSub.withOpacity(0.5), fontSize: 9),
                  ),
                  Text(
                    "MAX: ${maxValue.toInt()}",
                    style: TextStyle(color: textSub.withOpacity(0.5), fontSize: 9),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------------
/// 2️⃣ شبكة العرض المتجاوبة للحساسات الستة (Sensors Grid Layer)
/// -----------------------------------------------------------------------
class IndustrialSensorGrid extends StatelessWidget {
  final double currentTemperature;
  final double currentVibration;
  final double currentRPM;
  final double currentCurrent;
  final double currentVoltage;
  final double currentEnergy;

  const IndustrialSensorGrid({
    super.key,
    required this.currentTemperature,
    required this.currentVibration,
    required this.currentRPM,
    required this.currentCurrent,
    required this.currentVoltage,
    required this.currentEnergy,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // ضبط عدد الأعمدة ديناميكياً لتناسب شاشات الويب والتابلت والـ Desktop
    int crossAxisCount = screenWidth > 1200 ? 3 : (screenWidth > 800 ? 2 : 1);

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), 
      children: [
        // 🌡️ TEMPERATURE SENSOR CARD
        ScadaSensorCard(
          title: "Motor Temperature",
          value: currentTemperature,
          unit: "°C",
          icon: Icons.thermostat_rounded,
          minValue: 0,
          maxValue: 120,
          warningThreshold: 75,
          criticalThreshold: 90,
        ),

        // 🌀 VIBRATION SENSOR CARD
        ScadaSensorCard(
          title: "Vibration Severity",
          value: currentVibration,
          unit: "mm/s",
          icon: Icons.vibration_rounded,
          minValue: 0.0,
          maxValue: 10.0,
          warningThreshold: 4.5,
          criticalThreshold: 7.1,
        ),

        // ⚡ RPM SENSOR CARD
        ScadaSensorCard(
          title: "Motor Speed",
          value: currentRPM,
          unit: "RPM",
          icon: Icons.speed_rounded,
          minValue: 0,
          maxValue: 3000,
          warningThreshold: 1450,
          criticalThreshold: 1520,
        ),

        // 🔌 CURRENT SENSOR CARD
        ScadaSensorCard(
          title: "Current Absorbed",
          value: currentCurrent,
          unit: "A",
          icon: Icons.bolt_rounded,
          minValue: 0.0,
          maxValue: 50.0,
          warningThreshold: 32.0,
          criticalThreshold: 42.0,
        ),

        // 🎛️ VOLTAGE SENSOR CARD
        ScadaSensorCard(
          title: "Line Voltage",
          value: currentVoltage,
          unit: "V",
          icon: Icons.electrical_services_rounded,
          minValue: 0,
          maxValue: 500,
          warningThreshold: 415,
          criticalThreshold: 440,
        ),

        // 🔋 ENERGY CONSUMPTION CARD
        ScadaSensorCard(
          title: "Energy Consumption",
          value: currentEnergy,
          unit: "kWh",
          icon: Icons.analytics_rounded,
          minValue: 0.0,
          maxValue: 5000.0,
          warningThreshold: 4000.0,
          criticalThreshold: 4800.0,
        ),
      ],
    );
  }
}