/*import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 استيراد مكتبة Firebase Auth لتسجيل الخروج
import '../../../main.dart';
import 'vibration_details_window.dart';

class MotorDashboardScreen extends StatefulWidget {
  const MotorDashboardScreen({super.key});

  @override
  State<MotorDashboardScreen> createState() => _MotorDashboardScreenState();
}

class _MotorDashboardScreenState extends State<MotorDashboardScreen>
    with TickerProviderStateMixin {
  String? selectedMetric;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  double valeurVibration = 2.4;
  double valeurCourant = 13.7;
  double valeurTemperature = 68.5;

  final Map<String, Map<String, String>> localizedTexts = {
    'ar': {
      'title': 'لوحة تحكم المحرك',
      'realtime_params': 'المعطيات في الوقت الحقيقي',
      'motor_operating': 'في طور التشغيل',
      'motor_title': 'محرك كهربائي',
      'vibration': 'الاهتزاز',
      'current': 'التيار',
      'temperature': 'الحرارة',
      'v_unit': 'ملم/ث',
      'c_unit': 'أمبير',
      't_unit': '°م',
      'status_nominal': 'الوضع العام: اسمي — كل المؤشرات عادية.',
      'normal': 'طبيعي',
      'alert': 'تنبيه',
      'high': 'مرتفع',
      'hot': 'ساخن',
    },
    'fr': {
      'title': 'Tableau de Bord Moteur',
      'realtime_params': 'PARAMÈTRES EN TEMPS RÉEL',
      'motor_operating': 'En fonctionnement',
      'motor_title': 'MOTEUR ÉLECTRIQUE',
      'vibration': 'Vibration',
      'current': 'Courant',
      'temperature': 'Température',
      'v_unit': 'mm/s',
      'c_unit': 'A',
      't_unit': '°C',
      'status_nominal':
          'Statut Global : Nominal — Tous les paramètres sont normaux.',
      'normal': 'NORMAL',
      'alert': 'ALERTE',
      'high': 'ÉLEVÉ',
      'hot': 'CHAUD',
    },
    'en': {
      'title': 'Motor Dashboard',
      'realtime_params': 'REAL-TIME PARAMETERS',
      'motor_operating': 'Operating',
      'motor_title': 'ELECTRIC MOTOR',
      'vibration': 'Vibration',
      'current': 'Current',
      'temperature': 'Temperature',
      'v_unit': 'mm/s',
      'c_unit': 'A',
      't_unit': '°C',
      'status_nominal': 'Global Status: Nominal — All parameters are normal.',
      'normal': 'NORMAL',
      'alert': 'ALERT',
      'high': 'HIGH',
      'hot': 'HOT',
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, child) {
        bool isRtl = currentLang == 'ar';
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final primaryCyan = Theme.of(context).primaryColor;
        final cardColor = Theme.of(context).colorScheme.surface;
        final titleColor = isDark
            ? const Color(0xFFE0F7FA)
            : const Color(0xFF0F172A);
        final labelColor = isDark
            ? Colors.white.withOpacity(0.45)
            : const Color(0xFF334155);

        String _t(String key) {
          return localizedTexts[currentLang]?[key] ?? key;
        }

        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: isDark ? const Color(0xFF0D1220) : Colors.white,
              elevation: isDark ? 0 : 2,
              shadowColor: Colors.black12,
              title: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primaryCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _t('title'),
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              actions: [
                // ☀️/🌙 1. أيقونة وضع النهار والليل
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, currentMode, child) {
                    return IconButton(
                      icon: Icon(
                        currentMode == ThemeMode.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: primaryCyan,
                      ),
                      onPressed: () {
                        themeNotifier.value = currentMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark;
                      },
                    );
                  },
                ),

                // 🌐 2. أيقونة اختيار اللغة (العربية، الفرنسية، الإنجليزية)
                PopupMenuButton<String>(
                  icon: Icon(Icons.language, color: primaryCyan, size: 22),
                  tooltip: 'Changer la langue',
                  color: isDark ? const Color(0xFF141B30) : Colors.white,
                  onSelected: (String langCode) {
                    languageNotifier.value = langCode;
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'ar',
                      child: Text(
                        'العربية',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'fr',
                      child: Text(
                        'Français',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'en',
                      child: Text(
                        'English',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),

                // 🚪 3. أيقونة تسجيل الخروج (Logout)
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  onPressed: () async {
                    // إظهار نافذة تأكيد تسجيل الخروج
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: isDark
                              ? const Color(0xFF141B30)
                              : Colors.white,
                          title: Text(
                            currentLang == 'ar'
                                ? 'تسجيل الخروج'
                                : (currentLang == 'fr'
                                      ? 'Déconnexion'
                                      : 'Logout'),
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          content: Text(
                            currentLang == 'ar'
                                ? 'هل أنت متأكد من رغبتك في تسجيل الخروج؟'
                                : (currentLang == 'fr'
                                      ? 'Êtes-vous sûr de vouloir vous déconnecter ?'
                                      : 'Are you sure you want to logout?'),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                currentLang == 'ar'
                                    ? 'إلغاء'
                                    : (currentLang == 'fr'
                                          ? 'Annuler'
                                          : 'Cancel'),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            TextButton(
                              child: Text(
                                currentLang == 'ar'
                                    ? 'خروج'
                                    : (currentLang == 'fr'
                                          ? 'Quitter'
                                          : 'Logout'),
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await FirebaseAuth.instance
                                    .signOut(); // 👈 قطع الاتصال والعودة لصفحة الـ Login تلقائياً
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('realtime_params'),
                    style: TextStyle(
                      color: primaryCyan,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 135,
                          child: Column(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            VibrationDetailsWindow(
                                              title: "Vibration Analysis",
                                              currentValue: valeurVibration,
                                              currentLang: currentLang,
                                            ),
                                      ),
                                    );
                                  },
                                  child: _buildMetricCardVertical(
                                    icon: Icons.vibration,
                                    label: _t('vibration'),
                                    value: valeurVibration,
                                    unit: _t('v_unit'),
                                    color: const Color(0xFF7C4DFF),
                                    iconBg: isDark
                                        ? const Color(0xFF1A1040)
                                        : const Color(0xFFF3E8FF),
                                    cardColor: cardColor,
                                    labelColor: labelColor,
                                    status: _getVibrationStatus(
                                      valeurVibration,
                                    ),
                                    t: _t,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildMetricCardVertical(
                                  icon: Icons.bolt,
                                  label: _t('current'),
                                  value: valeurCourant,
                                  unit: _t('c_unit'),
                                  color: isDark
                                      ? const Color(0xFF00E5FF)
                                      : const Color(0xFF00A3B4),
                                  iconBg: isDark
                                      ? const Color(0xFF001D26)
                                      : const Color(0xFFE0F7FA),
                                  cardColor: cardColor,
                                  labelColor: labelColor,
                                  status: _getCurrentStatus(valeurCourant),
                                  t: _t,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildMetricCardVertical(
                                  icon: Icons.thermostat,
                                  label: _t('temperature'),
                                  value: valeurTemperature,
                                  unit: _t('t_unit'),
                                  color: const Color(0xFFFF6D00),
                                  iconBg: isDark
                                      ? const Color(0xFF261200)
                                      : const Color(0xFFFFEFFF),
                                  cardColor: cardColor,
                                  labelColor: labelColor,
                                  status: _getTempStatus(valeurTemperature),
                                  t: _t,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildMotorDisplay(
                            isDark,
                            cardColor,
                            primaryCyan,
                            _t,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildStatusBanner(_t),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // الدوال المساعدة تمرر دالة الترجمة [_t] بشكل صحيح
  Widget _buildMetricCardVertical({
    required IconData icon,
    required String label,
    required double value,
    required String unit,
    required Color color,
    required Color iconBg,
    required Color cardColor,
    required Color labelColor,
    required String status,
    required String Function(String) t,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Row(
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t(status.toLowerCase()),
              style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotorDisplay(
    bool isDark,
    Color cardColor,
    Color primaryCyan,
    String Function(String) t,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cardColor,
        border: Border.all(
          color: isDark ? const Color(0xFF1E2A45) : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F1928) : Colors.grey[100],
                  border: Border.all(
                    color: primaryCyan.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.settings, color: primaryCyan, size: 60),
              ),
              const SizedBox(height: 16),
              Text(
                t('motor_title'),
                style: TextStyle(
                  color: primaryCyan,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00E676),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t('motor_operating'),
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniStat('RPM', '1450', isDark),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? const Color(0xFF1E2A45) : Colors.grey[300]!,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildMiniStat('kW', '7.5', isDark),
                  Container(
                    width: 1,
                    height: 28,
                    color: isDark ? const Color(0xFF1E2A45) : Colors.grey[300]!,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _buildMiniStat('cos φ', '0.87', isDark),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? const Color(0xFFE0F7FA) : const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner(String Function(String) t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF00E676),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t('status_nominal'),
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getVibrationStatus(double v) => v < 3.0 ? 'NORMAL' : 'ALERT';
  String _getCurrentStatus(double v) => v < 15.0 ? 'NORMAL' : 'HIGH';
  String _getTempStatus(double v) => v < 80.0 ? 'NORMAL' : 'HOT';

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NORMAL':
        return const Color(0xFF00E676);
      case 'ALERT':
      case 'HOT':
        return const Color(0xFFFF6D00);
      case 'HIGH':
        return const Color(0xFFFFD600);
      default:
        return const Color(0xFF00E5FF);
    }
  }
}
*/