import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

class PredictiveMaintenanceScreen extends StatefulWidget {
  const PredictiveMaintenanceScreen({super.key});

  @override
  State<PredictiveMaintenanceScreen> createState() => _PredictiveMaintenanceScreenState();
}

class _PredictiveMaintenanceScreenState extends State<PredictiveMaintenanceScreen> with SingleTickerProviderStateMixin {
  Timer? _aiStreamTimer;
  final math.Random _random = math.Random();

  // ─── تليمتري الذكاء الاصطناعي الديناميكي (Live AI Telemetry Engine) ───────────
  double _motorHealthScore = 94.2;        // نسبة سلامة المحرك الإجمالية
  int _remainingUsefulLifeDays = 142;     // العمر الافتراضي المتبقي (RUL)
  double _failureProbability = 4.8;       // احتمالية الفشل المباشر
  double _aiConfidence = 98.6;            // مدى ثقة النموذج الذكي بالتشخيص
  
  // التشخيص التنبئي للحساسات الثلاثة (Vibration, Thermal, Current)
  String _bearingFaultStatus = 'NOMINAL'; // NOMINAL, WARNING, CRITICAL
  String _overheatingStatus = 'STABLE';    // STABLE, ELEVATED, CRITICAL
  String _electricalUnbalance = 'NONE';   // NONE, MINOR, SEVERE

  // ─── لوحة ألوان النمذجة السيبرانية الصناعية المستقرة ───────────────────────────
  final Color colorCyanNeon = const Color(0xFF00E5FF);
  final Color colorPurpleNeon = const Color(0xFF9D4EDD);
  final Color colorEmeraldGreen = const Color(0xFF00E676);
  final Color colorAmberAlert = const Color(0xFFFF9100);
  final Color colorCrimsonAlert = const Color(0xFFFF3333);

