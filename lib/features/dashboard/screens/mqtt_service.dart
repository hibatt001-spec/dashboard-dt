import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;
  
  final Function(double temp, double vib, double current) onTelemetryReceived;
  final Function(bool isConnected) onStatusChanged; // 👈 إضافة دالة لتحديث حالة الاتصال في الـ UI

  MqttService({
    required this.onTelemetryReceived,
    required this.onStatusChanged, // 👈 تمريرها هنا
  }) {
    client = MqttServerClient('broker.hivemq.com', 'flutter_digital_twin_${DateTime.now().millisecondsSinceEpoch}');
    client.port = 1883;
    client.keepAlivePeriod = 60;
    client.logging(on: false);

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
  }

  Future<void> connect() async {
    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      // 📡 الاشتراك في الـ Topics (البيانات والحالة)
      client.subscribe('feedcom/gabes/motor1/telemetry', MqttQos.atMostOnce);
      client.subscribe('feedcom/gabes/motor1/status', MqttQos.atMostOnce); // 👈 اشتراك في الـ Status

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String currentTopic = c[0].topic;

        try {
          final Map<String, dynamic> data = jsonDecode(message);

          // 1. إذا كانت الرسالة قادمة من توبيك الحالة
          if (currentTopic == 'feedcom/gabes/motor1/status') {
            bool isConnected = data['status'] == 'connected';
            onStatusChanged(isConnected); // 👈 نغير الحالة في الوجت فوراً
          } 
          // 2. إذا كانت الرسالة قادمة من توبيك البيانات الحية
          else if (currentTopic == 'feedcom/gabes/motor1/telemetry') {
            final double temperature = (data['temperature'] as num).toDouble();
            final double vibration = (data['vibration'] as num).toDouble();
            final double current = (data['current'] as num).toDouble();
            onTelemetryReceived(temperature, vibration, current);
          }
        } catch (e) {
          print('❌ [PARSING ERROR]: $e');
        }
      });
    }
  }

  void _onConnected() => print('🛰️ Connected to HiveMQ.');
  void _onDisconnected() => print('❌ Disconnected.');
  void disconnect() => client.disconnect();
}