# Park Smart Project - Full Process Guide
(Ye file aapki Mam ko project samjane mein madad karegi)

Hi! Is file mein humne step-by-step likha hai ki ye application kaise bani hai, isme kaunsi technology use hui hai, aur ise live kaise karte hain.

---

## 1. Technologies Used (Kisme banaya hai?)

Is project ko humne teen main parts mein divide kiya hai:

1.  **Frontend (Mobile App):** Banaya hai **Flutter (Dart)** mein.
2.  **Admin Panel (Web Dashboard):** Banaya hai **HTML, CSS, aur Vanilla JavaScript** mein. Ye ek simple aur powerful web interface hai.
3.  **Backend (Server):** Banaya hai **FastAPI (Python)** mein. Ye APIs aur Admin Panel dono ko handle karta hai.
4.  **Database:** Humne **SQLite** use kiya hai.

---

## 2. Project Structure (Kaise banaya hai?)

Project do main folders mein split hai:
-   **`/app`**: Isme saara Flutter code hai (UI, Screens, Services).
-   **`/backend`**: Isme server ka logic hai.
-   **`/backend/static/admin`**: Isme Admin Panel ki saari files (HTML/CSS/JS) hain.

### Core Logic:
-   User App se booking karta hai.
-   Admin Panel se admin saari bookings ko real-time mein dekh sakta hai.
-   Backend FastAPI dono requests ko process karta hai aur Database se communicate karta hai.

---

## 3. Live Kaise Karein? (ngrok Process)

Backend ko internet par live karne ke liye (taki aap apne phone se app chala sakein), humne **ngrok** use kiya hai.

### Steps:
1.  **Backend Start Karein**:
    -   Terminal mein jayein: `cd C:\flutter_smart_park`
    -   Run karein: `python -m backend.main` (Server porta 8001 par chalta hai).
2.  **ngrok Live Karein**:
    -   Naya terminal kholein aur ngrok folder mein jayein.
    -   Command run karein: `ngrok http 8001`
    -   Wahan ek URL milega (e.g., `https://random-id.ngrok-free.app`).
3.  **App Connect Karein**:
    -   Is URL ko `app/lib/services/api_service.dart` mein `baseUrl` ki jagah daal dein.
    -   Ab aapki app internet ke zariye server se connect ho jayegi.

---

## 4. How to Generate Mobile App (APK)?

Agar aapko Mam ko app install karke dikhani hai:
1.  Terminal mein `app` folder mein jayein.
2.  Run karein: `flutter build apk --release`
3.  Build hone ke baad APK file yahan milegi:
    `build/app/outputs/flutter-apk/app-release.apk`

---

## 5. Main Features
-   **Dashboard**: Sunder UI jahan Mall, Office, aur Hospital categories hain.
-   **Real-time Booking**: Slot select karke time set karna.
-   **Vehicle Management**: Apni gaadi add/remove karna.
-   **Admin Panel**: Sabhi bookings ko monitor karne ke liye web-based dashboard.

---

**Tip for Mam**: "Mam, humne modern stack (FastAPI + Flutter) use kiya hai jo scalable hai aur ngrok ke through humne ise cloud environment mein test kiya hai."
