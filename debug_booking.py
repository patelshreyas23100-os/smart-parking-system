import requests
import json

BASE_URL = "http://127.0.0.1:8001"

def debug():
    # 1. Login
    login_res = requests.post(f"{BASE_URL}/login", json={"email": "gunjanpatel266@gmail.com", "password": "Gunjan@123"})
    if login_res.status_code != 200:
        print(f"Login failed: {login_res.text}")
        return
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    print("Logged in successfully.")

    # 2. Get Palladium slots
    slots_res = requests.get(f"{BASE_URL}/slots/?location_id=1&type=Four-Wheeler", headers=headers)
    slots = slots_res.json()
    if not slots:
        print("No slots found for Palladium.")
        return
    slot = slots[0]
    print(f"Found slot: {slot['slot_number']} (ID: {slot['id']})")

    # 3. Get Vehicles
    vehicles_res = requests.get(f"{BASE_URL}/vehicles/", headers=headers)
    vehicles = vehicles_res.json()
    if not vehicles:
        print("No vehicles found.")
        return
    vehicle = [v for v in vehicles if v['type'] == 'Four-Wheeler'][0]
    print(f"Using vehicle: {vehicle['plate_number']} (ID: {vehicle['id']})")

    # 4. Attempt Booking
    from datetime import datetime, timedelta
    start = datetime.now() + timedelta(minutes=10)
    end = start + timedelta(hours=1)
    
    booking_data = {
        "slot_id": slot["id"],
        "vehicle_id": vehicle["id"],
        "start_time": start.isoformat(),
        "end_time": end.isoformat(),
        "payment_method": "Cash"
    }
    
    print(f"Attempting booking: {booking_data}")
    res = requests.post(f"{BASE_URL}/bookings/", json=booking_data, headers=headers)
    
    if res.status_code == 200:
        print(f"Booking successful! ID: {res.json()['id']}")
    else:
        print(f"Booking failed! Status: {res.status_code}, Detail: {res.text}")

if __name__ == "__main__":
    debug()
