import sqlite3
import os

def migrate():
    db_path = 'park_smart.db'
    if not os.path.exists(db_path):
        # Check if it's in the flutter_smart_park folder
        db_path = 'flutter_smart_park/park_smart.db'
    
    if not os.path.exists(db_path):
        print(f"Database not found at {db_path}")
        return

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 1. Create parking_locations table if it doesn't exist
        cursor.execute("""
        CREATE TABLE IF NOT EXISTS parking_locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name VARCHAR,
            area VARCHAR,
            latitude FLOAT,
            longitude FLOAT
        )
        """)
        print("Ensured parking_locations table exists.")

        # 2. Add location_id to parking_slots
        cursor.execute("PRAGMA table_info(parking_slots)")
        columns = [info[1] for info in cursor.fetchall()]
        
        if 'location_id' not in columns:
            cursor.execute("ALTER TABLE parking_slots ADD COLUMN location_id INTEGER REFERENCES parking_locations(id)")
            print("Added location_id column to parking_slots.")
        else:
            print("location_id column already exists.")
            
        conn.commit()
        print("Migration successful.")
    except Exception as e:
        print(f"Migration error: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    migrate()
