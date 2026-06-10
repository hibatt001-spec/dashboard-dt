import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IndustrialSettingsScreen extends StatefulWidget {
  const IndustrialSettingsScreen({super.key});

  @override
  State<IndustrialSettingsScreen> createState() =>
      _IndustrialSettingsScreenState();
}

class _IndustrialSettingsScreenState extends State<IndustrialSettingsScreen> {
  // ─── تتبع الحالات والمتغيرات (State Management Variables) ─────────────────
  final _formKey = GlobalKey<FormState>();

  // Section 1: General
  final _dashboardNameController = TextEditingController(
    text: "FEEDCOM_MOTOR_FA107",
  );
  String _selectedLanguage = 'English';
  String _currentSimulationMode = 'Normal Operation';

  bool _isDarkMode = true;
  double _refreshRate = 1.0;
  bool _is24hFormat = true;

  // Section 2: Connectivity
  bool _esp32Connected = true;
  final _mqttBrokerController = TextEditingController(text: "broker.emqx.io");
  final _mqttPortController = TextEditingController(text: "1883");
  final _mqttTopicController = TextEditingController(
    text: "feedcom/gabes/motor1/telemetry",
  );
  bool _autoReconnect = true;
  bool _isTestingConnection = false;

  // Section 3: Alerts Thresholds
  double _tempThreshold = 75.0;
  double _vibThreshold = 4.5;
  double _currentThreshold = 15.5;
  String _criticalAlarmLevel = 'Critical';
  bool _enableNotifications = true;
  bool _enableAlarmSound = true;

  // Section 4: AI & Edge Impulse
  bool _enableAIPredictions = true;
  String _edgeImpulseStatus = 'DEPLOYED (Optimized)';
  double _predictionInterval = 5.0;
  double _confidenceThreshold = 85.0;
  bool _enableAnomalyDetection = true;

  // Section 5: Dashboard Display
  bool _showCharts = true;
  bool _showKpis = true;
  bool _showAiSection = true;
  bool _showDigitalTwin = true;
  bool _showHistory = true;
  bool _fullScreenMode = false;

  // Section 6: Appearance
  Color _accentColor = const Color(0xFF00C2FF);
  double _animationSpeed = 300;
  bool _glassEffect = true;
  bool _neonGlow = true;
  double _cardTransparency = 0.15;

  // Section 7: Simulation Parameters
  bool _enableSimulation = false;
  String _activeSimulationScenario = 'Normal Operation';

  // Section 8: Reports Settings
  bool _autoPdfReports = true;
  bool _dailyReports = true;
  bool _weeklyReports = false;
  String _exportFormat = 'PDF / CSV';
  double _storageLimitMonths = 6;

  // Section 9: Security Settings
  bool _userAuthRequired = true;
  bool _adminAccess = false;
  double _sessionTimeout = 15;

  // ─── لوحة الألوان السيبرانية الصناعية الثابتة ──────────────────────────────
  final Color bgDark = const Color(0xFF0B1020);
  final Color baseCardBg = const Color(0xFF182338);
  final Color baseBorderBg = const Color(0xFF2A3A5A);
  final Color textMain = const Color(0xFFF5F7FA);
  final Color textSub = const Color(0xFFAAB6C5);
  final Color neonCyan = const Color(0xFF00C2FF);
  final Color neonGreen = const Color(0xFF00E676);
  final Color dangerRed = const Color(0xFFFF5252);

  @override
  void dispose() {
    _dashboardNameController.dispose();
    _mqttBrokerController.dispose();
    _mqttPortController.dispose();
    _mqttTopicController.dispose();
    super.dispose();
  }

