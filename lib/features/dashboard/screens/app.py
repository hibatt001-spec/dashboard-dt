import json
import socket
import struct
import threading
import time
from flask import Flask, jsonify
from flask_mqtt import Mqtt

app = Flask(__name__)

# 🌐 إعدادات HiveMQ Broker
app.config['MQTT_BROKER_URL'] = 'broker.hivemq.com'
app.config['MQTT_BROKER_PORT'] = 1883
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_KEEPALIVE'] = 60
app.config['MQTT_TLS_ENABLED'] = False

mqtt = Mqtt(app)

# 📡 إعداد سوكيت الـ UDP للاستماع لـ Simulink محلياً
UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(False)  # لكي لا يعطل سيرفر Flask الرئيسي

@app.route('/')
def home():
    return jsonify({
        "status": "Online",
        "project": "Digital Twin - Feedcom Gabes",
        "engine": "SEW-EURODRIVE"
    })

# 📥 دالة استقبال البيانات من سيمولينك وتحويلها إلى MQTT
def listen_to_simulink():
    try:
        data, addr = sock.recvfrom(1024)  # استقبال المصفوفة من سيمولينك
        unpacked_data = struct.unpack('ddd', data)  # تفكيك 3 متغيرات من نوع double
        
        telemetry = {
            "vibration": unpacked_data[0],
            "temperature": unpacked_data[1],
            "current": unpacked_data[2]
        }
        
        # نشر البيانات مباشرة ليلتقطها تطبيق الـ Flutter
        mqtt.publish('feedcom/gabes/motor1/telemetry', json.dumps(telemetry))
        print(f"📡 [LIVE STREAM]: Published telemetry -> {telemetry}")
        
    except BlockingIOError:
        pass  # لا توجد بيانات قادمة في هذه الملي ثانية، تجاوز الخطأ بأمان
    except Exception as e:
        print(f"❌ [ERROR]: {e}")

# 🚀 دالة الخلفية المستمرة
def simulink_worker():
    print("🤖 Background thread started: Listening for Simulink UDP packets on port 5005...")
    while True:
        listen_to_simulink()
        time.sleep(0.01)  # تأخير بسيط جداً لتخفيف الضغط على المعالج

@mqtt.on_connect()
def handle_connect(client, userdata, flags, rc):
    if rc == 0:
        print("\n🤖 [MQTT STATUS]: Connected to HiveMQ Broker successfully!")
    else:
        print(f"❌ [MQTT ERROR]: Connection failed with code {rc}")

if __name__ == '__main__':
    # تشغيل خيط الخلفية للاستماع للماتلاب فور إقلاع السيرفر
    threading.Thread(target=simulink_worker, daemon=True).start()
    
    # تشغيل سيرفر بايثون فلاسك
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)