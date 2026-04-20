import requests
import json

# ========================================================
# SETTINGS
# ========================================================
BASE_URL = "https://campus-placement-app-production.up.railway.app"
TEST_USERNAME = "admin"  # Replace with a valid username from your database

def test_landing_page():
    print(f"--- Testing Landing Page: {BASE_URL} ---")
    try:
        res = requests.get(BASE_URL)
        print(f"Status Code: {res.statusCode if hasattr(res, 'statusCode') else res.status_code}")
        if res.status_code == 200:
            print("✅ Landing Page is UP")
        else:
            print(f"❌ Landing Page returned error: {res.status_code}")
    except Exception as e:
        print(f"❌ Connection Failed: {e}")
    print("\n")

def test_otp_api():
    print(f"--- Testing Forgot Password API for user: {TEST_USERNAME} ---")
    url = f"{BASE_URL}/api/forgot-password/"
    payload = {"username": TEST_USERNAME}
    
    try:
        res = requests.post(url, json=payload)
        print(f"Status Code: {res.status_code}")
        print(f"Response: {res.text}")
        
        if res.status_code == 200:
            print("✅ API accepted the request! Check your email.")
        elif res.status_code == 404:
            print("❌ User not found in database.")
        elif res.status_code == 400:
            print("❌ Input error (likely missing email in DB).")
        elif res.status_code == 500:
            print("❌ Server error (likely Gmail SMTP configuration).")
            
    except Exception as e:
        print(f"❌ API Connection Failed: {e}")
    print("\n")

if __name__ == "__main__":
    test_landing_page()
    test_otp_api()
