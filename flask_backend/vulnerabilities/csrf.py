import requests

def test_csrf(url):
    try:
        response = requests.get(url)
        if "csrf" not in response.text.lower() and "authenticity_token" not in response.text.lower():
            return {"vulnerable": True, "reason": "No CSRF token detected in form submission."}
        else:
            return {"vulnerable": False}
    except Exception as e:
        return {"error": f"Error testing CSRF: {str(e)}"}
