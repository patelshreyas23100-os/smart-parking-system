from fastapi import FastAPI, Depends, HTTPException, status
import uvicorn
import random
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), '..', '.env'))

from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone, timedelta
from . import models, schemas, auth, database
from .database import engine
try:
    # Add root to sys.path to ensure absolute imports work
    import sys
    sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
    from ai_engine.deploy_ai import ParkingAI
    
    model_path = os.path.join(os.path.dirname(__file__), '..', 'ai_engine', 'models', 'ppo_smart_parking')
    parking_ai = ParkingAI(model_path)
    print(f"AI Engine Loaded successfully from {model_path}")
except Exception as e:
    print(f"AI Engine Load Error: {e}")
    parking_ai = None

def get_now():
    # Use UTC for all logic and storage
    return datetime.now(timezone.utc).replace(tzinfo=None)

# Create the database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="Park Smart API")

# Setup CORS

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, replace with specific frontend origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def init_slots():
    db = database.SessionLocal()
    try:
        # Map locations to unique 3-letter prefixes
        loc_prefixes = {
            "Mall": "MAL",
            "Office": "OFF",
            "Theater": "THE",
            "Hotel": "HOT",
            "Market": "MAR"
        }
        types = ["Two-Wheeler", "Four-Wheeler"]
        
        for loc, prefix_code in loc_prefixes.items():
            for v_type in types:
                prefix = "T" if v_type == "Two-Wheeler" else "F"
                # Check for our specific naming pattern to count correctly
                pattern = f"{prefix_code}-{prefix}-%"
                current_slots = db.query(models.ParkingSlot).filter(
                    models.ParkingSlot.slot_number.like(pattern)
                ).all()
                
                count = len(current_slots)
                
                # Add slots if less than 10
                for i in range(count, 10):
                    index = i + 1
                    while True:
                        slot_num = f"{prefix_code}-{prefix}-{index}"
                        existing = db.query(models.ParkingSlot).filter(models.ParkingSlot.slot_number == slot_num).first()
                        if not existing:
                            break
                        index += 1
                    
                    new_slot = models.ParkingSlot(
                        slot_number=slot_num,
                        type=v_type,
                        location=loc,
                        price_per_hour=20.0 if v_type == "Two-Wheeler" else 50.0,
                        is_available=True
                    )
                    db.add(new_slot)
        db.commit()
    except Exception as e:
        print(f"Error initializing slots: {e}")
    finally:
        db.close()

# Run initialization
init_slots()

def init_plans():
    db = database.SessionLocal()
    try:
        plans = [
            {"name": "Two-Wheeler Monthly Pass", "vehicle_type": "Two-Wheeler", "duration_days": 30, "price": 400.0},
            {"name": "Four-Wheeler Monthly Pass", "vehicle_type": "Four-Wheeler", "duration_days": 30, "price": 1000.0}
        ]
        for p in plans:
            existing = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.name == p["name"]).first()
            if not existing:
                new_plan = models.SubscriptionPlan(**p)
                db.add(new_plan)
        db.commit()
    except Exception as e:
        print(f"Error initializing plans: {e}")
    finally:
        db.close()

init_plans()

def init_ahmedabad():
    try:
        from .seed_ahmedabad_data import seed_ahmedabad_data
        seed_ahmedabad_data()
    except ImportError:
        print("seed_ahmedabad_data.py not found or import error")

init_ahmedabad()

