from flask import Flask, render_template
from flask_socketio import SocketIO, emit

app = Flask(__name__)
socketio = SocketIO(app, async_mode='threading', cors_allowed_origins='*')

@app.route('/')
def home():
    return render_template('dashboard.html') 

@socketio.on('video_frame')
def handle_video(data):
    try:
        emit('dashboard_video', data, broadcast=True)
    except Exception as e:
        print(f"Relay Error: {e}")

if __name__ == '__main__':
    socketio.run(app, host='0.0.0.0', port=8000, ssl_context='adhoc')