  // محاكاة فحص الاتصال بالـ MQTT و ESP32
  void _testConnectivity() async {
    setState(() => _isTestingConnection = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isTestingConnection = false;
      _esp32Connected = !_esp32Connected;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esp32Connected
                ? '⚡ MQTT Connection Successful'
                : '❌ Connection Lost',
          ),
          backgroundColor: _esp32Connected ? neonGreen : dangerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // التكيف مع حجم الشاشة (Responsive Layout Architecture)
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: baseCardBg,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.settings_suggest_rounded, color: _accentColor, size: 22),
            const SizedBox(width: 10),
            Text(
              "⚙️ SCADA CONTROL SYSTEM - CONFIGURATION PANEL",
              style: TextStyle(
                color: textMain,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        actions: [
          _buildStatusTag("SYSTEM STATUS: READY", neonGreen),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: baseBorderBg, height: 1.2),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: isWideScreen
              ? _buildHorizontalLayout()
              : _buildVerticalLayout(),
        ),
      ),
      bottomNavigationBar: _buildBottomActionPanel(),
    );
  }

  // تخطيط طولي للشاشات الصغيرة (الهواتف)
  Widget _buildVerticalLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(children: _buildAllSettingsSections()),
    );
  }

  // تخطيط شبكي متوازي للشاشات الكبيرة (Tablets / PC)
  Widget _buildHorizontalLayout() {
    final sections = _buildAllSettingsSections();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [
              sections[0],
              sections[2],
              sections[4],
              sections[6],
              sections[8],
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            children: [sections[1], sections[3], sections[5], sections[7]],
          ),
        ),
      ],
    );
  }

  // مصفوفة تحتوي على كافة أقسام الإعدادات المطلوبة
  List<Widget> _buildAllSettingsSections() {
    return [
      // 1. General Settings
      _buildSectionWrapper(
        title: "GENERAL CORE SYSTEM SETTINGS",
        icon: Icons.dashboard_customize_rounded,
        children: [
          _buildTextField(
            "Asset Dashboard Node Identifier",
            _dashboardNameController,
          ),
          _buildDropdownField<String>(
            label: "System Language Interface",
            value: _selectedLanguage,
            items: ['English', 'French', 'Arabic'],
            onChanged: (v) => setState(() => _selectedLanguage = v!),
          ),
          _buildSwitchListTile(
            "Telemetry Engine High-Contrast Dark Mode",
            _isDarkMode,
            (v) => setState(() => _isDarkMode = v),
          ),
          _buildSliderField(
            "Data Bus UI Refresh Interval",
            _refreshRate,
            0.1,
            5.0,
            "sec",
            (v) => setState(() => _refreshRate = v),
          ),
          _buildSwitchListTile(
            "Industrial Time Stamp (24-Hour Format)",
            _is24hFormat,
            (v) => setState(() => _is24hFormat = v),
          ),
        ],
      ),

      // 2. Connectivity Settings
      _buildSectionWrapper(
        title: "I/O HARDWARE & MQTT TELEMETRY BUS",
        icon: Icons.lan_rounded,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ESP32 Sensor Array Node Status",
                style: TextStyle(color: textMain, fontSize: 12),
              ),
              _buildStatusTag(
                _esp32Connected ? "ONLINE (UTP CAT6)" : "OFFLINE",
                _esp32Connected ? neonGreen : dangerRed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(
            "MQTT Network Broker IP / DNS Host",
            _mqttBrokerController,
          ),
          _buildTextField(
            "Port Gateway Address",
            _mqttPortController,
            isNumeric: true,
          ),
          _buildTextField(
            "Publish / Subscribe Root Topic Prefix",
            _mqttTopicController,
          ),
          _buildSwitchListTile(
            "Auto-Heal Broken Gateway Pipe",
            _autoReconnect,
            (v) => setState(() => _autoReconnect = v),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isTestingConnection ? null : _testConnectivity,
            icon: _isTestingConnection
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.bolt, size: 16),
            label: Text(
              _isTestingConnection
                  ? "PINGING SERVER..."
                  : "TEST TELEMETRY PIPE",
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: neonCyan.withOpacity(0.2),
              foregroundColor: neonCyan,
              side: BorderSide(color: neonCyan),
              minimumSize: const Size(double.infinity, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),

      // 3. Alert Settings
      _buildSectionWrapper(
        title: "CRITICAL ALARM LIMITS & INTERRUPTS",
        icon: Icons.notification_important_rounded,
        children: [
          _buildSliderField(
            "Asynchronous Motor Core Temp Limit",
            _tempThreshold,
            40,
            120,
            "°C",
            (v) => setState(() => _tempThreshold = v),
          ),
          _buildSliderField(
            "Bearing Radial Vibration Velocity Peak",
            _vibThreshold,
            0.5,
            12.0,
            "mm/s",
            (v) => setState(() => _vibThreshold = v),
          ),
          _buildSliderField(
            "Stator Nominal Line Current Threshold",
            _currentThreshold,
            1.0,
            32.0,
            "A",
            (v) => setState(() => _currentThreshold = v),
          ),
          _buildDropdownField<String>(
            label: "Aggressive Alarm Severity Matrix",
            value: _criticalAlarmLevel,
            items: ['Warning Only', 'Critical', 'Emergency Emergency Stop'],
            onChanged: (v) => setState(() => _criticalAlarmLevel = v!),
          ),
          _buildSwitchListTile(
            "Dispatch Native System UI Push Alerts",
            _enableNotifications,
            (v) => setState(() => _enableNotifications = v),
          ),
          _buildSwitchListTile(
            "Trigger Physical SCADA Hooter Sound",
            _enableAlarmSound,
            (v) => setState(() => _enableAlarmSound = v),
          ),
        ],
      ),

      // 4. AI Settings
      _buildSectionWrapper(
        title: "EDGE IMPULSE NEURAL CLASSIFIER (TINYML)",
        icon: Icons.psychology_rounded,
        children: [
          _buildSwitchListTile(
            "Enable Machine Learning Inference Engine",
            _enableAIPredictions,
            (v) => setState(() => _enableAIPredictions = v),
          ),
          _buildTextField(
            "C-MCU Compiled Model Signature State",
            TextEditingController(text: _edgeImpulseStatus),
            enabled: false,
          ),
          _buildSliderField(
            "Anomaly Scanning Window Resolution",
            _predictionInterval,
            1.0,
            30.0,
            "sec",
            (v) => setState(() => _predictionInterval = v),
          ),
          _buildSliderField(
            "Softmax Classifier Mathematical Confidence Cutoff",
            _confidenceThreshold,
            50,
            99,
            "%",
            (v) => setState(() => _confidenceThreshold = v),
          ),
          _buildSwitchListTile(
            "Isolate Unknown Spectral Waveform Deviations",
            _enableAnomalyDetection,
            (v) => setState(() => _enableAnomalyDetection = v),
          ),
        ],
      ),

      // 5. Dashboard Display Settings
      _buildSectionWrapper(
        title: "SCADA TELEMETRY DISPLAY GRAPHICS",
        icon: Icons.analytics_outlined,
        children: [
          _buildSwitchListTile(
            "Render High-Density FFT & Time Charts",
            _showCharts,
            (v) => setState(() => _showCharts = v),
          ),
          _buildSwitchListTile(
            "Display OEE / MTBF Operational Key Metrics",
            _showKpis,
            (v) => setState(() => _showKpis = v),
          ),
          _buildSwitchListTile(
            "Show TinyML Predictive Health Timeline",
            _showAiSection,
            (v) => setState(() => _showAiSection = v),
          ),
          _buildSwitchListTile(
            "Show SolidWorks CAO Simscape Kinematic Motor View",
            _showDigitalTwin,
            (v) => setState(() => _showDigitalTwin = v),
          ),
          _buildSwitchListTile(
            "Show Historical InfluxDB Log Data Matrix",
            _showHistory,
            (v) => setState(() => _showHistory = v),
          ),
          _buildSwitchListTile(
            "Lock UI In Native Full Screen Control Mode",
            _fullScreenMode,
            (v) => setState(() => _fullScreenMode = v),
          ),
        ],
      ),

      // 6. Appearance Settings
      _buildSectionWrapper(
        title: "CYBER HMI THEME & GLASS EFFECT DESIGN",
        icon: Icons.palette_rounded,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Neon Cyber Pipeline Pipeline Palette",
                style: TextStyle(color: textMain, fontSize: 12),
              ),
              Row(
                children: [
                  _buildColorCircle(const Color(0xFF00C2FF)),
                  _buildColorCircle(const Color(0xFF00E676)),
                  _buildColorCircle(const Color(0xFFFF9800)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSliderField(
            "HMI Interpolation Animation Velocity",
            _animationSpeed,
            100,
            1000,
            "ms",
            (v) => setState(() => _animationSpeed = v),
          ),
          _buildSwitchListTile(
            "Enable Advanced CSS Frosted Glass Effect",
            _glassEffect,
            (v) => setState(() => _glassEffect = v),
          ),
          _buildSwitchListTile(
            "Inject High-Intensity Photonic Neon Glow",
            _neonGlow,
            (v) => setState(() => _neonGlow = v),
          ),
          _buildSliderField(
            "Sub-Layer Alpha Transparency Opacity",
            _cardTransparency,
            0.05,
            0.40,
            "",
            (v) => setState(() => _cardTransparency = v),
          ),
        ],
      ),

      // 7. Simulation Settings
      _buildSectionWrapper(
        title: "ISOLATED FAULT INJECTION SIMULATOR ENGINE",
        icon: Icons.model_training_rounded,
        children: [
          _buildSwitchListTile(
            "Override Live Hardware (Activate Software Bus)",
            _enableSimulation,
            (v) => setState(() => _enableSimulation = v),
          ),
          _buildDropdownField<String>(
            label: "Mathematical Error Injection Matrix Selector",
            value: _activeSimulationScenario,
            items: [
              'Normal Operation',
              'Overload Simulation',
              'High Vibration Simulation',
              'Overheating Simulation',
              'Bearing Fault Simulation',
            ],
            onChanged: _enableSimulation
                ? (v) => setState(() => _activeSimulationScenario = v!)
                : null,
          ),
        ],
      ),

      // 8. Reports Settings
      _buildSectionWrapper(
        title: "AUTOMATED COMPLIANCE & HISTORIAN LOGS",
        icon: Icons.assessment_rounded,
        children: [
          _buildSwitchListTile(
            "Build Native Structural PDF Compliance Dossier",
            _autoPdfReports,
            (v) => setState(() => _autoPdfReports = v),
          ),
          _buildSwitchListTile(
            "Execute Daily Shift Data Export Sequence",
            _dailyReports,
            (v) => setState(() => _dailyReports = v),
          ),
          _buildSwitchListTile(
            "Execute Weekly Aggregate Maintenance Log",
            _weeklyReports,
            (v) => setState(() => _weeklyReports = v),
          ),
          _buildDropdownField<String>(
            label: "Export Raw Structural Schema Format",
            value: _exportFormat,
            items: ['PDF / CSV', 'JSON Raw Telemetry', 'Excel Sheet'],
            onChanged: (v) => setState(() => _exportFormat = v!),
          ),
          _buildSliderField(
            "Local Buffer Alert Purge Boundary",
            _storageLimitMonths,
            1,
            24,
            "Months",
            (v) => setState(() => _storageLimitMonths = v),
          ),
        ],
      ),

      // 9. Security Settings
      _buildSectionWrapper(
        title: "OPERATOR ACCESS ACCESS GATE & ENCRYPTION",
        icon: Icons.admin_panel_settings_rounded,
        children: [
          _buildSwitchListTile(
            "Enforce Biometric Cryptographic Handshake",
            _userAuthRequired,
            (v) => setState(() => _userAuthRequired = v),
          ),
          _buildSwitchListTile(
            "Elevate Current Session Token To Root Administrator",
            _adminAccess,
            (v) => setState(() => _adminAccess = v),
          ),
          _buildSliderField(
            "Idle Terminal Server Active Session Lifespan",
            _sessionTimeout,
            5,
            60,
            "min",
            (v) => setState(() => _sessionTimeout = v),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.lock_reset, size: 14),
            label: const Text(
              "ROTATE RSA CIPHER KEYS / PASSWORD",
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: textMain,
              side: BorderSide(color: baseBorderBg, width: 1.2),
              minimumSize: const Size(double.infinity, 38),
            ),
          ),
        ],
      ),
    ];
  }

  // ─── Reusable Custom Widgets Architecture (UI Blocks) ──────────────────────

  // حاوية الأقسام ذات طابع الـ Glassmorphic والمحاطة بإطار النيون
  Widget _buildSectionWrapper({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: _animationSpeed.toInt()),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glassEffect
            ? baseCardBg.withOpacity(_cardTransparency)
            : baseCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _neonGlow ? _accentColor.withOpacity(0.25) : baseBorderBg,
          width: 1.2,
        ),
        boxShadow: _neonGlow
            ? [
                BoxShadow(
                  color: _accentColor.withOpacity(0.03),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentColor, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textMain,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Divider(color: baseBorderBg.withOpacity(0.5), thickness: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  // حقل إدخال النص الصناعي المحمي
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumeric = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? textMain : textSub,
          fontSize: 12,
          fontFamily: 'Courier',
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : [],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textSub, fontSize: 11),
          filled: true,
          fillColor: bgDark.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: baseBorderBg, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _accentColor, width: 1.2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: baseBorderBg.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }

  // زر الاختيارات المنسدلة الاحترافي
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: baseCardBg,
        style: TextStyle(color: textMain, fontSize: 12),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textSub, fontSize: 11),
          filled: true,
          fillColor: bgDark.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: baseBorderBg, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _accentColor, width: 1.2),
          ),
        ),
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString(),
              style: const TextStyle(fontFamily: 'Courier'),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // شريط التمرير الرقمي التفاعلي (Sliders)
  Widget _buildSliderField(
    String label,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: textSub, fontSize: 11)),
              Text(
                "${value.toStringAsFixed(1)} $unit",
                style: TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accentColor,
              inactiveTrackColor: baseBorderBg,
              thumbColor: textMain,
              overlayColor: _accentColor.withOpacity(0.2),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // قائمة المفاتيح البرمجية المضيئة المخصصة (Custom Switch Tiles)
  Widget _buildSwitchListTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile.adaptive(
      title: Text(title, style: TextStyle(color: textMain, fontSize: 11.5)),
      value: value,
      activeColor: _accentColor,
      activeTrackColor: _accentColor.withOpacity(0.3),
      inactiveThumbColor: textSub,
      inactiveTrackColor: baseBorderBg,
      contentPadding: EdgeInsets.zero,
      dense: true,
      onChanged: onChanged,
    );
  }

  // بطاقة عرض الحالة العلوية الصغيرة (Status Badges)
  Widget _buildStatusTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: 'Courier',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // دوائر تبديل الألوان البصرية الديناميكية
  Widget _buildColorCircle(Color targetColor) {
    bool isSelected = _accentColor == targetColor;
    return InkWell(
      onTap: () => setState(() => _accentColor = targetColor),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: targetColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // لوحة التحكم والعمليات السفلية لحفظ وتصفير النظام
  Widget _buildBottomActionPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: baseCardBg,
        border: Border(top: BorderSide(color: baseBorderBg, width: 1.2)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              onPressed: () {
                _formKey.currentState?.reset();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔄 Factory Parameter Architecture Restored'),
                    backgroundColor: Color(0xFF182338),
                  ),
                );
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text(
                "RESET CONFIG",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: dangerRed,
                side: BorderSide(color: dangerRed.withOpacity(0.5)),
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(
                        '💾 Settings Flash Memory Transmitted Successfully',
                      ),
                      backgroundColor: neonGreen,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: const Text(
                "COMMIT CHANGES",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                foregroundColor: bgDark,
                minimumSize: const Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: _neonGlow ? 4 : 0,
                shadowColor: neonGreen.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
