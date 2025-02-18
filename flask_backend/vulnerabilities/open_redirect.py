import requests

def test_open_redirect(url):
    payloads = [
        "/redirect?url=http://malicious.com",
        "/?next=http://malicious.com",
        "/?redirect=http://malicious.com",
    ]

    results = []

    for payload in payloads:
        try:
            full_url = url + payload
            response = requests.get(full_url, allow_redirects=False)
            if response.status_code in [301, 302] and "malicious.com" in response.headers.get("Location", ""):
                results.append({"payload": payload, "vulnerable": True})
            else:
                results.append({"payload": payload, "vulnerable": False})
        except Exception as e:
            return {"error": f"Error testing Open Redirect: {str(e)}"}

    return {"results": results}
