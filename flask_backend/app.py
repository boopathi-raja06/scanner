from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import os
import re
from reportlab.lib.pagesizes import letter
from reportlab.pdfgen import canvas
from vulnerabilities.sql_injection import test_sql_injection
from vulnerabilities.xss import test_xss
from vulnerabilities.csrf import test_csrf
from vulnerabilities.open_redirect import test_open_redirect
from vulnerabilities.security_headers import test_security_headers

app = Flask(__name__)
CORS(app)

def sanitize_filename(url):
    filename = url.replace('http://', '').replace('https://', '').replace('/', '_')
    filename = re.sub(r'[<>:"/\\|?*]', '_', filename)  # Remove invalid characters
    return filename

def generate_pdf_report(results, url):
    filename = f"scan_report_{sanitize_filename(url)}.pdf"
    filepath = os.path.join("reports", filename)

    os.makedirs("reports", exist_ok=True)
    c = canvas.Canvas(filepath, pagesize=letter)
    c.drawString(100, 750, f"Web Vulnerability Scan Report for {url}")
    c.drawString(100, 730, "-" * 50)

    y_position = 710
    for test, result in results.items():
        c.drawString(100, y_position, f"{test.upper()}:")
        y_position -= 20

        if isinstance(result, dict) and "results" in result:
            for item in result["results"]:
                c.drawString(120, y_position, f"Payload: {item['payload']}, Vulnerable: {item['vulnerable']}")
                y_position -= 20
        else:
            c.drawString(120, y_position, str(result))
            y_position -= 20

    c.save()
    return filepath

@app.route('/scan', methods=['POST'])
def scan():
    data = request.json
    url = data.get('url')

    if not url:
        return jsonify({"error": "URL is required"}), 400

    # Perform vulnerability tests
    sql_injection_result = test_sql_injection(url)
    xss_result = test_xss(url)
    csrf_result = test_csrf(url)
    open_redirect_result = test_open_redirect(url)
    security_headers_result = test_security_headers(url)

    results = {
        "sql_injection": sql_injection_result,
        "xss": xss_result,
        "csrf": csrf_result,
        "open_redirect": open_redirect_result,
        "security_headers": security_headers_result
    }

    pdf_path = generate_pdf_report(results, url)
    response = {"results": results, "download_link": f"/download/{os.path.basename(pdf_path)}"}
    return jsonify(response)

@app.route('/download/<filename>', methods=['GET'])
def download_file(filename):
    filepath = os.path.join("reports", filename)
    if os.path.exists(filepath):
        return send_file(filepath, as_attachment=True)
    return jsonify({"error": "File not found"}), 404

if __name__ == '__main__':
    app.run(debug=True)
