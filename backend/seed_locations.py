import sqlite3
import random

def seed_locations():
    conn = sqlite3.connect('flutter_smart_park/park_smart.db')
    cursor = conn.cursor()
    
    locations = ["Mall", "Office", "Theater", "Hotel", "Market", "Airport"]
    
    cursor.execute("SELECT id FROM parking_slots")
    slots = cursor.fetchall()
    
    for slot_id in slots:
        loc = random.choice(locations)
        cursor.execute("UPDATE parking_slots SET location = ? WHERE id = ?", (loc, slot_id[0]))
    
    conn.commit()
    print(f"Updated {len(slots)} slots with random locations.")
    conn.close()

if __name__ == "__main__":
    seed_locations()
