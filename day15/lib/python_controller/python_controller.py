import asyncio
import json
from pynput.mouse import Controller, Button
import websockets

class GyroMouseController:
    def __init__(self):
        self.mouse = Controller()
        
        # Configuration for how your gyroscope works,
        self.sensitivity = 230
        self.deadzone = 0.25
        
        # Momentum factor (0.0 to 1.0). Higher = more "slide" / smoother. Lower = more responsive.
        self.momentum = 0.70
        self.update_rate = 0.01  # 10ms loop (100Hz) for smooth rendering

        # State
        self.target_vx = 0.0
        self.target_vy = 0.0
        self.current_vx = 0.0
        self.current_vy = 0.0
        self.running = True

    async def start(self):
        asyncio.create_task(self.movement_loop())
        
        print("Gyro mouse server running on 0.0.0.0:8765...")
        async with websockets.serve(self.handler, "0.0.0.0", 8765):
            await asyncio.Future()  # Keep running

    async def movement_loop(self):
        while self.running:
            #  formula for calculate the movement with momentum w.r.t target velocity
            self.current_vx = (self.current_vx * self.momentum) + (self.target_vx * (1 - self.momentum))
            self.current_vy = (self.current_vy * self.momentum) + (self.target_vy * (1 - self.momentum))

            # avoiding small steps
            if abs(self.current_vx) < 0.1: self.current_vx = 0
            if abs(self.current_vy) < 0.1: self.current_vy = 0

            # only move if there is any velocity
            if self.current_vx != 0 or self.current_vy != 0:
                self.mouse.move(self.current_vx, self.current_vy)

            await asyncio.sleep(self.update_rate)

    async def handler(self, websocket):
        print(f"New connection from {websocket.remote_address}") #prints ip of connected device
        try:
            async for message in websocket:
                data = json.loads(message)

                # Handle Clicks
                if 'action' in data and data['action'] == 'click':
                    btn = Button.left if data['button'] == 'left' else Button.right
                    self.mouse.click(btn)
                    print(f"{data['button']} click")
                    continue

                # Handle Stop Command
                if 'action' in data and data['action'] == 'stop':
                    self.target_vx = 0
                    self.target_vy = 0
                    self.current_vx = 0
                    self.current_vy = 0
                    print("Movement stopped")
                    continue

                # Handle Touch Movement
                if 'action' in data and data['action'] == 'move':
                    scale = 7.0 #change this for mouse speed
                    self.mouse.move(data['dx'] * scale, data['dy'] * scale)
                    continue

                # Handle Gyro Movement
                if 'gx' not in data: continue

                gx = data['gx']
                gy = data['gy']

                # Apply Deadzone
                if abs(gx) < self.deadzone: gx = 0
                if abs(gy) < self.deadzone: gy = 0

                # Calculate Target Velocity
                speed_multiplier = self.sensitivity * 0.2
                
                self.target_vx = gy * speed_multiplier
                self.target_vy = -gx * speed_multiplier

        except Exception as e:
            print(f"Connection closed: {e}")
            # Stop movement on disconnect
            self.target_vx = 0
            self.target_vy = 0

if __name__ == "__main__":
    controller = GyroMouseController()
    try:
        asyncio.run(controller.start())
    except KeyboardInterrupt:
        print("\nStopping server...")

