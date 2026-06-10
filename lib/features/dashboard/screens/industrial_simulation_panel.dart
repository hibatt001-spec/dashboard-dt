import 'package:flutter/material.dart';

class IndustrialSimulationPanel extends StatelessWidget {
  final Function(String mode) onModeChanged;
  final String currentMode;

  const IndustrialSimulationPanel({
    super.key,
    required this.onModeChanged,
    required this.currentMode,
  });

  // 🎨 ألوان حالات المحاكاة الثابتة (تظل ثابتة لتعبر عن الحالة الصناعية بدقة)
  final Color colorNormal = const Color(0xFF00E676);
  final Color colorOverload = const Color(0xFFFFB300);
  final Color colorCooling = const Color(0xFF00C2FF);
  final Color colorVib = const Color(0xFFFF9800);
  final Color colorBearing = const Color(0xFFFF5252);
  final Color colorEStop = const Color(0xFFFF1744);

  @override
  Widget build(BuildContext context) {
    // ☀️ جلب ألوان الواجهة ديناميكياً لتتوافق مع الـ Mode الحالي لقاعدة البيانات أو الثيم
    final Color themeCardBg = Theme.of(context).cardColor;
    final Color themeBorder = Theme.of(context).dividerColor.withOpacity(0.2);
    final Color themeTextSub = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // تحديد خلفية أزرار غير النشطة بناءً على الثيم
    final Color inactiveButtonBg = isDark ? const Color(0xFF0F1624) : Colors.black.withOpacity(0.04);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeCardBg, // يتغير تلقائياً حسب الليل والنهار
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeBorder, width: 1.2),
      ),
      child: Row(
        children: [
          // عنوان صغير جداً للوحة المحاكاة
          Text(
            'SIMULATION INJECTOR:',
            style: TextStyle(
              color: themeTextSub.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),

          // أزرار المحاكاة مصفوفة أفقياً بشكل نحيف جداً
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildMicroButton(
                    'normal',
                    'NORMAL',
                    colorNormal,
                    Icons.check_circle_outline_rounded,
                    inactiveButtonBg,
                    themeTextSub,
                  ),
                  _buildMicroButton(
                    'overload',
                    'OVERLOAD',
                    colorOverload,
                    Icons.bolt_rounded,
                    inactiveButtonBg,
                    themeTextSub,
                  ),
                  _buildMicroButton(
                    'cooling_failure',
                    'COOLING FLT',
                    colorCooling,
                    Icons.ac_unit_rounded,
                    inactiveButtonBg,
                    themeTextSub,
                  ),
                  _buildMicroButton(
                    'high_vibration',
                    'VIBRATION',
                    colorVib,
                    Icons.vibration_rounded,
                    inactiveButtonBg,
                    themeTextSub,
                  ),
                  _buildMicroButton(
                    'bearing_damage',
                    'BEARING FLT',
                    colorBearing,
                    Icons.brightness_7_rounded,
                    inactiveButtonBg,
                    themeTextSub,
                  ),
                  const SizedBox(width: 8),
                  _buildMicroEStop(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // زر صغير ونحيف للأوضاع العادية والأعطال يتكيف مع الثيمات
  Widget _buildMicroButton(
    String id,
    String label,
    Color color,
    IconData icon,
    Color inactiveBg,
    Color textSub,
  ) {
    bool isActive = currentMode == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: InkWell(
        onTap: () => onModeChanged(id),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.15) : inactiveBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? color : textSub.withOpacity(0.15),
              width: isActive ? 1.5 : 1.0,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? color : textSub.withOpacity(0.5),
                size: 12,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? (isActive && color == colorOverload ? Colors.orange[800] : color) : textSub,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // زر التوقف الطارئ بحجم متناسق ونحيف متكيف بصرياً
  Widget _buildMicroEStop(bool isDark) {
    bool isEStop = currentMode == 'emergency_stop';
    
    // تعديل لون الخلفية في وضع النهار لتكون مريحة وليست شديدة الظلمة
    Color eStopInactiveBg = isDark ? const Color(0xFF320A14) : const Color(0xFFFFEBEE);

    return InkWell(
      onTap: () => onModeChanged('emergency_stop'),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEStop ? colorEStop : eStopInactiveBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorEStop, width: 1.2),
          boxShadow: isEStop
              ? [BoxShadow(color: colorEStop.withOpacity(0.5), blurRadius: 8)]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.gpp_bad_rounded,
              color: isEStop ? Colors.white : colorEStop,
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              'E-STOP',
              style: TextStyle(
                color: isEStop ? Colors.white : colorEStop,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}