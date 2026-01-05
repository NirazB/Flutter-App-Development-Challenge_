import socket
import json
import subprocess
import threading
import os
import time
import pythoncom
from ctypes import cast, POINTER
from comtypes import CLSCTX_ALL
from pycaw.pycaw import AudioUtilities, IAudioEndpointVolume
import screen_brightness_control as sbc

HOST = '0.0.0.0'
PORT = 2000


def get_volume():
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
        try:
            pythoncom.CoUninitialize()
        except:
            pass

def set_volume(level):
    try:
        pythoncom.CoInitialize()  
        devices = AudioUtilities.GetSpeakers()
        interface = devices.Activate(IAudioEndpointVolume._iid_, CLSCTX_ALL, None)
        volume = cast(interface, POINTER(IAudioEndpointVolume))
        volume.SetMasterVolumeLevelScalar(level / 100.0, None)
        print(f"Volume: {level}%")
    except Exception as e:
        print(f"Volume Error: {e}")
    finally:
        try:
            pythoncom.CoUninitialize()
        except:
            pass

def get_wifi():
    try:
        result = subprocess.run('netsh interface show interface name="Wi-Fi"', 
                              shell=True, capture_output=True, text=True)
        if result.returncode != 0:
            result = subprocess.run('netsh interface show interface name="WLAN"', 
                                  shell=True, capture_output=True, text=True)
        return "Enabled" in result.stdout
    except:
        return True

def set_wifi(enabled):
    state = "enabled" if enabled else "disabled"
    try:
        # We try 'Wi-Fi' first, then 'WLAN' as fallback
        cmd = f'netsh interface set interface name="Wi-Fi" admin={state}'
        result = subprocess.run(cmd, shell=True, capture_output=True)
        if result.returncode != 0:
            subprocess.run(f'netsh interface set interface name="WLAN" admin={state}', shell=True)
        print(f"WiFi set to {state}")
    except Exception as e:
        print(f"WiFi Error: {e}")

def get_bluetooth():
    """Check if Bluetooth is enabled."""
    try:
        result = subprocess.run(
            ['powershell', '-Command', 
             'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -eq "OK"} | Measure-Object | Select-Object -ExpandProperty Count'],
            capture_output=True, text=True, timeout=5
        )
        count = result.stdout.strip()
        return int(count) > 0 if count.isdigit() else False
    except:
        return False

def set_bluetooth(enabled):
    """Uses PnP Device Manager (compatible with all Windows versions)."""
    try:
        if enabled:
            # Re-enable all Bluetooth devices
            subprocess.run([
                'powershell', '-Command',
                'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -ne "OK"} | Enable-PnpDevice -Confirm:$false'
            ], capture_output=True, timeout=10)
            print("Bluetooth enabled")
        else:
            # Disable all Bluetooth devices
            subprocess.run([
                'powershell', '-Command',
                'Get-PnpDevice -Class Bluetooth | Where-Object {$_.Status -eq "OK"} | Disable-PnpDevice -Confirm:$false'
            ], capture_output=True, timeout=10)
            print("Bluetooth disabled")
    except Exception as e:
        print(f"Bluetooth Error: {e}")

def get_airplane_mode():
    """Check if airplane mode is on by checking if both WiFi and Bluetooth are off."""
    wifi_on = get_wifi()
    bt_on = get_bluetooth()
    return not wifi_on and not bt_on

def set_airplane_mode(enabled):
    """Toggle airplane mode by controlling WiFi and Bluetooth."""
    try:
        if enabled:
            print("Enabling airplane mode...")
            set_wifi(False)
            time.sleep(0.3)
            set_bluetooth(False)
        else:
            print("Disabling airplane mode...")
            # Enable with delays to ensure proper initialization
            set_bluetooth(True)
            time.sleep(0.5)
            set_wifi(True)
            print("Airplane mode disabled")
    except Exception as e:
        print(f"Airplane Mode Error: {e}")

def get_dark_mode():
    """Check if dark mode is enabled."""
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
        print(f"Dark Mode: {is_dark}")
    except Exception as e:
        print(f"Registry Error: {e}")

def get_brightness():
    """Get current brightness level."""
    try:
        brightness = sbc.get_brightness()
        if isinstance(brightness, list):
            return brightness[0] if brightness else 50
        return brightness
    except:
        return 50

def set_brightness(level):
    """Set brightness level."""
    try:
        sbc.set_brightness(int(level))
        print(f"Brightness: {level}%")
    except Exception as e:
        print(f"Brightness Error: {e}")

def handle_client(conn, addr):
    print(f"Connected by {addr}")
    try:
        data = conn.recv(1024).decode('utf-8')
        if not data: return
        
        request = json.loads(data)
        action = request.get('action')
        val = request.get('value')

        if action == 'get_status':
            response = {
                "volume": get_volume(),
                "brightness": get_brightness(),
                "isDarkMode": get_dark_mode(),
                "isWifiOn": get_wifi(),
                "isBluetoothOn": get_bluetooth(),
                "isAirplaneModeOn": get_airplane_mode()
            }
        elif action == 'volume':
            set_volume(int(val))
            response = {"status": "ok"}
        elif action == 'brightness':
            set_brightness(int(val))
            response = {"status": "ok"}
        elif action == 'darkmode':
            set_dark_mode(val == 'dark')
            response = {"status": "ok"}
        elif action == 'wifi':
            set_wifi(val)
            response = {"status": "ok"}
        elif action == 'bluetooth':
            set_bluetooth(val)
            response = {"status": "ok"}
        elif action == 'airplane_mode':
            set_airplane_mode(val)
            response = {"status": "ok"}
        else:
            response = {"status": "unknown_action"}

        conn.sendall(json.dumps(response).encode('utf-8'))
    except Exception as e:
        print(f"Handler Error: {e}")
    finally:
        conn.close()

def start_server():
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        s.bind((HOST, PORT))
        s.listen()
        print(f"Laptop Command Center active on port {PORT}...")
        while True:
            conn, addr = s.accept()
            threading.Thread(target=handle_client, args=(conn, addr)).start()

if __name__ == "__main__":
    start_server()