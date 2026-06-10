import 'dart:async';
import 'package:flutter/material.dart';

class SensorsScreen extends StatefulWidget {
  final double temperature;
  final double vibration;
  final double rpm;
  final double current;
  final double voltage;
  final double energy;
  final bool isEsp32Connected;

  const SensorsScreen({
    super.key,
    required this.temperature,
    required this.vibration,
    required this.rpm,
    required this.current,
    required this.voltage,
    required this.energy,
    required this.isEsp32Connected,
  });

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 سحب قيم الألوان ديناميكياً من ثيم التطبيق الحالي
    final Color themeBg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardBg = Theme.of(context).cardColor;
    final Color borderLine = Theme.of(context).dividerColor.withOpacity(0.15);
    final Color textMain = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final Color textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      color: themeBg, // يتغير تلقائياً حسب الوضع المختار
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHardwareGatewayHeader(cardBg, borderLine, textMain, textSecondary),
          const SizedBox(height: 32),
          Text(
            'RAW TELEMETRY NODES',
            style: TextStyle(
              color: textSecondary.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive Grid Columns
                int crossAxisCount = 1;
                if (constraints.maxWidth > 1200) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth > 768) {
                  crossAxisCount = 2;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 24,
                  mainAxisSpacing: 24,
                  childAspectRatio: constraints.maxWidth > 1200 ? 1.6 : 1.4,
                  children: [
                    _buildSensorCard(
                      title: 'MPU6050 - VIBRATION SENSOR',
                      subtitle: 'MEMS 3-Axis Accelerometer',
                      connection: 'I2C Bus -> ESP32 Node',
                      value: widget.vibration.toStringAsFixed(2),
                      unit: 'mm/s',
                      iconData: Icons.vibration_rounded,
                      color: const Color(0xFF00E676), // اللون النيوني الأخضر يظل ثابتاً ليعبر عن الحالة الصناعية للحساس
                      cardBg: cardBg,
                      borderLine: borderLine,
                      textMain: textMain,
                      textSecondary: textSecondary,
                      themeBg: themeBg,
                    ),
                    _buildSensorCard(
                      title: 'THERMOCOUPLE / TEMP NODE',
                      subtitle: 'MLX90614 / PT100 Element',
                      connection: 'I2C Bus / Analog Input',
                      value: widget.temperature.toStringAsFixed(1),
                      unit: '°C',
                      iconData: Icons.thermostat_rounded,
                      color: const Color(0xFFFFB300), // ثابت لتمييز الحرارة
                      cardBg: cardBg,
                      borderLine: borderLine,
                      textMain: textMain,
                      textSecondary: textSecondary,
                      themeBg: themeBg,
                    ),
                    _buildSensorCard(
                      title: 'SCT-013 CURRENT SENSOR',
                      subtitle: 'Non-Invasive CT Sensor',
                      connection: 'ADC Channel 1',
                      value: widget.current.toStringAsFixed(1),
                      unit: 'A',
                      iconData: Icons.bolt_rounded,
                      color: const Color(0xFFE040FB), // ثابت لتمييز التيار
                      cardBg: cardBg,
                      borderLine: borderLine,
                      textMain: textMain,
                      textSecondary: textSecondary,
                      themeBg: themeBg,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareGatewayHeader(Color cardBg, Color borderLine, Color textMain, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: textSecondary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.router_rounded, color: textMain, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESP32 HARDWARE GATEWAY',
                        style: TextStyle(
                          color: textMain,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ethernet UTP Cat 6  //  Static IP: 192.168.1.50',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildConnectionIndicator(),
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    final color = widget.isEsp32Connected ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final text = widget.isEsp32Connected ? 'ONLINE' : 'OFFLINE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.6), blurRadius: 6),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String subtitle,
    required String connection,
    required String value,
    required String unit,
    required IconData iconData,
    required Color color,
    required Color cardBg,
    required Color borderLine,
    required Color textMain,
    required Color textSecondary,
    required Color themeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: themeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderLine),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cable_rounded, color: textSecondary.withOpacity(0.7), size: 14),
                const SizedBox(width: 6),
                Text(
                  connection,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}