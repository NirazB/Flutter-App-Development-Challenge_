import asyncio
import json
import socket
import subprocess
import threading
import time
import os
import psutil
import urllib.request
from flask import Flask, render_template, request, send_from_directory, jsonify
from flask_socketio import SocketIO, emit
from werkzeug.utils import secure_filename
from pynput.mouse import Controller, Button
import websockets

# Try importing Windows-specific libraries
try:
    import wmi
    import pythoncom
    from ctypes import cast, POINTER
    from comtypes import CLSCTX_ALL
    from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
    import screen_brightness_control as sbc
    HAS_WINDOWS_LIBS = True
except ImportError:
    HAS_WINDOWS_LIBS = False
    print("Warning: Windows-specific libraries not found. Some features may not work.")

# ============================================================================
# CONFIGURATION
# ============================================================================

LAPTOP_PORT = 2000
WEB_PORT = 5000
GYRO_PORT = 8765
PERF_PORT = 8766

LIBRE_HARDWARE_URL = "http://localhost:8085/data.json"

# ============================================================================
# LAPTOP CONTROLLER LOGIC (Port 2000)
# ============================================================================

def get_volume():
    if not HAS_WINDOWS_LIBS: return 50
    try:
        pythoncom.CoInitialize()
        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        volume = cast(interface, POINTER(IAudioEndpointVolume))
        return int(volume.GetMasterVolumeLevelScalar() * 100)
    except Exception as e:
        print(f"Get Volume Error: {e}")
        return 50
    finally:
        pythoncom.CoUninitialize()

def set_volume(level):
    if not HAS_WINDOWS_LIBS: return
    try:
        pythoncom.CoInitialize()
        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        volume = cast(interface, POINTER(IAudioEndpointVolume))
        volume.SetMasterVolumeLevelScalar(level / 100.0, None)
        print(f"Volume set to: {level}%")
    except Exception as e:
        print(f"Set Volume Error: {e}")
    finally:
        pythoncom.CoUninitialize()

def get_wifi():
    try:
        result = subprocess.run('netsh interface show interface name="Wi-Fi"', 
                              shell=True, capture_output=True, text=True)
        return "Enabled" in result.stdout
    except:
        return True

def set_wifi(enabled):
    state = "enabled" if enabled else "disabled"
    try:
        # Restart adapter to fix potential airplane mode lockups
        if enabled:
            subprocess.run('powershell -Command "Restart-NetAdapter -Name \'Wi-Fi\'"', shell=True)
            time.sleep(0.5)
        
        cmd = f'netsh interface set interface name="Wi-Fi" admin={state}'
        subprocess.run(cmd, shell=True)
        print(f"WiFi set to {state}")
    except Exception as e:
        print(f"WiFi Error: {e}")

def get_bluetooth():
    try:
        result = subprocess.run(
            ['powershell', '-Command', 
             'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -eq "OK"} | Measure-Object | Select-Object -ExpandProperty Count'],
            capture_output=True, text=True
        )
        count = result.stdout.strip()
        return int(count) > 0 if count.isdigit() else False
    except:
        return False

def set_bluetooth(enabled):
    try:
        if enabled:
            subprocess.run(['powershell', '-Command', 
                          'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -ne "OK"} | Enable-PnpDevice -Confirm:$false'], 
                          capture_output=True)
        else:
            subprocess.run(['powershell', '-Command', 
                          'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -eq "OK"} | Disable-PnpDevice -Confirm:$false'], 
                          capture_output=True)
        print(f"Bluetooth set to {enabled}")
    except Exception as e:
        print(f"Bluetooth Error: {e}")

def set_airplane_mode(enabled):
    try:
        if enabled:
            set_wifi(False)
            set_bluetooth(False)
        else:
            # Enable sequentially to avoid conflicts
            set_bluetooth(True)
            time.sleep(0.5)
            set_wifi(True)
        print(f"Airplane Mode set to {enabled}")
    except Exception as e:
        print(f"Airplane Mode Error: {e}")

