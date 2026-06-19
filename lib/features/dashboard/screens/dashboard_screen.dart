//import 'package:digital_twin_control_center/features/auth/screens/loading_screen.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../../../main.dart';
import 'industrial_charts_screen.dart';
import 'industrial_alerts_panel.dart';
import 'predictive_maintenance_ai_screen.dart';
import 'app_translations.dart';
import 'sensors_screen.dart';
import 'historique.dart';
import 'dart:convert'; // مهم داً لفك شفرة الـ JSON
import '../../../core/models/kpi_history.dart';
import '../../../core/services/history_service.dart';
import 'mqtt_service.dart';
import 'package:digital_twin_control_center/features/auth/screens/login_screen.dart';

// ═══════════════════════════════════════════════════════════════
//  CyberSparklinePainter — top-level class
// ═══════════════════════════════════════════════════════════════
class CyberSparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  CyberSparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final step = size.width / (data.length - 1);
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final y = size.height - (data[i].clamp(0.0, 1.0) * size.height);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CyberSparklinePainter old) =>
      old.data != data || 
      old.color != color;
}
//mqtt 

// ═══════════════════════════════════════════════════════════════
//  DashboardScreen
// ═══════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _currentSidePage = 'Dashboard';
  bool _sidebarExpanded = false;
  bool isSimulinkConnected = false;
  bool isMqttConnected = false;
  
  // بيانات حية للتوأم الرقمي
  double currentTemperature = 28.5;
  double currentVibration = 1.2;
  double currentRPM = 1440.0;
  double currentCurrent = 8.5;
  double currentVoltage = 220.0;
  double currentEnergy = 1250.5;
  bool isEsp32Connected = true;
  double vibrationValue = 0.0;
  double temperatureValue = 0.0;
  double currentValue = 0.0;

  
  late MqttService _mqttService;

  // History tracking variables
  DateTime? _lastSavedTime;
  double _lastSavedTemp = 0.0;
  double _lastSavedVib = 0.0;
  double _lastSavedCurr = 0.0;
  double _lastSavedOee = 0.0;
  double _lastSavedHealth = 0.0;
  String _lastSavedStatus = 'Normal';

  List<FlSpot> tempSpots = [];
  List<FlSpot> vibSpots = [];
  List<FlSpot> currentSpots = [];

  // قوائم لاستقبال ورسم منحنيات الـ FFT الترددية
  List<FlSpot> vibFftSpots = [];
  List<FlSpot> currentFftSpots = [];
  // 📊 قوائم الاهتزاز الديناميكية
  List<FlSpot> vibrationTimeSpots = []; // للمنحنى الزمني السفلي
  List<FlSpot> vibrationFftSpots = [];  // لمنحنى الـ FFT العلوي

  // متغيرات لحساب القمم (Peaks) ديناميكياً لتحديث الجدول الجانبي
  double peak1Freq = 45.0, peak1Val = 0.0;
  double peak2Freq = 90.0, peak2Val = 0.0;
  double peak3Freq = 135.0, peak3Val = 0.0;


  int timeCounter = 0;
  DateTime? startTime;

  // 🎯 توليد طيف FFT واقعي محلياً بناءً على شدة الاهتزاز الحقيقية القادمة من سيمولينك
  // يبني قمم عند 45Hz (BPF) و90Hz (2×BPF) و135Hz (3×BPF) تتحرك حسب vib
 List<FlSpot> _generateSimulatedFft(double vib) {
  final List<FlSpot> spots = [];
  // رفع ليميت الـ severity ليتناسب مع أبعاد الأنيميشن في الشاشة
  final double severity = vib.clamp(0.0, 10.0) * 12.0; 

  // ضوضاء أساسية منخفضة عبر كل الترددات (مرفوعة لتظهر فوق الصفر)
  double baseline(double f) => 0.8 + 0.3 * math.sin(f * 0.3);

  // دالة قمة غاوسية حول تردد معين
  double peak(double f, double center, double amplitude, double width) {
    final double d = (f - center) / width;
    return amplitude * math.exp(-d * d);
  }

  // الحساب من 0 إلى 500 هرتز ليتطابق تماماً مع الـ maxX للتشارت
  for (double f = 0; f <= 500; f += 5) {
    double y = baseline(f);
    
    // القمم الميكانيكية موزعة بذكاء ومضروبة في الـ severity لتتفاعل حياً مع المحرك
    y += peak(f, 45, severity * 0.22, 10.0);   // BPF (Ball Pass Frequency)
    y += peak(f, 90, severity * 0.10, 12.0);   // 2×BPF
    y += peak(f, 135, severity * 0.04, 12.0);  // 3×BPF
    y += peak(f, 250, severity * 0.18, 15.0);  // قمة إضافية عند الترددات المتوسطة 
    y += peak(f, 11.2, severity * 0.26, 6.0);  // اهتزاز عام منخفض التردد

    // الـ clamp الآن مضبوط على 28.0 ليتماشى مع الـ maxY: 30 الجديد للتشارت
    spots.add(FlSpot(f, y.clamp(0.0, 2.3)));
  }
  return spots;
}

  // Helper method for history saving
  void _checkAndSaveHistory() {
    // 1. Calculate realistic KPIs
    double healthIndex = (100 - (vibrationValue * 10) - ((temperatureValue - 30) * 1.5)).clamp(0, 100).toDouble();
    double oee = healthIndex * 0.9;
    
    String alertStatus = 'Normal';
    if (healthIndex < 50) {
      alertStatus = 'Critical';
    } else if (healthIndex < 75) {
      alertStatus = 'Warning';
    }

    // Fixed dummy values for the rest to simulate full model
    double rul = healthIndex * 50; 
    double availability = 96.5;
    double efficiency = 91.2;
    double mtbf = 142.0;
    double mttr = 1.8;
    double maintenanceCost = 420.0;

    final now = DateTime.now();
    bool shouldSave = false;

    if (_lastSavedTime == null) {
      shouldSave = true;
    } else {
      final secondsSinceLastSave = now.difference(_lastSavedTime!).inSeconds;
      
      if (secondsSinceLastSave >= 5) {
        shouldSave = true;
      } else if (alertStatus != _lastSavedStatus) {
        shouldSave = true;
      } else if ((healthIndex - _lastSavedHealth).abs() > 2) {
        shouldSave = true;
      } else if ((oee - _lastSavedOee).abs() > 2) {
        shouldSave = true;
      } else if ((temperatureValue - _lastSavedTemp).abs() > 2) {
        shouldSave = true;
      } else if ((currentValue - _lastSavedCurr).abs() > 2) {
        shouldSave = true;
      } else if ((vibrationValue - _lastSavedVib).abs() > 0.1) {
        shouldSave = true;
      }
    }

    if (shouldSave) {
      HistoryService.saveSnapshot(
        KpiHistory(
          timestamp: now,
          temperature: temperatureValue,
          vibration: vibrationValue,
          current: currentValue,
          healthIndex: healthIndex,
          rul: rul,
          oee: oee,
          availability: availability,
          efficiency: efficiency,
          mtbf: mtbf,
          mttr: mttr,
          maintenanceCost: maintenanceCost,
          alertStatus: alertStatus,
          mode: currentSimulationModeNotifier.value,
        )
      );

      _lastSavedTime = now;
      _lastSavedTemp = temperatureValue;
      _lastSavedVib = vibrationValue;
      _lastSavedCurr = currentValue;
      _lastSavedOee = oee;
      _lastSavedHealth = healthIndex;
      _lastSavedStatus = alertStatus;
    }
  }
  // ألوان ثابتة
  final Color neonCyan = const Color(0xFF00C2FF);
  final Color accentPurple = const Color(0xFF7B61FF);
  final Color successGreen = const Color(0xFF00E676);
  final Color dangerRed = const Color(0xFFFF5252);
  
  String _t(String key, String lang) => AppTranslations.t(key, lang);

  Color _getTempGlowColor(double temp) {
    if (temp < 40) return const Color(0xFF0077FF);
    if (temp < 70) return const Color(0xFFFF9800);
    return const Color(0xFFFF3D00);
  }

  // Handle user logout
  void _handleLogout(String Function(String) t, ThemeMode currentMode, Color mainText) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed')),
      );
    }
  }

  // ════════════════════════════════════════════════════════════
  //  BUILD — Responsive & Safe Layout
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, _) {
        final bool isRtl = currentLang == 'ar';
        String t(String key) => _t(key, currentLang);

        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentMode, _) {
            final bool isDark = currentMode == ThemeMode.dark;

            final Color currentBg = isDark
                ? const Color(0xFF0B1020)
                : const Color(0xFFF4F7FB);
            final Color sidebarBg = isDark
                ? const Color(0xFF121A2F)
                : Colors.white;
            final Color cardBg = isDark
                ? const Color(0xFF182338)
                : Colors.white;
            final Color borderBg = isDark
                ? const Color(0xFF2A3A5A)
                : const Color(0xFFDCE3F0);
            final Color mainText = isDark
                ? const Color(0xFFF5F7FA)
                : const Color(0xFF1B263B);
            final Color subText = isDark
                ? const Color(0xFFAAB6C5)
                : const Color(0xFF5C677D);
            final Color accentIcon = isDark
                ? const Color(0xFF00C2FF)
                : const Color(0xFF0077FF);

            return Directionality(
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: Scaffold(
                backgroundColor: currentBg,
                body: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── القائمة الجانبية المستقرة هندسياً
                      Material(
                        color: Colors.transparent,
                        child: _buildSidebar(
                          t,
                          sidebarBg,
                          borderBg,
                          mainText,
                          subText,
                          accentIcon,
                        ),
                      ),
                      // ── مساحة العرض الرئيسية المتمددة تلقائياً
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildTopStatusBar(
                              t,
                              borderBg,
                              mainText,
                              currentMode,
                              accentIcon,
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  key: ValueKey<String>(_currentSidePage),
                                  child: _buildPageContent(
                                    _currentSidePage,
                                    t,
                                    currentLang,
                                    cardBg,
                                    borderBg,
                                    mainText,
                                    subText,
                                    accentIcon,
                                    isDark,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════
  //  1. SIDEBAR
  // ════════════════════════════════════════════════════════════
  Widget _buildSidebar(
    String Function(String) t,
    Color bg,
    Color borderColor,
    Color mainText,
    Color subText,
    Color accentIcon,
  ) {
    // 📥 تم إضافة 'History' هنا بالترتيب بين Alerts و Sensors
    final menuItems = [
      {'id': 'Dashboard', 'icon': Icons.grid_view_rounded},
      {'id': 'Analytics', 'icon': Icons.analytics_outlined},
      {'id': 'Alerts', 'icon': Icons.warning_amber_rounded},
      {
        'id': 'History',
        'icon': Icons.history_toggle_off_rounded,
      }, // 👈 الأرشيف التاريخي
      {'id': 'Sensors', 'icon': Icons.sensors_rounded},
      {'id': 'Settings', 'icon': Icons.settings_outlined},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _sidebarExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          right: languageNotifier.value != 'ar'
              ? BorderSide(color: borderColor, width: 1.5)
              : BorderSide.none,
          left: languageNotifier.value == 'ar'
              ? BorderSide(color: borderColor, width: 1.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: GestureDetector(
              onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: _sidebarExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Icon(Icons.blur_on, color: accentIcon, size: 30),
                  if (_sidebarExpanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DIGITAL TWIN CENTER',
                        style: TextStyle(
                          color: mainText,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Divider(color: borderColor, height: 1, thickness: 1.2),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final pageId = menuItems[index]['id'] as String;
                final icon = menuItems[index]['icon'] as IconData;
                final selected = _currentSidePage == pageId;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: selected
                          ? accentIcon.withOpacity(0.12)
                          : Colors.transparent,
                      border: Border.all(
                        color: selected ? accentIcon : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      onTap: () => setState(() => _currentSidePage = pageId),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: _sidebarExpanded ? 16 : 0,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: _sidebarExpanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: selected
                                  ? accentIcon
                                  : subText.withOpacity(0.8),
                              size: 20,
                            ),
                            if (_sidebarExpanded) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  t(pageId),
                                  style: TextStyle(
                                    color: mainText,
                                    fontWeight: selected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

 // ════════════════════════════════════════════════════════════
  //  2. TOP STATUS BAR (WITH LIVE MQTT & SIMULINK INDICATORS)
  // ════════════════════════════════════════════════════════════
  Widget _buildTopStatusBar(
    String Function(String) t,
    Color borderColor,
    Color mainText,
    ThemeMode currentMode,
    Color accentIcon,
  ) {
    final bool isDark = currentMode == ThemeMode.dark;
    
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121A2F) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // عنوان الصفحة الحالية
          Text(
            t(_currentSidePage).toUpperCase(),
            style: TextStyle(
              color: mainText,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          
          // الأزرار والمؤشرات اليمنى
          Row(
            children: [
              // 🌐 1. مؤشر حالة سيرفر الـ MQTT المتغير ديناميكياً
              _statusDot(
                isMqttConnected ? t('mqtt_on') : t('mqtt_off'),
                isMqttConnected ? successGreen : Colors.red,
              ),

              const SizedBox(width: 8),

              // 🟢🔴 2. مؤشر حالة الـ Simulink المتغير ديناميكياً
              _statusDot(
                isSimulinkConnected ? t('simulink_on') : t('simulink_off'), 
                isSimulinkConnected ? successGreen : Colors.red, // أخضر عند العمل، أحمر عند التوقف
              ),
              
              const SizedBox(width: 8),
              
              // زر تبديل الثيم المظلم/المضيء
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: accentIcon,
                  size: 22,
                ),
                onPressed: () => themeNotifier.value = isDark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
              
              // قائمة تبديل لغات واجهة التحكم (تونسي، فرنسي، إنجليزي)
              PopupMenuButton<String>(
                icon: Icon(Icons.language, color: accentIcon, size: 22),
                color: isDark ? const Color(0xFF182338) : Colors.white,
                onSelected: (code) => languageNotifier.value = code,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'ar',
                    child: Text(
                      '🇹🇳 العربية',
                      style: TextStyle(color: mainText, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'fr',
                    child: Text(
                      '🇫🇷 Français',
                      style: TextStyle(color: mainText, fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'en',
                    child: Text(
                      '🇬🇧 English',
                      style: TextStyle(color: mainText, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              
              // زر الخروج الآمن (Logout)
              IconButton(
                icon: const Icon(
                  Icons.logout,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: () => _handleLogout(t, currentMode, mainText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  3. PAGE ROUTER
  // ════════════════════════════════════════════════════════════
  Widget _buildPageContent(
    String pageName,
    String Function(String) t,
    String currentLang,
    Color cardBg,
    Color borderBg,
    Color mainText,
    Color subText,
    Color accentIcon,
    bool isDark,
  ) {
    switch (pageName) {
      case 'Dashboard':
        return _buildDashboardPage(
          t,
          currentLang,
          cardBg,
          borderBg,
          mainText,
          subText,
          accentIcon,
          isDark,
        );
      case 'Analytics':
        return IndustrialChartsScreen(
          key: const ValueKey('Charts'),
          isDarkMode: isDark,
          vibrationFftSpots: vibFftSpots,   // 👈 التعديل: مرري vibFftSpots بدلاً من vibrationFftSpots
          vibrationTimeSpots: vibSpots,
        );
      case 'Sensors':
        return SensorsScreen(
          key: const ValueKey('Sensors'),
          temperature: currentTemperature,
          vibration: currentVibration,
          rpm: currentRPM,
          current: currentCurrent,
          voltage: currentVoltage,
          energy: currentEnergy,
          isEsp32Connected: isEsp32Connected,
        );
      case 'Alerts':
        return const IndustrialAlertsPanel(key: ValueKey('Alerts'));
      case 'History': 
        return HistoryScreen(
          isDarkMode: Theme.of(context).brightness == Brightness.dark,
        );
      case 'Settings':
        return const PredictiveMaintenanceScreen(key: ValueKey('Predictive'));
      default:
        return Center(
          key: ValueKey(pageName),
          child: Text(
            '${t(pageName)} Content View',
            style: TextStyle(
              color: mainText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }

 // ════════════════════════════════════════════════════════════
  //  4. IMMERSIVE DIGITAL TWIN DASHBOARD (THE MASTERPIECE)
  // ════════════════════════════════════════════════════════════
  Widget _buildDashboardPage(
    String Function(String) t,
    String currentLang,
    Color cardBg,
    Color borderBg,
    Color mainText,
    Color subText,
    Color accentIcon,
    bool isDark, // 👈 أضفنا المتغير هنا لتمريره للأسفل
  ) {
    return SingleChildScrollView(
      key: const ValueKey('Dashboard'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 🪐 المحرك الكبير في الصدارة يتكيف الآن مع الوضعين تلقائياً
          _buildTwinVisualizer(
            temperature: currentTemperature,
            vibration: currentVibration,
            rpm: currentRPM,
            current: currentCurrent,
            accentIcon: accentIcon,
            currentLang: currentLang,
            t: t,
            isDark: isDark, // 👈 تم التمرير هنا بنجاح
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  //  DIGITAL TWIN VISUALIZER (FULLWIDTH EXPANDED VERSION)
  // ════════════════════════════════════════════════════════════
  Widget _buildTwinVisualizer({
    required double temperature,
    required double vibration,
    required double rpm,
    required double current,
    required Color accentIcon,
    required String currentLang,
    required String Function(String) t,
    required bool isDark, // 👈 استلام المتغير الذكي هنا لضبط الجماليات
  }) {
    final Color glowColor = _getTempGlowColor(temperature);
    final double calculatedSpeed = (10.0 + vibration * 8).clamp(10.0, 150.0);

    // 🎨 ضبط الألوان ديناميكياً حسب وضع الليل والنهار
    final Color containerBg = isDark 
        ? const Color(0xFF0C1322)  // خلفية داكنة السيبرانية لوضع الليل
        : const Color(0xFFF8FAFC); // خلفية فاتحة جداً ونظيفة لوضع النهار

    final Color containerBorder = isDark 
        ? const Color(0xFF1E2D4A)  // حدود داكنة متناسقة
        : const Color(0xFFE2E8F0); // حدود فاتحة ناعمة (Slate-200)

    final Color titleColor = isDark 
        ? Colors.white.withOpacity(0.9) 
        : const Color(0xFF0F172A); // نص عنوان داكن جداً في النهار لسهولة القراءة

    return LayoutBuilder(
      builder: (context, constraints) {
        // نثبتوا هل الشاشة ضيقة (Responsive Check)
        final bool isNarrow = constraints.maxWidth < 750;

        return Container(
          height: isNarrow ? 720 : 680, 
          width: double.infinity,
          decoration: BoxDecoration(
            color: containerBg, // 👈 الخلفية المتغيرة ديناميكياً
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: containerBorder, width: 1.5), // 👈 الحدود المتغيرة
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(isDark ? 0.08 : 0.04), // توهج ناعم يقل في النهار
                blurRadius: 40,
                spreadRadius: 2,
              ),
              if (!isDark) // إضافة ظل ناعم إضافي في وضع النهار ليعطي بعداً هندسياً للكارت
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cyber Grid Effect (تأثير شبكة الرسوم البيانية المستقبلية)
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.03 : 0.05, // تفتيح الشبكة قليلاً في النهار لتظهر بوضوح ناعم
                  child: GridPaper(
                    color: accentIcon,
                    divisions: 2,
                    subdivisions: 1,
                    interval: 40,
                  ),
                ),
              ),

              // Title Bar Info (شريط معلومات الموديل والحالة العلوية)
              Positioned(
                top: 20,
                left: 24,
                right: 24,
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: glowColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t('motor_model'),
                        style: TextStyle(
                          color: titleColor, // 👈 يتغير حسب وضع الشاشة
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildMotorStatusHeader(
                      context: context,
                      temperature: temperature,
                      vibration: vibration,
                      currentLang: currentLang,
                      t: t,
                    ),
                  ],
                ),
              ),

              // 🪐 مركز الشاشة: مجسم الـ 3D لتوأم المحرك الرقمي
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 60,
                    horizontal: isNarrow ? 30 : 180, 
                  ),
                  child: ModelViewer(
                    src: 'assets/images/motor.glb',
                    alt: 'Industrial Motor 3D Digital Twin',
                    autoPlay: true,
                    autoRotate: false,
                    cameraControls: true,
                    rotationPerSecond: '${calculatedSpeed.toStringAsFixed(0)}deg',
                    backgroundColor: const Color(0x00FFFFFF), // شفاف تماماً ليعكس لون الخلفية المتغير
                  ),
                ),
              ),

              // 🛰️ توزيع الكروت والبيانات بطريقة ذكية ومتجاوبة حسب العرض المتاح
              if (!isNarrow) ...[
                // ── [الوضع العريض: كروت عائمة بكامل بياناتها المتقدمة والرسومات المصغرة]
                Positioned(
                  top: 80,
                  left: 24,
                  child: _buildImmersiveChartBadge(
                    t('motor_temperature'),
                    '${temperature.toStringAsFixed(1)} ${t('degree_label')}',
                    glowColor,
                    [0.3, 0.4, 0.35, 0.55, 0.45, 0.65, (temperature / 100).clamp(0.0, 1.0)],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 24,
                  child: _buildImmersiveChartBadge(
                    t('vibration_severity'),
                    '${vibration.toStringAsFixed(2)} ${t('mm_s_label')}',
                    const Color(0xFF00E676),
                    [0.4, 0.5, 0.3, 0.7, 0.2, 0.6, (vibration / 10).clamp(0.0, 1.0)],
                  ),
                ),
                Positioned(
                  top: 80,
                  right: 24,
                  child: _buildImmersiveChartBadge(
                    t('motor_speed'),
                    '${rpm.toInt()} ${t('rpm_label')}',
                    const Color(0xFFFFB300),
                    [0.78, 0.82, 0.80, 0.85, 0.81, 0.83, (rpm / 3000).clamp(0.0, 1.0)],
                  ),
                ),
                Positioned(
                  bottom: 40,
                  right: 24,
                  child: _buildImmersiveChartBadge(
                    t('current_absorbed'),
                    '${current.toStringAsFixed(1)} ${t('amp_label')}',
                    const Color(0xFFE040FB),
                    [0.25, 0.45, 0.35, 0.50, 0.40, 0.58, (current / 25).clamp(0.0, 1.0)],
                  ),
                ),
              ] else ...[
                // ── [الوضع الضيق: شريط سفلي مدمج لعرض القيم اللحظية بوضوح تام وثبات هندسي]
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: Text(
                          '${temperature.toStringAsFixed(1)}${t('degree_label')}',
                          style: TextStyle(
                            color: glowColor,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${vibration.toStringAsFixed(1)} ${t('mm_s_label')}',
                          style: const TextStyle(
                            color: Color(0xFF00E676),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${rpm.toInt()} ${t('rpm_label')}',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${current.toStringAsFixed(1)} ${t('amp_label')}',
                          style: const TextStyle(
                            color: Color(0xFFE040FB),
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

Widget _buildMotorStatusHeader({
  required BuildContext context, // 👈 أضفنا الـ BuildContext هنا لكي نتمكن من قراءة الثيم الحالي
  required double temperature,
  required double vibration,
  required String currentLang,
  required String Function(String) t,
}) {
  Color statusColor;
  String statusText;
  String subText;

  // فحص إذا كان التطبيق حالياً في الوضع المظلم (Dark Mode)
  final isDark = Theme.of(context).brightness == Brightness.dark;

  // 1️⃣ تحديد ألوان الحالات حسب قيم المستشعرات
  if (temperature > 80.0 || vibration > 7.1) {
    statusColor = const Color(0xFFFF5252); // أحمر - خطر
    statusText = t('danger_critique');
    subText = t('shutdown_recommendation');
  } else if (temperature >= 65.0 || vibration >= 4.5) {
    statusColor = const Color(0xFFFFB300); // برتقالي - صيانة
    statusText = t('alerte_maintenance');
    subText = t('inspection_required');
  } else {
    statusColor = isDark ? const Color(0xFF00E676) : const Color(0xFF00C853); // أخضر ذكي يتكيف مع الخلفية
    statusText = t('system_normal');
    subText = t('system_normal_sub'); // 👈 قمت بتعديل الـ key هنا ليكون منطقياً وحسب حالة العمل الطبيعية
  }

  // 2️⃣ تحديد لون خلفية الـ الكارت ولون النص الفرعي حسب وضع النهار والليل
  final containerBgColor = isDark 
      ? const Color(0xFF1E293B).withOpacity(0.6) // رمادي مزرق داكن ومناسب لـ Dark mode
      : Colors.grey[100]; // رمادي فاتح جداً ونظيف لـ Light mode

  final subTextColor = isDark 
      ? const Color(0xAA8A99AD) // نص رمادي فاتح للـ Dark
      : const Color(0xFF64748B); // نص رمادي غامق وواضح للـ Light

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: containerBgColor, // 👈 الخلفية المتغيرة
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: statusColor.withOpacity(isDark ? 0.15 : 0.08), // تقليل التوهج في النهار لكي لا يفسد التصميم
          blurRadius: 16,
          spreadRadius: 2,
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // نقطة الحالة المضيئة (Status LED Indicator)
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: statusColor,
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 👈 جعلتها Start لتبدأ النصوص متناسقة بجانب نقطة الحالة
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subText,
              style: TextStyle(
                color: subTextColor, // 👈 النص الفرعي المتغير
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
  // ════════════════════════════════════════════════════════════
  //  REUSABLE WIDGETS
  // ════════════════════════════════════════════════════════════
  Widget _buildImmersiveChartBadge(
    String title,
    String value,
    Color color,
    List<double> dataHistory,
  ) {
    // 🌗 فحص المود الحالي داخل الـ Badge
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // تحديد لون الخلفية والحدود حسب وضع النهار أو الليل
    final Color badgeBg = isDark ? const Color(0xFF0B1529).withOpacity(0.85) : const Color(0xFFF8FAFC);
    final Color badgeBorder = isDark ? color.withOpacity(0.4) : color.withOpacity(0.25);
    final Color labelColor = isDark ? const Color(0xAA8A99AD) : const Color(0xFF64748B);

    var children = [
          Text(
            title,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100, 
            width: double.infinity,
            child: CustomPaint(
              painter: TelemetrySparklinePainter(
                dataPoints: dataHistory,
                color: color,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
          ),
        ];
    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: badgeBg,
        border: Border.all(color: badgeBorder, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? color.withOpacity(0.15) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // Small reusable status dot with label used in the top status bar
  Widget _statusDot(String label, Color color) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
  // NOTE: dispose is implemented later to handle all disconnections.
 //════════════════════════════════════════════════════════════
  //  STATE LIFECYCLE (INIT, DISPOSE & LIVE TELEMETRY COUPLING)
  // ════════════════════════════════════════════════════════════
  // 1️⃣ تعيين عداد يدوي تراكمي في أعلى الكلاس (خارج initState) إذا لم يكن معرفاً:
  double? firstTelemetryTimestamp;

  @override
  void initState() {
    super.initState();

    // إعداد الـ ربط الحي مع سيرفر الـ MQTT الخاص بـ Feedcom قابس
    _mqttService = MqttService(
      onMqttStatusChanged: (bool mqttConnected) {
        if (mounted) setState(() => isMqttConnected = mqttConnected);
      },
      onStatusChanged: (bool isConnected) {
        if (mounted) setState(() => isSimulinkConnected = isConnected);
      },
      onTelemetryReceived: (double temp, double vib, double current) {
        if (!mounted) return;
        setState(() {
          // تحديث القيم الرقمية
          temperatureValue = temp;
          vibrationValue = vib;
          currentValue = current;
          
          currentTemperature = temp;
          currentVibration = vib;
          currentCurrent = current;
          
          if (current > 0.5) {
            currentRPM = (1500.0 - (vib * 12) - (temp * 0.4)).clamp(1380.0, 1485.0);
          } else {
            currentRPM = 0.0;
          }

          // 📈 2️⃣ التعديل الذهبي: زيادة العداد بخطوة ثابتة ونظيفة جداً لمنع تداخل النقاط
          if (firstTelemetryTimestamp == null) {
            firstTelemetryTimestamp = DateTime.now().millisecondsSinceEpoch / 1000.0;
          }
          double vibrationXCounter = DateTime.now().millisecondsSinceEpoch / 1000.0 - firstTelemetryTimestamp!;

          // إضافة النقطة بمحور X منتظم هندسياً
          vibrationTimeSpots.add(FlSpot(vibrationXCounter, vib));
          vibSpots.add(FlSpot(vibrationXCounter, vib));
          tempSpots.add(FlSpot(vibrationXCounter, temp));
          currentSpots.add(FlSpot(vibrationXCounter, current));

          // 🧹 3️⃣ حماية الذاكرة: الاعتماد على عدد النقاط (FIFO) لتغطية نافذة العرض بالكامل
          // الاحتفاظ بآخر 250 نقطة يضمن أن الكيرف مفرود ونظيف ومستحيل يرجع خط مستقيم
          if (vibrationTimeSpots.length > 250) vibrationTimeSpots.removeAt(0);
          if (vibSpots.length > 250) vibSpots.removeAt(0);
          if (tempSpots.length > 250) tempSpots.removeAt(0);
          if (currentSpots.length > 250) currentSpots.removeAt(0);

          // تحديث طيف FFT استجابةً للقيم الحقيقية الأخيرة
          vibFftSpots = _generateSimulatedFft(vib);

          // تشغيل خوارزمية حفظ الأرشيف التاريخي
          _checkAndSaveHistory();
        });
      },
    );

    // إطلاق أمر الاتصال الفوري بالسيرفر السحابي
    _connectToMqttTwin();
  }


  Future<void> _connectToMqttTwin() async {
    await _mqttService.connect();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // عمل كاش للصورة لضمان تحميل الموديل بسلاسة
    precacheImage(const AssetImage('assets/images/motor.png'), context);
  }

  @override
  void dispose() {
    // 🛡️ قطع الاتصال بشكل آمن عند الخروج لحماية موارد الجهاز والسيرفر
    _mqttService.disconnect();
    super.dispose();
  }
}

class TelemetrySparklinePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color color;

  final bool isDark;

  TelemetrySparklinePainter({
    required this.dataPoints,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.length < 2) return;

    final paintLine = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final paintGradient = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.2), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final pathLine = Path();
    final pathGradient = Path();

    double dx = size.width / (dataPoints.length - 1);
    double minVal = dataPoints.reduce((a, b) => a < b ? a : b);
    double maxVal = dataPoints.reduce((a, b) => a > b ? a : b);
    double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    for (int i = 0; i < dataPoints.length; i++) {
      double normalizedY = (dataPoints[i] - minVal) / range;
      double x = i * dx;
      double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        pathLine.moveTo(x, y);
        pathGradient.moveTo(x, size.height);
        pathGradient.lineTo(x, y);
      } else {
        pathLine.lineTo(x, y);
        pathGradient.lineTo(x, y);
      }
    }

    pathGradient.lineTo(size.width, size.height);
    pathGradient.close();

    canvas.drawPath(pathGradient, paintGradient);
    canvas.drawPath(pathLine, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}