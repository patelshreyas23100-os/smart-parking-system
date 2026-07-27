import sqlite3

def migrate():
    try:
        conn = sqlite3.connect('C:/flutter_smart_park/backend/park_smart.db')
        cursor = conn.cursor()
        
        # Check if columns already exist before adding
        cursor.execute("PRAGMA table_info(users)")
        columns = [info[1] for info in cursor.fetchall()]
        
        if 'reset_otp' not in columns:
            cursor.execute("ALTER TABLE users ADD COLUMN reset_otp VARCHAR")
            print("Added reset_otp column.")
        else:
            print("reset_otp column already exists.")
            
        if 'reset_otp_expiry' not in columns:
            cursor.execute("ALTER TABLE users ADD COLUMN reset_otp_expiry DATETIME")
            print("Added reset_otp_expiry column.")
        else:
            print("reset_otp_expiry column already exists.")
            
        conn.commit()
        print("Migration successful - missing columns added.")
    except Exception as e:
        print(f"Migration error: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    migrate()
