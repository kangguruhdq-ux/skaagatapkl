import http.server
import socketserver
import os
import threading

DIRECTORY = os.path.join(os.path.dirname(__file__), "build", "web")

class NoCacheHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.send_header("Clear-Site-Data", '"cache"')
        self.send_header("Access-Control-Allow-Origin", "*")
        super().end_headers()

def serve_on_port(port):
    socketserver.TCPServer.allow_reuse_address = True
    try:
        with socketserver.TCPServer(("", port), NoCacheHTTPRequestHandler) as httpd:
            print(f"Serving Flutter Web at http://localhost:{port} from {DIRECTORY}")
            httpd.serve_forever()
    except Exception as e:
        print(f"Error on port {port}: {e}")

if __name__ == "__main__":
    t = threading.Thread(target=serve_on_port, args=(3001,), daemon=True)
    t.start()
    serve_on_port(3000)