def get_brightness():
    if not HAS_WINDOWS_LIBS: return 50
    try:
        brightness = sbc.get_brightness()
        if isinstance(brightness, list): return brightness[0]
        return brightness
    except:
        return 50

def set_brightness(level):
    if not HAS_WINDOWS_LIBS: return
    try:
        sbc.set_brightness(int(level))
        print(f"Brightness set to: {level}%")
    except Exception as e:
        print(f"Brightness Error: {e}")

def get_dark_mode():
    try:
        result = subprocess.run(
            ['reg', 'query', r'HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize', 
             '/v', 'AppsUseLightTheme'],
            capture_output=True, text=True
        )
        return '0x0' in result.stdout
    except:
        return False

def set_dark_mode(is_dark):
    value = 0 if is_dark else 1
    try:
        path = r"HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
        subprocess.run(['reg', 'add', path, '/v', 'AppsUseLightTheme', '/t', 'REG_DWORD', '/d', str(value), '/f'], capture_output=True)
        subprocess.run(['reg', 'add', path, '/v', 'SystemUsesLightTheme', '/t', 'REG_DWORD', '/d', str(value), '/f'], capture_output=True)
        print(f"Dark Mode set to: {is_dark}")
    except Exception as e:
        print(f"Dark Mode Error: {e}")

def laptop_controller_handler(conn, addr):
    print(f"Laptop Controller: Connected by {addr}")
    try:
        data = conn.recv(1024).decode('utf-8')
        if not data: return
        
        request = json.loads(data)
        action = request.get('action')
        val = request.get('value')

        response = {"status": "ok"}

        if action == 'get_status':
            response = {
                "volume": get_volume(),
                "brightness": get_brightness(),
                "wifi": get_wifi(),
                "bluetooth": get_bluetooth(),
                "dark_mode": get_dark_mode()
            }
        elif action == 'volume': set_volume(val)
        elif action == 'brightness': set_brightness(val)
        elif action == 'darkmode': set_dark_mode(val)
        elif action == 'wifi': set_wifi(val)
        elif action == 'bluetooth': set_bluetooth(val)
        elif action == 'airplane_mode': set_airplane_mode(val)

        conn.sendall(json.dumps(response).encode('utf-8'))
    except Exception as e:
        print(f"Laptop Controller Error: {e}")
    finally:
        conn.close()

def start_laptop_controller():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind(('0.0.0.0', LAPTOP_PORT))
        s.listen()
        print(f"Laptop Controller running on 0.0.0.0:{LAPTOP_PORT}")
        while True:
            conn, addr = s.accept()
            threading.Thread(target=laptop_controller_handler, args=(conn, addr)).start()

# ============================================================================
# PERFORMANCE MONITOR LOGIC (Port 8766)
# ============================================================================

def get_libre_hardware_data():
    cpu_temp = gpu_temp = fan_speed = None
    try:
        with urllib.request.urlopen(LIBRE_HARDWARE_URL, timeout=0.5) as response:
            data = json.loads(response.read())
            
            def parse_hardware(hw):
                nonlocal cpu_temp, gpu_temp, fan_speed
                if 'Children' in hw:
                    for child in hw['Children']:
                        if child.get('Text') == 'Temperatures':
                            for sensor in child.get('Children', []):
                                name = sensor.get('Text', '')
                                value = sensor.get('Value', '')
                                if value:
                                    try:
                                        temp_val = float(value.replace('°C', '').strip())
                                        if ('Package' in name or 'CPU' in name) and cpu_temp is None:
                                            cpu_temp = temp_val
                                        elif 'GPU Core' in name:
                                            gpu_temp = temp_val
                                    except: pass
                        elif child.get('Text') == 'Fans':
                            for sensor in child.get('Children', []):
                                value = sensor.get('Value', '')
                                if value and fan_speed is None:
                                    try:
                                        fan_speed = float(value.replace('RPM', '').strip())
                                    except: pass
                for child in hw.get('Children', []):
                    parse_hardware(child)
            parse_hardware(data)
    except: pass
    return cpu_temp, gpu_temp, fan_speed

