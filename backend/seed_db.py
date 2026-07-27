from .database import SessionLocal, engine, Base
from . import models

def init_db():
    # Create tables
    models.Base.metadata.create_all(bind=engine)
    
    db = SessionLocal()
    
    # Check if we already have slots
    if db.query(models.ParkingSlot).first():
        db.close()
        return

    # Create dummy parking slots
    slots = []
    
    # 2 Wheelers (A1-A10)
    for i in range(1, 11):
        slots.append(models.ParkingSlot(
            slot_number=f"A{i}",
            type="Two-Wheeler",
            price_per_hour=100.0,
            is_available=True
        ))
        
    # 4 Wheelers (B1-B10)
    for i in range(1, 11):
        slots.append(models.ParkingSlot(
            slot_number=f"B{i}",
            type="Four-Wheeler",
            price_per_hour=250.0,
            is_available=True
        ))
        
    db.add_all(slots)
    db.commit()
    db.close()

if __name__ == "__main__":
    init_db()
