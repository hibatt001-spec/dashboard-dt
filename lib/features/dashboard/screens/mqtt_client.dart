import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 

class MotorStreamProvider extends ChangeNotifier {
  late MqttServerClient client;
  List<FlSpot> vibrationPointsESP32 = [];
  List<FlSpot> tempPointsESP32 = [];
  List<FlSpot> rpmPointsESP32 = [];
  List<FlSpot> currentPointsESP32 = [];

  double currentVibration = 0.0;
  double currentTemperature = 0.0;
  double currentRPM = 0.0;
  double currentCurrent = 0.0;
  double _timeCounter = 0.0;

  void connectMqtt() async {
    client = MqttServerClient('YOUR_HIVEMQ_BROKER_URL', 'flutter_client');
    client.port = 1883;
    client.keepAlivePeriod = 20;

    try {
      await client.connect();
      // الاشتراك في الـ Topic متع الموتور
      client.subscribe('motor/telemetry', MqttQos.atMostOnce);
      
      // الاستماع للبيانات القادمة في الوقت الحقيقي
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String rawPayload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        
        // تفكيك الـ JSON اللي جاي من الـ ESP32 عبر الكيبل
        final data = jsonDecode(rawPayload);
        
        // تحديث الكربات ديركت
        updateTelemetryFromESP32(
          incomingVib: data['vibration'].toDouble(),
          incomingTemp: data['temp'].toDouble(),
          incomingRpm: data['rpm'].toDouble(),
          incomingCurrent: data['current'].toDouble(),
        );
      });
    } catch (e) {
      debugPrint('MQTT Connection failed: $e');    }
  }

void updateTelemetryFromESP32({
    required double incomingVib,
    required double incomingTemp,
    required double incomingRpm,
    required double incomingCurrent,
  }) {
    _timeCounter += 0.2; 

    currentVibration = incomingVib;
    currentTemperature = incomingTemp;
    currentRPM = incomingRpm;
    currentCurrent = incomingCurrent;

    vibrationPointsESP32.add(FlSpot(_timeCounter, incomingVib));
    tempPointsESP32.add(FlSpot(_timeCounter, incomingTemp));
    rpmPointsESP32.add(FlSpot(_timeCounter, incomingRpm));
    currentPointsESP32.add(FlSpot(_timeCounter, incomingCurrent));

    // باش الكربا ما تتقلش الذاكرة (آخر 30 نقطة)
    if (vibrationPointsESP32.length > 30) {
      vibrationPointsESP32.removeAt(0);
      tempPointsESP32.removeAt(0);
      rpmPointsESP32.removeAt(0);
      currentPointsESP32.removeAt(0);
    }

    notifyListeners(); // هذي تعاود ترسم الكربات والـ 3D لايف
  }
}
