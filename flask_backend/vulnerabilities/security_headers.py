import requests

def test_security_headers(url):
    try:
        response = requests.get(url)
        missing_headers = []

        required_headers = [
            "Content-Security-Policy",
            "Strict-Transport-Security",
            "X-Content-Type-Options",
            "X-Frame-Options",
        ]

        for header in required_headers:
            if header not in response.headers:
                missing_headers.append(header)

        return {"missing_headers": missing_headers, "vulnerable": len(missing_headers) > 0}
    except Exception as e:
        return {"error": f"Error testing Security Headers: {str(e)}"}
