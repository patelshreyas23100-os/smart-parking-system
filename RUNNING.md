# How to Run Park Smart (Admin Panel & Mobile App)

Follow these steps to run the complete system on your laptop.

## 1. Backend & Admin Panel (FASTAPI)
The backend must be running for the App and Admin Panel to work.

### Steps:
1.  **Open Terminal** in the root folder: `C:\flutter_smart_park`
2.  **Run the Server**:
    ```powershell
    python -m backend.main
    ```
3.  **Access Admin Panel**:
    Once the server is running, open this link in your browser:
    👉 [http://127.0.0.1:8001/admin/index.html](http://127.0.0.1:8001/admin/index.html)

---

## 2. Mobile Application (FLUTTER)
You can run the app in the android emulator or on your phone.

### Steps:
1.  **Open Terminal** in the `app` folder:
    ```powershell
    cd C:\flutter_smart_park\app
    ```
2.  **Run the Application**:
    ```powershell
    flutter run
    ```

---

## 💡 Important Tips:
- **Admin Login**: Admin credentials (usually `admin@parksmart.com` / `admin123`).
- **Backend Error?**: If you see "ModuleNotFoundError", make sure you are in the root `C:\flutter_smart_park` folder before running the server.
- **Physical Phone**: If running on a real phone, remember to change the `baseUrl` in `app/lib/services/api_service.dart` to your Laptop's IP (e.g., `192.168.x.x`).


##  cd C:\flutter_smart_park   ## python -m backend.main

## uvicorn backend.main:app --reload --port 8001

## cd C:\flutter_smart_park/app
## flutter run

##  Terminal 2: ngrok Chalu Karein
Ab ek naya (second) terminal kholein.
Wahan ngrok folder mein jayein.
Aur ye command run karein:
 ## ngrok http 8001

 ## flutter build apk --release


## flutter run -d windows


I have moved everything to a safe location for you:
👉 **`C:\flutter_smart_park`**

[//]: # (### To Run the Backend:)
[//]: # (1. Open Terminal.)
[//]: # (2. Type: cd C:\flutter_smart_park)
[//]: # (3. Type: python -m backend.main)

[//]: # (Run the Application: )
[//]: # (### To Run the Windows App &#40;Fixed&#41;:)
[//]: # (1. Open Terminal.) 
[//]: # (2. Type: cd C:\flutter_smart_park\app)
[//]: # (3. Type: flutter clean)
[//]: # (4. Type: **flutter run -d windows**)


http://127.0.0.1:8001/admin/index.html

python -m uvicorn backend.main:app --reload --port 8001



cd C:\flutter_smart_park\flutter_smart_park
python -m uvicorn backend.main:app --reload --port 8001


cd C:\flutter_smart_park\flutter_smart_park\app
    flutter clean
flutter run -d windows
