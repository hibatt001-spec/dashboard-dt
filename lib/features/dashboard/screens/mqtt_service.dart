import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  late MqttBrowserClient client;

  // 🎯 التعديل: تعديل الـ Callback لتستقبل فقط الـ 3 قيم الفيزيائية الحقيقية للمحرك
  final Function(double temp, double vib, double current) onTelemetryReceived;
  final Function(bool isConnected) onStatusChanged;
  final Function(bool isMqttConnected) onMqttStatusChanged;
  
  MqttService({
    required this.onTelemetryReceived,
    required this.onStatusChanged,
    required this.onMqttStatusChanged,
  }) {
    final String clientIdentifier = 'feedcom_web_${DateTime.now().millisecondsSinceEpoch}';

    // 🌐 الرابط السحابي النظيف المتوافق مع المتصفحات (WebSockets)
    final String clusterUrl = 'wss://96d2dbc610244ebf81fb0869b53769e0.s1.eu.hivemq.cloud/mqtt';
    
    // 🟢 تهيئة العميل على المنفذ الآمن 8884 الخاص بالويب
    client = MqttBrowserClient.withPort(clusterUrl, clientIdentifier, 8884);
    client.logging(on: true);
    client.keepAlivePeriod = 60;

    // 🛡️ تفعيل بروتوكول الـ WebSocket بأمان للـ Web Dashboard
    client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;

    client.onConnected = () {
      print('🟢 [MQTT]: Connected to HiveMQ Cloud Cluster Successfully!');
      onMqttStatusChanged(true);
    };

    client.onDisconnected = () {
      print('🔴 [MQTT]: Disconnected from HiveMQ Cloud.');
      onMqttStatusChanged(false);
    };
  }

  Future<void> connect() async {
    try {
      print('🛰️ [MQTT]: Connecting to Private HiveMQ Cloud on Port 8884...');
      
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(client.clientIdentifier)
          .authenticateAs('touati', '1234*Abih') 
          .startClean();

      await client.connect();
      print('🔍 Status: ${client.connectionStatus?.state}');
      print('🔍 Return code: ${client.connectionStatus?.returnCode}');
    } catch (e) {
      print('❌ [MQTT CONN ERROR]: $e');
      onMqttStatusChanged(false);
      onStatusChanged(false);
      client.disconnect();
      return;
    }

    if (client.connectionStatus != null && 
        client.connectionStatus!.state == MqttConnectionState.connected) {
      
      // الاشتراك في قنوات التليمتري والحالة المخصصة لمحرك فدكوم
      client.subscribe('feedcom/gabes/motor1/telemetry', MqttQos.atMostOnce);
      client.subscribe('feedcom/gabes/motor1/status', MqttQos.atMostOnce);

      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        if (c == null || c.isEmpty) return;

        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final String currentTopic = c[0].topic;

        try {
          final Map<String, dynamic> data = jsonDecode(message);

          // 1. فحص حالة اتصال نظام البايثون والسيمولينك
          if (currentTopic == 'feedcom/gabes/motor1/status') {
            onStatusChanged(data['status'] == 'connected');
          } 
          // 2. معالجة البيانات اللحظية الصافية للمحرك (Real-Time Telemetry)
          else if (currentTopic == 'feedcom/gabes/motor1/telemetry') {
            
            // تمرير الثلاث قيم الفيزيائية مباشرة دون تكلّف مصفوفات الـ FFT المحذوفة
            onTelemetryReceived(
              data['temperature'] != null ? (data['temperature'] as num).toDouble() : 0.0,
              data['vibration'] != null ? (data['vibration'] as num).toDouble() : 0.0,
              data['current'] != null ? (data['current'] as num).toDouble() : 0.0,
            );
          }
        } catch (e) {
          print('❌ [DATA CONVERSION ERROR]: $e');
        }
      });
    }
  }

  void disconnect() {
    client.disconnect();
  }
}