from .database import SessionLocal, engine
from . import models

def seed_ahmedabad_data():
    db = SessionLocal()
    try:
        # 0. Clear existing data to ensure clean state
        db.query(models.ParkingSlot).delete()
        db.query(models.ParkingLocation).delete()
        db.commit()

        # 1. Define Parking Locations (Hubs)
        locations_data = [
            {"name": "Palladium Mall Parking", "area": "Thaltej", "latitude": 23.0410, "longitude": 72.5312},
            {"name": "Gota Cross Road Parking", "area": "Gota", "latitude": 23.1064, "longitude": 72.5414},
            {"name": "Satellite Hub Parking", "area": "Satellite", "latitude": 23.0305, "longitude": 72.5181},
            {"name": "SG Highway Public Parking", "area": "SG Highway", "latitude": 23.0232, "longitude": 72.5074},
            {"name": "Navrangpura Multi-level Parking", "area": "Navrangpura", "latitude": 23.0333, "longitude": 72.5594},
            {"name": "Maninagar Railway Parking", "area": "Maninagar", "latitude": 22.9972, "longitude": 72.6111},
            {"name": "Thaltej Parking Hub", "area": "Thaltej", "latitude": 23.0450, "longitude": 72.5280},
            {"name": "Iskcon Cross Road Parking", "area": "SG Highway", "latitude": 23.0250, "longitude": 72.5080},
            {"name": "Gota Bus Stand Parking", "area": "Gota", "latitude": 23.1080, "longitude": 72.5430},
            {"name": "Paldi Cross Road Parking", "area": "Paldi", "latitude": 23.0110, "longitude": 72.5620},
        ]

        locations = []
        for loc_data in locations_data:
            loc = models.ParkingLocation(**loc_data)
            db.add(loc)
            db.flush() # To get ID
            locations.append(loc)

        db.commit()

        # 2. Add Exactly 20 slots to these locations
        for loc in locations:
            types = ["Two-Wheeler", "Four-Wheeler"]
            for v_type in types:
                prefix = "T" if v_type == "Two-Wheeler" else "F"
                short_name = loc.name[:3].upper()
                for i in range(1, 11): # Exactly 10 slots of each type per location
                    slot_num = f"{short_name}{loc.id}-{prefix}-{i}"
                    new_slot = models.ParkingSlot(
                        slot_number=slot_num,
                        type=v_type,
                        location=loc.name, # Backward compatibility
                        location_id=loc.id,
                        price_per_hour=20.0 if v_type == "Two-Wheeler" else 50.0,
                        is_available=True
                    )
                    db.add(new_slot)
        
        db.commit()
        print("Successfully seeded Ahmedabad parking locations and slots.")
    except Exception as e:
        print(f"Error seeding data: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    seed_ahmedabad_data()