def get_wmi_sensors():
    cpu_temp = gpu_temp = fan_speed = None
    if not HAS_WINDOWS_LIBS: return None, None, None
    try:
        pythoncom.CoInitialize()
        for namespace in ['root\\OpenHardwareMonitor', 'root\\LibreHardwareMonitor']:
            try:
                w = wmi.WMI(namespace=namespace)
                sensors = w.Sensor()
                for sensor in sensors:
                    if sensor.SensorType == 'Temperature':
                        if 'CPU' in sensor.Name and cpu_temp is None: cpu_temp = sensor.Value
                        elif 'GPU' in sensor.Name and gpu_temp is None: gpu_temp = sensor.Value
                    elif sensor.SensorType == 'Fan' and fan_speed is None: fan_speed = sensor.Value
                if cpu_temp is not None: break
            except: continue
    except: pass
    finally: pythoncom.CoUninitialize()
    return cpu_temp, gpu_temp, fan_speed

async def get_performance_data():
    mem = psutil.virtual_memory()
    battery = psutil.sensors_battery()
    disk = psutil.disk_usage('C:\\')
    net = psutil.net_io_counters()
    
    # Try LibreHardwareMonitor first, then WMI
    cpu_temp, gpu_temp, fan_speed = get_libre_hardware_data()
    if cpu_temp is None:
        cpu_temp, gpu_temp, fan_speed = get_wmi_sensors()

    return {
        'cpu_usage': psutil.cpu_percent(interval=0.1),
        'memory_total': mem.total,
        'memory_available': mem.available,
        'memory_percent': mem.percent,
        'battery_percent': battery.percent if battery else None,
        'battery_plugged': battery.power_plugged if battery else None,
        'battery_secsleft': battery.secsleft if battery and battery.secsleft != -1 else None,
        'disk_total': disk.total,
        'disk_used': disk.used,
        'disk_percent': disk.percent,
        'net_sent': net.bytes_sent,
        'net_recv': net.bytes_recv,
        'cpu_temp': cpu_temp,
        'gpu_temp': gpu_temp,
        'fan_speed': fan_speed
    }

async def perf_handler(websocket):
    print("Performance Monitor: Client connected")
    try:
        while True:
            data = await get_performance_data()
            await websocket.send(json.dumps(data))
            await asyncio.sleep(1)
    except:
        print("Performance Monitor: Client disconnected")

# ============================================================================
# GYRO MOUSE LOGIC (Port 8765)
# ============================================================================

class GyroMouseController:
    def __init__(self):
        self.mouse = Controller()
        self.sensitivity = 150
        self.deadzone = 0.25
        self.momentum = 0.70
        self.update_rate = 0.01
        self.target_vx = 0.0
        self.target_vy = 0.0
        self.current_vx = 0.0
        self.current_vy = 0.0
        self.running = True

    async def movement_loop(self):
        while self.running:
            self.current_vx = (self.current_vx * self.momentum) + (self.target_vx * (1 - self.momentum))
            self.current_vy = (self.current_vy * self.momentum) + (self.target_vy * (1 - self.momentum))
            
            if abs(self.current_vx) < 0.1: self.current_vx = 0
            if abs(self.current_vy) < 0.1: self.current_vy = 0
            
            if self.current_vx != 0 or self.current_vy != 0:
                self.mouse.move(self.current_vx, self.current_vy)
            
            await asyncio.sleep(self.update_rate)

    async def handler(self, websocket):
        print(f"Gyro Mouse: New connection from {websocket.remote_address}")
        try:
            async for message in websocket:
                data = json.loads(message)
                
                if 'action' in data:
                    if data['action'] == 'click':
                        btn = Button.left if data['button'] == 'left' else Button.right
                        self.mouse.click(btn)
                    elif data['action'] == 'stop':
                        self.target_vx = self.target_vy = self.current_vx = self.current_vy = 0
                    elif data['action'] == 'move':
                        self.mouse.move(data['dx'] * 7.0, data['dy'] * 7.0)
                    continue

                if 'gx' not in data: continue
                
                gx, gy = data['gx'], data['gy']
                if abs(gx) < self.deadzone: gx = 0
                if abs(gy) < self.deadzone: gy = 0
                
                speed_multiplier = self.sensitivity * 0.2
                self.target_vx = gy * speed_multiplier
                self.target_vy = -gx * speed_multiplier
                
        except Exception as e:
            print(f"Gyro Mouse Error: {e}")
            self.target_vx = self.target_vy = 0

