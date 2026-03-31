import requests

# ----------------------------
# Step 1: Register a new user
# ----------------------------
register_url = "http://127.0.0.1:8000/api/users/register/"
register_data = {
    "username": "catlover",
    "email": "catlover@example.com",
    "password": "mypassword123"
}

reg_response = requests.post(register_url, json=register_data)
print("=== Registration ===")
print("Status code:", reg_response.status_code)
print("Response JSON:", reg_response.json())

# ----------------------------
# Step 2: Login to get JWT
# ----------------------------
login_url = "http://127.0.0.1:8000/api/auth/token/"
login_data = {
    "username": "catlover",
    "password": "mypassword123"
}

login_response = requests.post(login_url, json=login_data)
print("\n=== Login ===")
print("Status code:", login_response.status_code)
login_json = login_response.json()
print("Response JSON:", login_json)

if "access" not in login_json:
    print("\nLogin failed. Exiting script.")
    exit()

access_token = login_json["access"]

# ----------------------------
# Step 3: Access protected endpoint
# ----------------------------
protected_url = "http://127.0.0.1:8000/api/users/users/"
headers = {"Authorization": f"Bearer {access_token}"}

protected_response = requests.get(protected_url, headers=headers)
print("\n=== Access Protected Endpoint ===")
print("Status code:", protected_response.status_code)
print("Response JSON:", protected_response.json())