  // دالة مساعدة لترجمة النصوص بشكل مريغل (تستدعي المترجم الخاص بكِ في الـ App)
  String t(String key) {
    // يمكنكِ ربطها هنا بكلاس الترجمة اللغوية المتوفر لديكِ في الـ Core
    // كحل افتراضي، سنرجع النص الإنجليزي المقابل للمفتاح لضمان استقرار التشغيل
    Map<String, String> localizedValues = {
      'ai_core_title': 'AI PREDICTIVE MAINTENANCE CORE',
      'ai_core_subtitle': 'Continuous remaining useful life (RUL) execution and anomaly classification',
      'model_confidence': 'MODEL CONFIDENCE: ',
      'health_label': 'HEALTH',
      'nominal_state': 'NOMINAL STATE',
      'asset_name_label': 'Asset Name',
      'inference_rate_label': 'Inference Rate',
      'edge_status_label': 'Edge Unit Status',
      'edge_online': 'ONLINE',
      'pipeline_title': 'PREDICTIVE DIAGNOSTIC PIPELINES (EDGE INFERENCE)',
      'rul_title': 'REMAINING USEFUL LIFE (RUL)',
      'rul_days': 'DAYS',
      'rul_subtitle': 'Estimated window before critical asset overhaul',
      'failure_prob_title': 'INSTANTANEOUS FAILURE PROBABILITY',
      'failure_prob_subtitle': 'Risk matrix correlation across vibration peaks',
    };
    return localizedValues[key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _startAiInferenceSimulation();
  }

  @override
  void dispose() {
    _aiStreamTimer?.cancel();
    super.dispose();
  }

  // محاكاة استنتاج الذكاء الاصطناعي في الوقت الفعلي (Edge AI Inference Stream)
  void _startAiInferenceSimulation() {
    _aiStreamTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;
      setState(() {
        _motorHealthScore = 92.0 + _random.nextDouble() * 3.5;
        _aiConfidence = 97.5 + _random.nextDouble() * 1.4;
        _failureProbability = 3.5 + _random.nextDouble() * 2.1;
        
        int trigger = _random.nextInt(10);
        if (trigger == 7) {
          _bearingFaultStatus = 'WARNING';
          _overheatingStatus = 'ELEVATED';
          _remainingUsefulLifeDays = 128;
        } else if (trigger == 9) {
          _bearingFaultStatus = 'CRITICAL';
          _overheatingStatus = 'STABLE';
          _remainingUsefulLifeDays = 94;
        } else {
          _bearingFaultStatus = 'NOMINAL';
          _overheatingStatus = 'STABLE';
          _electricalUnbalance = 'NONE';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 سحب الألوان ديناميكياً بناءً على وضع النهار أو الليل النشط
    final Color themeBg = Theme.of(context).scaffoldBackgroundColor;
    final Color cardBg = Theme.of(context).cardColor;
    final Color borderLine = Theme.of(context).dividerColor.withOpacity(0.15);
    final Color textMain = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    final Color textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: themeBg, 
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAiHeader(cardBg, borderLine, textMain, textSecondary),
              const SizedBox(height: 24),
              
              // صف العدادات الحركية الأساسية لغرفة التحكم (Main Gauges Row)
              LayoutBuilder(builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 900;
                return isWide 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: _buildMainGaugeCard(cardBg, borderLine, textMain, textSecondary)),
                          const SizedBox(width: 18),
                          Expanded(flex: 3, child: _buildMetricsGridPanel(cardBg, borderLine, textSecondary)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildMainGaugeCard(cardBg, borderLine, textMain, textSecondary),
                          const SizedBox(height: 18),
                          _buildMetricsGridPanel(cardBg, borderLine, textSecondary),
                        ],
                      );
              }),
              
              const SizedBox(height: 26),
              _buildSectionTitle(t('pipeline_title'), textMain),
              const SizedBox(height: 16),
              
              // شبكة بطاقات الفشل المتوقع للحساسات الثلاثة المتوافقة مع الثيم
              _buildAiDiagnosticCardsGrid(cardBg, borderLine, textMain, textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. التصميم العلوي المستقبلي للوحة الذكاء الاصطناعي ────────────────────────
  Widget _buildAiHeader(Color cardBg, Color borderLine, Color textMain, Color textSecondary) {
    return LayoutBuilder(builder: (context, constraints) {
      bool isCompact = constraints.maxWidth < 600;
      
      Widget headerText = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.brain, color: colorCyanNeon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  t('ai_core_title'),
                  style: TextStyle(color: textMain, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.2, fontFamily: 'Courier'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t('ai_core_subtitle'),
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
        ],
      );

      Widget confidenceBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorPurpleNeon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorPurpleNeon.withOpacity(0.4), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t('model_confidence'), style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
            Text('${_aiConfidence.toStringAsFixed(1)}%', style: TextStyle(color: colorPurpleNeon, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
          ],
        ),
      );

      return isCompact 
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerText,
                const SizedBox(height: 12),
                confidenceBadge,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: headerText),
                const SizedBox(width: 16),
                confidenceBadge,
              ],
            );
    });
  }

  Widget _buildSectionTitle(String title, Color textMain) {
    return Row(
      children: [
        Container(width: 5, height: 15, color: colorPurpleNeon),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0))),
      ],
    );
  }

  // ─── 2. كرت العداد الدائري العملاق لسلامة المحرك (Motor Health Score Gauge) ───
  Widget _buildMainGaugeCard(Color cardBg, Color borderLine, Color textMain, Color textSecondary) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLine, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // العداد الدائري المخصص
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _motorHealthScore),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CustomPaint(
                      size: const Size(160, 160),
                      painter: AiGaugePainter(
                        percentage: value,
                        activeColor: value > 80 ? colorEmeraldGreen : (value > 60 ? colorAmberAlert : colorCrimsonAlert),
                        trackColor: textSecondary.withOpacity(0.12),
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t('health_label'), style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(height: 2),
                    Text(
                      '${_motorHealthScore.toStringAsFixed(1)}%',
                      style: TextStyle(color: textMain, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Courier'),
                    ),
                    const SizedBox(height: 2),
                    Text(t('nominal_state'), style: TextStyle(color: colorEmeraldGreen, fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          ),
          // تفاصيل التحليل الجانبي المباشر داخل نفس الكرت
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGaugeDetailRow(Icons.bolt_rounded, t('asset_name_label'), 'SEW-DRN225S4', textMain, textSecondary),
              const SizedBox(height: 14),
              _buildGaugeDetailRow(Icons.query_stats_rounded, t('inference_rate_label'), '125 ms / spl', textMain, textSecondary),
              const SizedBox(height: 14),
              _buildGaugeDetailRow(Icons.security_update_good_rounded, t('edge_status_label'), t('edge_online'), textMain, textSecondary, valueColor: colorEmeraldGreen),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGaugeDetailRow(IconData icon, String label, String value, Color textMain, Color textSecondary, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 12, color: valueColor ?? textMain.withOpacity(0.7)),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(color: valueColor ?? textMain, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Courier')),
          ],
        )
      ],
    );
  }

  // ─── 3. لوحة عرض المؤشرات الرقمية التنبؤية (RUL & Failure Probability) ───────
  Widget _buildMetricsGridPanel(Color cardBg, Color borderLine, Color textSecondary) {
    return SizedBox(
      height: 260,
      child: Column(
        children: [
          // كرت العمر الافتراضي المتبقي (Remaining Useful Life)
          Expanded(
            child: _buildMetricBlock(
              title: t('rul_title'),
              value: '$_remainingUsefulLifeDays ${t('rul_days')}',
              subtitle: t('rul_subtitle'),
              icon: FontAwesomeIcons.hourglassHalf,
              themeColor: colorCyanNeon,
              cardBg: cardBg,
              borderLine: borderLine,
              textSecondary: textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          // كرت احتمالية الفشل اللحظي (Failure Probability)
          Expanded(
            child: _buildMetricBlock(
              title: t('failure_prob_title'),
              value: '${_failureProbability.toStringAsFixed(2)} %',
              subtitle: t('failure_prob_subtitle'),
              icon: FontAwesomeIcons.triangleExclamation,
              themeColor: _failureProbability > 10 ? colorCrimsonAlert : colorAmberAlert,
              cardBg: cardBg,
              borderLine: borderLine,
              textSecondary: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color themeColor,
    required Color cardBg,
    required Color borderLine,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderLine, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: themeColor, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: textSecondary.withOpacity(0.7), fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: themeColor.withOpacity(0.08), shape: BoxShape.circle),
            child: FaIcon(icon, color: themeColor, size: 18),
          )
        ],
      ),
    );
  }

  // ─── 4. شبكة بطاقات التشخيص والتحليل الذكي للحساسات (AI Diagnostic Grid) ─────
  Widget _buildAiDiagnosticCardsGrid(Color cardBg, Color borderLine, Color textMain, Color textSecondary) {
    return LayoutBuilder(builder: (context, constraints) {
      int crossAxisCount = constraints.maxWidth > 1000 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.2,
        children: [
          _buildDiagnosticCard(
            title: 'BEARING FAULT DETECTION',
            status: _bearingFaultStatus,
            nominalDesc: 'Inner/Outer race vibration envelopes conform to ISO 10816 baseline.',
            warningDesc: 'Micro-shocks captured around 45Hz. Inspection recommended.',
            icon: FontAwesomeIcons.gears,
            accentColor: _bearingFaultStatus == 'NOMINAL' ? colorEmeraldGreen : (_bearingFaultStatus == 'WARNING' ? colorAmberAlert : colorCrimsonAlert),
            cardBg: cardBg,
            borderLine: borderLine,
            textMain: textMain,
            textSecondary: textSecondary,
          ),
          _buildDiagnosticCard(
            title: 'OVERHEATING PREDICTION',
            status: _overheatingStatus,
            nominalDesc: 'Thermal gradient is stable. Heat dissipation within parameters.',
            warningDesc: 'Abnormal infrared rise detected. Checking stator thermal coupling.',
            icon: FontAwesomeIcons.temperatureHigh,
            accentColor: _overheatingStatus == 'STABLE' ? colorCyanNeon : colorCrimsonAlert,
            cardBg: cardBg,
            borderLine: borderLine,
            textMain: textMain,
            textSecondary: textSecondary,
          ),
          _buildDiagnosticCard(
            title: 'ELECTRICAL BALANCE TRACKER',
            status: _electricalUnbalance,
            nominalDesc: 'Three-phase symmetrical components show current equilibrium.',
            warningDesc: 'Minor load phase shifting detected in third harmonic calculations.',
            icon: FontAwesomeIcons.bolt,
            accentColor: _electricalUnbalance == 'NONE' ? colorEmeraldGreen : colorAmberAlert,
            cardBg: cardBg,
            borderLine: borderLine,
            textMain: textMain,
            textSecondary: textSecondary,
          ),
        ],
      );
    });
  }

  Widget _buildDiagnosticCard({
    required String title,
    required String status,
    required String nominalDesc,
    required String warningDesc,
    required IconData icon,
    required Color accentColor,
    required Color cardBg,
    required Color borderLine,
    required Color textMain,
    required Color textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLine, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    FaIcon(icon, color: accentColor, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: TextStyle(color: textMain, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(status, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w900, fontFamily: 'Courier')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Text(
              status == 'NOMINAL' || status == 'STABLE' || status == 'NONE' ? nominalDesc : warningDesc,
              style: TextStyle(color: textSecondary, fontSize: 11, height: 1.4),
            ),
          )
        ],
      ),
    );
  }
}