# ============================================================================
# UNIFIED WEB SERVER (Port 5000)
# ============================================================================

app = Flask(__name__, template_folder='templates')
app.config['SECRET_KEY'] = 'secret!'
app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'backend', 'uploads')
# Increase buffer size to 10MB to handle large base64 image frames
socketio_web = SocketIO(app, cors_allowed_origins='*', max_http_buffer_size=10 * 1024 * 1024)

os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def get_ip_address():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"

# ===== FILE TRANSFER ROUTES =====

@app.route('/')
def home():
    return render_template('index.html', ip_address=get_ip_address())

@app.route('/files', methods=['GET'])
def list_files():
    files = []
    if os.path.exists(app.config['UPLOAD_FOLDER']):
        for f in os.listdir(app.config['UPLOAD_FOLDER']):
            if os.path.isfile(os.path.join(app.config['UPLOAD_FOLDER'], f)):
                files.append(f)
    return jsonify(files)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file:
        filename = secure_filename(file.filename)
        file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
        socketio_web.emit('file_added', {'filename': filename})
        return jsonify({'message': 'File uploaded successfully', 'filename': filename}), 201

@app.route('/download/<path:filename>', methods=['GET'])
def download_file(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

# ===== VIDEO STREAMING ROUTES =====

@app.route('/video')
def video_dashboard():
    return render_template('dashboard.html')

# ===== SOCKETIO EVENTS =====

@socketio_web.on('connect')
def web_connect():
    print('Web Client connected')

@socketio_web.on('disconnect')
def web_disconnect():
    print('Web Client disconnected')

@socketio_web.on('video_frame')
def handle_video_frame(data):
    try:
        socketio_web.emit('dashboard_video', data)
    except Exception as e:
        print(f"Video Relay Error: {e}")

def start_web_server():
    ip = get_ip_address()
    print(f"Unified Web Server running on http://{ip}:{WEB_PORT}")
    print(f"  - File Transfer: http://{ip}:{WEB_PORT}/")
    print(f"  - Video Streaming: http://{ip}:{WEB_PORT}/video")
    socketio_web.run(app, host='0.0.0.0', port=WEB_PORT, debug=False, allow_unsafe_werkzeug=True)

# ============================================================================
# MAIN EXECUTION
# ============================================================================

async def main():
    print("======================================================================")
    print("UNIFIED LAPTOP CONTROL SERVER")
    print("======================================================================")
    print("Starting all services...")

    # 1. Start Laptop Controller (Thread)
    threading.Thread(target=start_laptop_controller, daemon=True).start()

    # 2. Start Web Server (Thread)
    threading.Thread(target=start_web_server, daemon=True).start()

    print("======================================================================")
    print("All services running! Press Ctrl+C to stop.")
    print("======================================================================")

    # 3. Start Async Services (Performance Monitor & Gyro Mouse)
    # We run these in the main asyncio loop
    
    gyro_controller = GyroMouseController()
    asyncio.create_task(gyro_controller.movement_loop())
    
    print(f"Performance Monitor running on 0.0.0.0:{PERF_PORT}")
    print(f"Gyro Mouse Controller running on 0.0.0.0:{GYRO_PORT}")

    # Keep the main thread alive and run async servers
    async with websockets.serve(perf_handler, "0.0.0.0", PERF_PORT), \
               websockets.serve(gyro_controller.handler, "0.0.0.0", GYRO_PORT):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\nStopping server...")
