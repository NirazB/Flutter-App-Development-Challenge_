import asyncio
import json
import websockets
import psutil
import urllib.request

try:
    import wmi
    import pythoncom
    HAS_WMI = True
except ImportError:
    HAS_WMI = False

PORT = 8766
LIBRE_HARDWARE_URL = "http://localhost:8085/data.json" # i have dedicated libre app for ths

def get_libre_hardware_data():
    cpu_temp = gpu_temp = fan_speed = None
    
    try:
        with urllib.request.urlopen(LIBRE_HARDWARE_URL, timeout=2) as response:
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
                                        if ('Package' in name or 'Tctl' in name or 'CPU' in name) and cpu_temp is None:
                                            cpu_temp = temp_val
                                        elif 'GPU Core' in name:
                                            gpu_temp = temp_val
                                    except:
                                        pass
                        
                        elif child.get('Text') == 'Fans':
                            for sensor in child.get('Children', []):
                                value = sensor.get('Value', '')
                                if value and fan_speed is None:
                                    try:
                                        fan_speed = float(value.replace('RPM', '').strip())
                                    except:
                                        pass
                
                for child in hw.get('Children', []):
                    parse_hardware(child)
            
            parse_hardware(data)
            
    except:
        pass
    
    return cpu_temp, gpu_temp, fan_speed

def get_wmi_sensors():
    cpu_temp = gpu_temp = fan_speed = None
    
    if not HAS_WMI:
        return None, None, None
    
    try:
        pythoncom.CoInitialize()
        
        for namespace in ['root\\OpenHardwareMonitor', 'root\\LibreHardwareMonitor']:
            try:
                w = wmi.WMI(namespace=namespace)
                sensors = w.Sensor()
                
                for sensor in sensors:
                    if sensor.SensorType == 'Temperature':
                        if 'CPU' in sensor.Name and cpu_temp is None:
                            cpu_temp = sensor.Value
                        elif 'GPU' in sensor.Name and gpu_temp is None:
                            gpu_temp = sensor.Value
                    elif sensor.SensorType == 'Fan' and fan_speed is None:
                        fan_speed = sensor.Value
                
                if cpu_temp is not None:
                    break
            except:
                continue
                
    except:
        pass
    finally:
        try:
            pythoncom.CoUninitialize()
        except:
            pass
    
    return cpu_temp, gpu_temp, fan_speed

def get_windows_sensors():
    cpu_temp, gpu_temp, fan_speed = get_libre_hardware_data()
    if cpu_temp is not None:
        return cpu_temp, gpu_temp, fan_speed
    
    return get_wmi_sensors()

async def get_performance_data():
    mem = psutil.virtual_memory()
    battery = psutil.sensors_battery()
    disk = psutil.disk_usage('C:\\')
    net = psutil.net_io_counters()
    cpu_temp, gpu_temp, fan_speed = get_windows_sensors()
    
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

async def handler(websocket):
    print("Client connected")
    try:
        while True:
            data = await get_performance_data()
            await websocket.send(json.dumps(data))
            await asyncio.sleep(1)
    except websockets.exceptions.ConnectionClosed:
        print("Client disconnected")
    except Exception as e:
        print(f"Error: {e}")

async def main():
    print(f"Performance Monitor running on 0.0.0.0:{PORT}")
    async with websockets.serve(handler, "0.0.0.0", PORT):
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Stopping Performance Monitor")