// ─── 5. محرك رسم العداد الدائري السيبراني المخصص المتجاوب ─────────────────────────
class AiGaugePainter extends CustomPainter {
  final double percentage;
  final Color activeColor;
  final Color trackColor;

  AiGaugePainter({required this.percentage, required this.activeColor, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width / 2, size.height / 2) - 10;
    const double startAngle = -math.pi * 1.25;
    const double sweepAngle = math.pi * 1.5;

    // 1. رسم المسار الخلفي (تلقائي التباين حسب وضع الإضاءة)
    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);

    // 2. رسم العداد الملون النشط بناءً على نسبة استنتاج الـ AI
    final double currentSweepAngle = (percentage / 100) * sweepAngle;
    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, currentSweepAngle, false, activePaint);
    
    // 3. رسم خطوط الشبكة الصناعية الصغيرة الخارجية (Outer Industrial Ticks)
    final Paint tickPaint = Paint()
      ..color = activeColor.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    for (int i = 0; i <= 30; i++) {
      double angle = startAngle + (i / 30) * sweepAngle;
      Offset startPoint = Offset(center.dx + (radius + 12) * math.cos(angle), center.dy + (radius + 12) * math.sin(angle));
      Offset endPoint = Offset(center.dx + (radius + 18) * math.cos(angle), center.dy + (radius + 18) * math.sin(angle));
      canvas.drawLine(startPoint, endPoint, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AiGaugePainter oldDelegate) {
    return oldDelegate.percentage != percentage || oldDelegate.activeColor != activeColor || oldDelegate.trackColor != trackColor;
  }
}