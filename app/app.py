from flask import Flask, render_template
import socket
import datetime
import os

app = Flask(__name__)

@app.route('/')
def home():
    hostname = socket.gethostname()
    server_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    environment = os.getenv("APP_ENV", "Production")
    return render_template(
        'index.html',
        hostname=hostname,
        server_time=server_time,
        environment=environment
    )

@app.route('/health')
def health():
    return {"status": "UP", "service": "Flask-DevOps-Demo"}, 200

if __name__ == '__main__':
    # Listen on port 80 (or 5000 if not root)
    port = int(os.getenv("PORT", 80))
    app.run(host='0.0.0.0', port=port)
