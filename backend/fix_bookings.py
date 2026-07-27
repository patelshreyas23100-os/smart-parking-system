import sqlite3
import datetime

def fix_bookings():
    conn = sqlite3.connect('park_smart.db')
    cursor = conn.cursor()
    
    # 1. Find bookings with negative or zero total_price
    cursor.execute("SELECT id, start_time, end_time, total_price, user_id FROM bookings WHERE total_price <= 0")
    bad_bookings = cursor.fetchall()
    
    print(f"Found {len(bad_bookings)} suspicious bookings.")
    
    for b_id, start, end, price, u_id in bad_bookings:
        # Example fix: If it's the specific booking we saw (-2150.0 for user 2)
        # Let's assume a default fix or recalculate if possible
        # For simplicity, if price is negative, let's set it to a minimum of 100 or recalculate properly
        
        # Recalculate duration
        try:
            s_dt = datetime.datetime.fromisoformat(start.replace('Z', ''))
            e_dt = datetime.datetime.fromisoformat(end.replace('Z', ''))
            
            # If end is before start, it's likely a day wrap bug
            if e_dt <= s_dt:
                e_dt += datetime.timedelta(days=1)
            
            duration = e_dt - s_dt
            hours = duration.total_seconds() / 3600
            
            # We don't have the slot price here easily, so let's check slot_id
            cursor.execute("SELECT price_per_hour FROM parking_slots JOIN bookings ON parking_slots.id = bookings.slot_id WHERE bookings.id = ?", (b_id,))
            slot_price = cursor.fetchone()
            pph = slot_price[0] if slot_price else 100.0
            
            new_price = hours * pph
            
            print(f"Fixing booking {b_id}: {price} -> {new_price} (Duration: {hours}h)")
            cursor.execute("UPDATE bookings SET total_price = ?, end_time = ? WHERE id = ?", (new_price, e_dt.isoformat(), b_id))
            
            # If it was a wallet transaction (not tracked yet but for future)
            # or if we want to "refund" the user if we deducred wrong
            # User 2 'omdeep' had the -2150. Since it was negative, they actually "gained" balance if it was a deduction system.
            # But since we just added the wallet, we'll just correct the history.
            
        except Exception as e:
            print(f"Error fixing booking {b_id}: {e}")

    conn.commit()
    conn.close()
    print("Corrections complete.")

if __name__ == "__main__":
    fix_bookings()