@app.post("/signup", response_model=schemas.User)
def signup(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
        
    import re
    if len(user.password) < 8 or not re.search(r'[!@#\$&*~%]', user.password):
        raise HTTPException(status_code=400, detail="Password must be at least 8 chars and contain a special character")
        
    if user.licence_no:
        if not re.match(r'^[A-Za-z]{2}[ -]?[0-9]{2}[ -]?[0-9]{4}[ -]?[0-9]{7}$', user.licence_no):
            raise HTTPException(status_code=400, detail="Invalid Driving Licence Format (e.g. GJ0120230000000)")

    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(
        email=user.email,
        name=user.name,
        phone=user.phone,
        licence_no=user.licence_no,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@app.post("/auth/request-otp")
def request_otp(req: schemas.OTPRequest, db: Session = Depends(database.get_db)):
    # Check if user exists based on type
    user = db.query(models.User).filter(models.User.email == req.email).first()
    
    if req.type == "signup" and user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    if req.type == "login" and not user:
        raise HTTPException(status_code=404, detail="User not found. Please register.")

    otp = str(random.randint(100000, 999999))
    expiry = get_now() + timedelta(minutes=10)
    
    # Upsert into PendingOTP
    pending = db.query(models.PendingOTP).filter(models.PendingOTP.email == req.email).first()
    if pending:
        pending.otp = otp
        pending.expiry = expiry
    else:
        pending = models.PendingOTP(email=req.email, otp=otp, expiry=expiry)
        db.add(pending)
    
    db.commit()
    auth.send_otp_email(req.email, otp)
    print(f"DEBUG: OTP for {req.email} is {otp}")
    
    return {"message": "OTP sent successfully", "debug_otp": otp}

@app.post("/login-otp", response_model=schemas.Token)
def login_otp(data: schemas.OTPVerify, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found. Please register.")
    
    # Check PendingOTP
    pending = db.query(models.PendingOTP).filter(models.PendingOTP.email == data.email).first()
    if not pending or pending.otp != data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if pending.expiry < get_now():
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    # Clear PendingOTP
    db.delete(pending)
    db.commit()
    
    # Optional Password Verification (2FA flow)
    if data.password:
        if not auth.verify_password(data.password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Invalid password")
    
    access_token = auth.create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/signup-otp", response_model=schemas.AuthResponse)
def signup_otp(user_data: schemas.UserSignupWithOTP, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.email == user_data.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    # Check PendingOTP
    pending = db.query(models.PendingOTP).filter(models.PendingOTP.email == user_data.email).first()
    if not pending or pending.otp != user_data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if pending.expiry < get_now():
        raise HTTPException(status_code=400, detail="OTP has expired")
    
    hashed_password = auth.get_password_hash(user_data.password)
    new_user = models.User(
        email=user_data.email,
        name=user_data.name,
        phone=user_data.phone,
        licence_no=user_data.licence_no,
        hashed_password=hashed_password
    )
    db.add(new_user)
    db.delete(pending)
    db.commit()
    db.refresh(new_user)
    
    # Generate access token immediately after signup
    access_token = auth.create_access_token(data={"sub": new_user.email})
    return {
        "user": new_user,
        "token": {"access_token": access_token, "token_type": "bearer"}
    }

@app.post("/auth/forgot-password")
def forgot_password(req: schemas.ForgotPasswordRequest, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == req.email).first()
    if not user:
        return {"message": "If that email is registered, we have sent an OTP."}
        
    otp = str(random.randint(100000, 999999))
    user.reset_otp = otp
    user.reset_otp_expiry = get_now() + timedelta(minutes=15)
    db.commit()
    
    auth.send_otp_email(user.email, otp)
    
    return {"message": "If that email is registered, we have sent an OTP."}

@app.post("/auth/verify-otp")
def verify_otp(otp_data: schemas.OTPVerify, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == otp_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if not user.reset_otp or user.reset_otp != otp_data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if not user.reset_otp_expiry or get_now() > user.reset_otp_expiry:
        raise HTTPException(status_code=400, detail="OTP has expired")
        
    return {"message": "OTP verified successfully"}

@app.post("/auth/reset-password")
def reset_password(reset_data: schemas.UserPasswordReset, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == reset_data.email).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if not user.reset_otp or user.reset_otp != reset_data.otp:
        raise HTTPException(status_code=400, detail="Invalid OTP")
        
    if not user.reset_otp_expiry or get_now() > user.reset_otp_expiry:
        raise HTTPException(status_code=400, detail="OTP has expired")
        
    import re
    if len(reset_data.new_password) < 8 or not re.search(r'[!@#\$&*~%]', reset_data.new_password):
        raise HTTPException(status_code=400, detail="Password must be at least 8 chars and contain a special character")
        
    hashed_password = auth.get_password_hash(reset_data.new_password)
    user.hashed_password = hashed_password
    user.reset_otp = None
    user.reset_otp_expiry = None
    db.commit()
    
    return {"message": "Password updated successfully"}
@app.get("/users/me", response_model=schemas.User)
def read_users_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

def get_dynamic_price(slot, db: Session):
    """
    Calculate dynamic price for a slot based on AI model.
    """
    if not parking_ai:
        return slot.price_per_hour
        
    try:
        # 1. Get location stats
        loc = db.query(models.ParkingLocation).filter(models.ParkingLocation.id == slot.location_id).first()
        if not loc:
            return slot.price_per_hour
            
        # 2. Calculate occupancy for this location
        total_slots = db.query(models.ParkingSlot).filter(models.ParkingSlot.location_id == loc.id).count()
        occupied_slots = db.query(models.ParkingSlot).filter(
            models.ParkingSlot.location_id == loc.id,
            models.ParkingSlot.is_available == False
        ).count()
        
        occ_rate = occupied_slots / total_slots if total_slots > 0 else 0
        
        # 3. Get AI multiplier
        # For simplicity in this bridge, we use the specific zone's occupancy
        # and current hour for time
        now = datetime.now()
        current_time = now.hour / 24.0
        traffic = 0.4 # Placeholder for real-world traffic data
        
        # Use AI to get multipliers (passing list with one zone)
        multipliers = parking_ai.get_optimal_prices([occ_rate], current_time, traffic)
        multiplier = multipliers[0]
        
        # Add a tiny bit of random jitter (±2%) to make it look "alive" even at same occupancy
        jitter = 1.0 + (random.uniform(-0.02, 0.02))
        final_price = round(slot.price_per_hour * multiplier * jitter, 2)
        
        return final_price
    except Exception as e:
        print(f"Dynamic Pricing Error: {e}")
        return slot.price_per_hour

# Parking Slot Management
@app.get("/slots/", response_model=List[schemas.ParkingSlot])
def get_slots(type: str = None, location: str = None, location_id: int = None, db: Session = Depends(database.get_db)):
    check_expired_bookings(db)
    query = db.query(models.ParkingSlot)
    if type:
        query = query.filter(models.ParkingSlot.type == type)
    if location_id:
        query = query.filter(models.ParkingSlot.location_id == location_id)
    elif location:
        query = query.filter(models.ParkingSlot.location == location)
    slots = query.all()
    # Apply dynamic pricing
    for s in slots:
        s.price_per_hour = get_dynamic_price(s, db)
    return slots

@app.get("/locations/suggestions", response_model=List[schemas.LocationSuggestion])
def get_location_suggestions(q: str = "", db: Session = Depends(database.get_db)):
    # Common areas/malls in Ahmedabad
    general_places = [
        {"name": "Paldi Ahmedabad", "area": "Paldi", "type": "Area"},
        {"name": "Palladium Mall Ahmedabad", "area": "Thaltej", "type": "Mall"},
        {"name": "Alpha One Mall", "area": "Vastrapur", "type": "Mall"},
        {"name": "C.G. Road", "area": "Navrangpura", "type": "Commercial"},
        {"name": "Iskcon Temple", "area": "SG Highway", "type": "Landmark"},
        {"name": "Satellite Area", "area": "Satellite", "type": "Area"},
    ]

    if not q or len(q) < 1:
        return general_places[:5]
        
    suggestions = []
    
    # Search in Parking Locations (Hubs)
    locations = db.query(models.ParkingLocation).filter(
        (models.ParkingLocation.name.ilike(f"%{q}%")) | 
        (models.ParkingLocation.area.ilike(f"%{q}%"))
    ).all()
    
    for loc in locations:
        suggestions.append({
            "name": loc.name,
            "area": loc.area,
            "type": "Parking Hub"
        })
    
    # Filter general places based on query
    for place in general_places:
        if q.lower() in place["name"].lower() or q.lower() in place["area"].lower():
            # Avoid duplicates with actual hubs
            if not any(s["name"] == place["name"] for s in suggestions):
                suggestions.append(place)
                
    return suggestions[:5]

@app.get("/locations/nearby", response_model=List[schemas.ParkingLocation])
def get_nearby_parking(q: str, db: Session = Depends(database.get_db)):
    check_expired_bookings(db)
    # 1. Get all locations first
    all_locations = db.query(models.ParkingLocation).all()
    
    # 2. Find the reference location
    # Use the first word for better area matching (e.g., "Paldi Ahmedabad" -> "Paldi")
    search_term = q.split()[0] if q else ""
    search_query = f"%{search_term}%"
    
    primary_loc = db.query(models.ParkingLocation).filter(
        (models.ParkingLocation.name.ilike(search_query)) | 
        (models.ParkingLocation.area.ilike(search_query))
    ).first()
    
    results = []
    import math

    def haversine(lat1, lon1, lat2, lon2):
        R = 6371 # km
        dLat = math.radians(lat2 - lat1)
        dLon = math.radians(lon2 - lon1)
        a = math.sin(dLat/2) * math.sin(dLat/2) + \
            math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * \
            math.sin(dLon/2) * math.sin(dLon/2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c

    for loc in all_locations:
        # Calculate distance only if primary_loc exists
        dist = 0.0
        if primary_loc:
            dist = haversine(primary_loc.latitude, primary_loc.longitude, loc.latitude, loc.longitude)
        
        # Calculate slots
        total_slots = db.query(models.ParkingSlot).filter(models.ParkingSlot.location_id == loc.id).count()
        available_slots = db.query(models.ParkingSlot).filter(
            models.ParkingSlot.location_id == loc.id,
            models.ParkingSlot.is_available == True
        ).count()
        
        # Format distance string
        dist_str = f"{int(dist * 1000)}m" if dist < 1 else f"{dist:.1f}km"
        
        # Calculate dynamic price for this location
        # Find any slot for this location to get base price
        sample_slot = db.query(models.ParkingSlot).filter(models.ParkingSlot.location_id == loc.id).first()
        current_price = get_dynamic_price(sample_slot, db) if sample_slot else 20.0

        results.append({
            "id": loc.id,
            "name": loc.name,
            "area": loc.area,
            "latitude": loc.latitude,
            "longitude": loc.longitude,
            "total_slots": total_slots,
            "available_slots": available_slots,
            "distance": dist_str,
            "price_per_hour": current_price,
            "dist_val": dist # For sorting
        })
        
    # Sort by actual distance value
    results.sort(key=lambda x: x['dist_val'])
    
    # Remove helper field before returning
    for r in results:
        del r['dist_val']
                 
    return results

@app.post("/slots/", response_model=schemas.ParkingSlot)
def create_slot(slot: schemas.ParkingSlotBase, db: Session = Depends(database.get_db)):
    new_slot = models.ParkingSlot(**slot.dict())
    db.add(new_slot)
    db.commit()
    db.refresh(new_slot)
    return new_slot

# Booking Management
@app.post("/bookings/", response_model=schemas.Booking)
def create_booking(
    booking: schemas.BookingCreate, 
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    check_expired_bookings(db)
    # Check if slot exists
    slot = db.query(models.ParkingSlot).filter(models.ParkingSlot.id == booking.slot_id).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")
    
    # Check for overlapping bookings (Pending or Active)
    overlapping_booking = db.query(models.Booking).filter(
        models.Booking.slot_id == booking.slot_id,
        models.Booking.status.in_(["Pending", "Active"]),
        models.Booking.start_time < booking.end_time,
        models.Booking.end_time > booking.start_time
    ).first()
    
    if overlapping_booking:
        raise HTTPException(status_code=400, detail="Slot is already booked for this time period")
    
    # Calculate price (simple duration based)
    duration = booking.end_time - booking.start_time
    hours = duration.total_seconds() / 3600
    
    # Validation: Ensure hours is positive
    if hours <= 0:
        raise HTTPException(status_code=400, detail="Invalid booking duration. End time must be after start time.")
        
    # Use Dynamic Price for booking
    dynamic_price_per_hour = get_dynamic_price(slot, db)
    total_price = round(hours * dynamic_price_per_hour, 2)

    # Check subscription for discount
    now = get_now()
    active_sub = db.query(models.UserSubscription).join(models.SubscriptionPlan).filter(
        models.UserSubscription.user_id == current_user.id,
        models.UserSubscription.status == "Active",
        models.UserSubscription.end_date > now,
        models.SubscriptionPlan.vehicle_type == slot.type
    ).first()

    if active_sub:
        total_price = 0.0

    # Deduct from wallet if applicable
    if booking.payment_method == "Wallet":
        if current_user.wallet_balance < total_price:
            raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        current_user.wallet_balance -= total_price
    elif "UPI" in booking.payment_method:
        # UPI payments are handled by the app, we just record them here
        pass
    elif booking.payment_method == "Auto-pay":
        # Auto-pay will be charged after parking ends
        pass

    # Determine initial status: Pending if start_time is in the future
    initial_status = "Pending" if booking.start_time.replace(tzinfo=None) > get_now() else "Active"
    
    # If Auto-pay is selected, maybe we keep it as Pending/Active but mark as Unpaid?
    # For now, let's just keep it simple as per user request.

    new_booking = models.Booking(
        **booking.dict(),
        user_id=current_user.id,
        total_price=total_price,
        status=initial_status
    )
    
    # We no longer mark slot as unavailable immediately.
    # It will be managed by check_expired_bookings based on Active status.
    
    db.add(new_booking)
    
    # Create notification for user
    create_notification(
        db, 
        current_user.id, 
        "Booking Confirmed", 
        f"Your booking for slot {slot.slot_number} at {slot.location} is {initial_status.lower()}."
    )
    
    db.commit()
    db.refresh(new_booking)
    return new_booking

@app.get("/bookings/my", response_model=List[schemas.Booking])
def get_my_bookings(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    check_expired_bookings(db)
    return db.query(models.Booking).filter(models.Booking.user_id == current_user.id).all()

@app.put("/bookings/{booking_id}/cancel", response_model=schemas.Booking)
def cancel_booking(
    booking_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.status != 'Active':
        raise HTTPException(status_code=400, detail="Only active bookings can be cancelled")

    # Cancel the booking
    booking.status = 'Cancelled'
    booking.end_time = get_now()
    
    # Refund money to user wallet
    current_user.wallet_balance += booking.total_price
    
    # Free the slot
    if booking.slot:
        booking.slot.is_available = True
        
    # Create notification
    create_notification(
        db,
        current_user.id,
        "Booking Cancelled & Refunded",
        f"Your booking for slot {booking.slot.slot_number if booking.slot else 'N/A'} has been cancelled and ₹{booking.total_price} has been refunded to your wallet."
    )

    db.commit()
    db.refresh(booking)
    return booking

# User Profile Management
@app.put("/users/me", response_model=schemas.User)
def update_user_me(
    user_update: schemas.UserUpdate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if user_update.name is not None:
        current_user.name = user_update.name
    if user_update.phone is not None:
        current_user.phone = user_update.phone
    if user_update.licence_no is not None:
        if user_update.licence_no.strip() != "":
            import re
            if not re.match(r'^[A-Za-z]{2}[ -]?[0-9]{2}[ -]?[0-9]{4}[ -]?[0-9]{7}$', user_update.licence_no):
                raise HTTPException(status_code=400, detail="Invalid Driving Licence Format (e.g. GJ0120230000000)")
        current_user.licence_no = user_update.licence_no
    db.commit()
    db.refresh(current_user)
    return current_user

# Wallet Management
@app.post("/wallet/add-money", response_model=schemas.User)
def add_money(
    amount: float,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
    
    current_user.wallet_balance += amount
    
    # Create notification
    create_notification(
        db,
        current_user.id,
        "Money Added",
        f"₹{amount} has been added to your wallet successfully."
    )

    db.commit()
    db.refresh(current_user)
    return current_user

# Vehicle Management
@app.get("/vehicles/", response_model=List[schemas.Vehicle])
def get_vehicles(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    return db.query(models.Vehicle).filter(models.Vehicle.owner_id == current_user.id).all()

@app.post("/vehicles/", response_model=schemas.Vehicle)
def create_vehicle(
    vehicle: schemas.VehicleCreate,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    new_vehicle = models.Vehicle(**vehicle.dict(), owner_id=current_user.id)
    db.add(new_vehicle)
    db.commit()
    db.refresh(new_vehicle)
    return new_vehicle

@app.delete("/vehicles/{vehicle_id}")
def delete_vehicle(
    vehicle_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_vehicle = db.query(models.Vehicle).filter(
        models.Vehicle.id == vehicle_id, 
        models.Vehicle.owner_id == current_user.id
    ).first()
    if not db_vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
        
    # Manually delete associated bookings to avoid foreign key constraint issues
    db.query(models.Booking).filter(models.Booking.vehicle_id == vehicle_id).delete()
    
    db.delete(db_vehicle)
    db.commit()
    return {"message": "Vehicle deleted successfully"}

# Contact Us Form
@app.post("/contact", response_model=schemas.ContactMessage)
def submit_contact_message(
    message: schemas.ContactMessageCreate,
    db: Session = Depends(database.get_db)
):
    new_msg = models.ContactMessage(**message.dict())
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)
    return new_msg

# Notifications
@app.get("/notifications/", response_model=List[schemas.Notification])
def get_notifications(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    return db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id
    ).order_by(models.Notification.created_at.desc()).all()

@app.put("/notifications/{notification_id}/read")
def mark_notification_read(
    notification_id: int,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    notif = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == current_user.id
    ).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    return {"message": "Notification marked as read"}

@app.put("/notifications/read-all")
def mark_all_notifications_read(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id,
        models.Notification.is_read == False
    ).update({models.Notification.is_read: True})
    db.commit()
    return {"message": "All notifications marked as read"}

# Subscriptions
@app.get("/subscriptions/plans", response_model=List[schemas.SubscriptionPlan])
def get_subscription_plans(db: Session = Depends(database.get_db)):
    return db.query(models.SubscriptionPlan).all()

@app.get("/subscriptions/my", response_model=List[schemas.UserSubscription])
def get_my_subscriptions(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    now = get_now()
    subs = db.query(models.UserSubscription).filter(
        models.UserSubscription.user_id == current_user.id
    ).all()
    # Auto expire check
    for sub in subs:
        if sub.status == 'Active' and now > sub.end_date:
            sub.status = 'Expired'
            create_notification(
                db, 
                current_user.id, 
                "Subscription Expired", 
                f"Your {sub.plan.name} has expired. Please renew it from My Subscriptions to continue enjoying free parking."
            )
    db.commit()
    return subs

@app.post("/subscriptions/purchase")
def purchase_subscription(
    req: schemas.PurchaseSubscriptionRequest,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    plan = db.query(models.SubscriptionPlan).filter(models.SubscriptionPlan.id == req.plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
        
    # Check if already active
    now = get_now()
    existing = db.query(models.UserSubscription).filter(
        models.UserSubscription.user_id == current_user.id,
        models.UserSubscription.plan_id == plan.id,
        models.UserSubscription.status == "Active",
        models.UserSubscription.end_date > now
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="You already have an active subscription for this plan")

    if req.payment_method == "Wallet":
        if current_user.wallet_balance < plan.price:
            raise HTTPException(status_code=400, detail="Insufficient wallet balance")
        current_user.wallet_balance -= plan.price

    end_date = now + timedelta(days=plan.duration_days)
    new_sub = models.UserSubscription(
        user_id=current_user.id,
        plan_id=plan.id,
        start_date=now,
        end_date=end_date,
        status="Active"
    )
    db.add(new_sub)

    create_notification(
        db, 
        current_user.id, 
        "Subscription Activated", 
        f"Your {plan.name} is now active until {end_date.strftime('%Y-%m-%d')}."
    )
    db.commit()
    return {"message": "Subscription activated successfully"}

def check_expired_bookings(db: Session):
    now = get_now()
    
    # Update states for ALL bookings based on current time
    all_bookings = db.query(models.Booking).filter(
        models.Booking.status.in_(['Pending', 'Active', 'Completed'])
    ).all()

    changes_made = False
    for booking in all_bookings:
        old_status = booking.status
        
        if now < booking.start_time:
            # Future booking
            booking.status = 'Pending'
        elif booking.start_time <= now <= booking.end_time:
            # Currently active window
            booking.status = 'Active'
        else:
            # Past booking
            booking.status = 'Completed'
            
        if booking.status != old_status:
            print(f"DEBUG: Booking {booking.id} transitioned {old_status} -> {booking.status}")
            changes_made = True

    if changes_made:
        db.commit()

    # Dynamic Slot Availability
    # A slot is ONLY unavailable if it has a booking that is CURRENTLY 'Active'
    all_slots = db.query(models.ParkingSlot).all()
    for s in all_slots:
        active_booking = db.query(models.Booking).filter(
            models.Booking.slot_id == s.id,
            models.Booking.status == 'Active'
        ).first()
        
        # is_available = True means NO gaadi (Active booking) at this moment
        new_availability = (active_booking is None)
        if s.is_available != new_availability:
            s.is_available = new_availability
            print(f"DEBUG: Slot {s.slot_number} availability changed to {s.is_available}")
    
    db.commit()

def create_notification(db: Session, user_id: int, title: str, message: str):
    notif = models.Notification(user_id=user_id, title=title, message=message)
    db.add(notif)
    # We don't commit here as it's usually called inside a transaction

# Admin Endpoints
@app.get("/admin/stats", response_model=schemas.AdminStats)
def get_admin_stats(db: Session = Depends(database.get_db)):
    check_expired_bookings(db)
    
    total_users = db.query(models.User).count()
    total_bookings = db.query(models.Booking).count()
    active_bookings = db.query(models.Booking).filter(models.Booking.status == 'Active').count()
    
    total_revenue = db.query(models.Booking).filter(
        models.Booking.status.in_(['Active', 'Completed'])
    ).with_entities(models.Booking.total_price).all()
    revenue_sum = sum([r[0] for r in total_revenue if r[0]])
    
    # Add subscription revenue
    sub_revenue = db.query(models.UserSubscription).join(models.SubscriptionPlan).with_entities(models.SubscriptionPlan.price).all()
    revenue_sum += sum([r[0] for r in sub_revenue if r[0]])
    
    total_slots = db.query(models.ParkingSlot).count()
    available_slots = db.query(models.ParkingSlot).filter(models.ParkingSlot.is_available == True).count()
    
    return {
        "total_users": total_users,
        "total_bookings": total_bookings,
        "active_bookings": active_bookings,
        "total_revenue": revenue_sum,
        "available_slots": available_slots,
        "total_slots": total_slots
    }

@app.get("/admin/subscriptions", response_model=List[schemas.UserSubscription])
def get_all_subscriptions(db: Session = Depends(database.get_db)):
    now = get_now()
    subs = db.query(models.UserSubscription).all()
    for sub in subs:
        if sub.status == 'Active' and now > sub.end_date:
            sub.status = 'Expired'
    db.commit()
    return db.query(models.UserSubscription).order_by(models.UserSubscription.start_date.desc()).all()

@app.get("/admin/users", response_model=List[schemas.User])
def get_all_users(db: Session = Depends(database.get_db)):
    return db.query(models.User).all()

@app.get("/admin/bookings", response_model=List[schemas.Booking])
def get_all_bookings(db: Session = Depends(database.get_db)):
    check_expired_bookings(db)
    return db.query(models.Booking).order_by(models.Booking.created_at.desc()).all()

@app.get("/admin/slots", response_model=List[schemas.ParkingSlot])
def get_all_slots(db: Session = Depends(database.get_db)):
    check_expired_bookings(db)
    return db.query(models.ParkingSlot).all()

@app.put("/admin/slots/{slot_id}", response_model=schemas.ParkingSlot)
def update_slot(slot_id: int, slot_update: schemas.ParkingSlotUpdate, db: Session = Depends(database.get_db)):
    slot = db.query(models.ParkingSlot).filter(models.ParkingSlot.id == slot_id).first()
    if not slot:
        raise HTTPException(status_code=404, detail="Slot not found")
    
    if slot_update.is_available is not None:
        slot.is_available = slot_update.is_available
        # If admin marks slot as available, find and complete ALL active bookings on it
        if slot_update.is_available == True:
            active_bookings = db.query(models.Booking).filter(
                models.Booking.slot_id == slot_id,
                models.Booking.status == 'Active'
            ).all()
            for active_booking in active_bookings:
                active_booking.status = 'Completed'
                active_booking.end_time = get_now()

    if slot_update.type is not None:
        slot.type = slot_update.type
    if slot_update.price_per_hour is not None:
        slot.price_per_hour = slot_update.price_per_hour
        
    db.commit()
    db.refresh(slot)
    return slot

@app.delete("/admin/users/{user_id}")
def delete_user(user_id: int, db: Session = Depends(database.get_db)):
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Delete associated records (cascaded by DB or manual cleanup)
    db.query(models.Vehicle).filter(models.Vehicle.owner_id == user_id).delete()
    db.query(models.Booking).filter(models.Booking.user_id == user_id).delete()
    db.query(models.Notification).filter(models.Notification.user_id == user_id).delete()
    
    db.delete(db_user)
    db.commit()
    return {"message": "User and all associated records deleted"}

# Mount Static Files for Admin Web Panel at the end to avoid shadowing routes
import os
static_path = os.path.join(os.path.dirname(__file__), "static")
if not os.path.exists(static_path):
    os.makedirs(static_path)
app.mount("/admin", StaticFiles(directory=os.path.join(static_path, "admin"), html=True), name="admin")

if __name__ == "__main__":
    uvicorn.run("backend.main:app", host="0.0.0.0", port=8001, reload=True)
