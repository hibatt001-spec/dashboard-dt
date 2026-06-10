import time
import socket
import json
import threading
import struct
from app import app, mqtt  # استيراد التطبيق والـ mqtt معاً

# إعداد سوكيت الـ UDP للاستماع لـ Simulink
UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(False)

# متغيرات لمراقبة حالة الاتصال (Heartbeat)
last_received_time = 0
simulink_connected = False

def listen_to_simulink():
    global last_received_time, simulink_connected
    try:
        data, addr = sock.recvfrom(1024)
        unpacked_data = struct.unpack('ddd', data)
        
        # تحديث وقت استقبال آخر حزمة
        last_received_time = time.time()
        
        # إذا كانت الحالة السابقة "غير متصل"، نغيرها وننشر التحديث فوراً
        if not simulink_connected:
            simulink_connected = True
            mqtt.publish('feedcom/gabes/motor1/status', json.dumps({"status": "connected"}))
            print("🟢 [STATUS]: Simulink Connected!")

        telemetry = {
            "vibration": unpacked_data[0],
            "temperature": unpacked_data[1],
            "current": unpacked_data[2]
        }
        
        # نشر البيانات الحية للـ Dashboard
        mqtt.publish('feedcom/gabes/motor1/telemetry', json.dumps(telemetry))
        
    except BlockingIOError:
        pass
    except Exception as e:
        print(f"❌ [ERROR]: {e}")

def simulink_worker():
    global simulink_connected
    print("🚀 [UDP SERVER]: Background thread started! Listening for Simulink packets on port 5005...")
    
    while True:
        listen_to_simulink()
        
        # ⏱️ فحص الـ Timeout: إذا مرت أكثر من 2 ثانية بدون أي بيانات جديدة من سيمولينك
        if simulink_connected and (time.time() - last_received_time > 2.0):
            simulink_connected = False
            # إرسال حالة الفصل للتطبيق
            mqtt.publish('feedcom/gabes/motor1/status', json.dumps({"status": "disconnected"}))
            print("🔴 [STATUS]: Simulink Disconnected (Timeout).")
            
        time.sleep(0.01)

if __name__ == '__main__':
    # 1. إطلاق خيط الخلفية
    threading.Thread(target=simulink_worker, daemon=True).start()
    
    # 2. تشغيل السيرفر الرئيسي
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)