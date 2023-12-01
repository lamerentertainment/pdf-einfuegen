import requests
import json

url = "http://localhost:8000/api/v1/transform_text"
weburl = "https://courtapi.applikuapp.com/api/v1/transform_text"
payload = {
    "text": """Lange herrschte in Kreisen der Strafverfolger die Über- zeugung, dass sich junge Vernehmungsbeamte die entspre- chenden Kompetenzen bei erfahrenen Kollegen abgucken könnten. Die Überlegung war, dass Erfahrung als Schulungs- voraussetzung genüge und dass sich entsprechende Fähig- keiten nur in realen Situationen erwerben liessen.""",
    "geschlecht": "m",
}

# Convert payload to JSON
json_payload = json.dumps(payload)

# Set the Content-Type header to indicate JSON data
headers = {'Content-Type': 'application/json'}

# Send the POST request
response = requests.post(weburl, data=json_payload, headers=headers)

# Print the response
print(response.json())