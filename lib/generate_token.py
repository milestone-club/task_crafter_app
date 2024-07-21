import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
from urllib.parse import urlencode
import requests
import google.auth
from google.oauth2 import service_account
import google.auth.transport.requests

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Parse the query parameters
        query_components = parse_qs(urlparse(self.path).query)

        # Example endpoint to generate and return access token
        if self.path.startswith("/getAccessToken"):
            access_token = self.generate_access_token()

            # Respond with the access token
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'access_token': access_token}).encode())

    def generate_access_token(self):
        # Load your service account credentials
        service_account_file=r'C:\Users\skhas\Downloads\taskcrafter-a7c64-firebase-adminsdk-8oh61-327e0dac3f.json'
        with open(service_account_file) as f:
            credentials_info = json.load(f)
        credentials = service_account.Credentials.from_service_account_info(
            credentials_info,
            scopes=['https://www.googleapis.com/auth/firebase.messaging']
        )

        # Request an access token
        request = google.auth.transport.requests.Request()
        credentials.refresh(request)
        access_token = credentials.token

        return access_token

def run(server_class=HTTPServer, handler_class=RequestHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f'Starting server on port {port}...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()
