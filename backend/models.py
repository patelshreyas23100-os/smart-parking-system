from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String, unique=True, index=True)
    phone = Column(String)
    licence_no = Column(String, nullable=True)
    hashed_password = Column(String)
    wallet_balance = Column(Float, default=0.0)
    reset_otp = Column(String, nullable=True)
    reset_otp_expiry = Column(DateTime, nullable=True)
    
    vehicles = relationship("Vehicle", back_populates="owner")
    bookings = relationship("Booking", back_populates="user")
    notifications = relationship("Notification", back_populates="user")

class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    plate_number = Column(String)
    type = Column(String) # Two-Wheeler / Four-Wheeler
    owner_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="vehicles")

class ParkingSlot(Base):
    __tablename__ = "parking_slots"

    id = Column(Integer, primary_key=True, index=True)
    slot_number = Column(String, unique=True) # e.g. A1, B2
    type = Column(String) # Two-Wheeler / Four-Wheeler
    location = Column(String, default="General") # Mall, Office, Theater, etc.
    is_available = Column(Boolean, default=True)
    price_per_hour = Column(Float)
    location_id = Column(Integer, ForeignKey("parking_locations.id"), nullable=True)

    parking_location = relationship("ParkingLocation", back_populates="slots")

class ParkingLocation(Base):
    __tablename__ = "parking_locations"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Palladium Mall Parking"
    area = Column(String) # e.g. "Thaltej"
    latitude = Column(Float)
    longitude = Column(Float)
    
    slots = relationship("ParkingSlot", back_populates="parking_location")

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    slot_id = Column(Integer, ForeignKey("parking_slots.id"))
    vehicle_id = Column(Integer, ForeignKey("vehicles.id", ondelete="CASCADE"))
    start_time = Column(DateTime)
    end_time = Column(DateTime)
    total_price = Column(Float)
    status = Column(String, default="Active") # Active, Completed, Cancelled
    payment_method = Column(String) # Cash, Wallet, UPI
    created_at = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None))

    user = relationship("User", back_populates="bookings")
    slot = relationship("ParkingSlot")
    vehicle = relationship("Vehicle")

    @property
    def location(self):
        if self.slot and self.slot.parking_location:
            return f"{self.slot.parking_location.name}, {self.slot.parking_location.area}"
        return self.slot.location if self.slot else "General"

class ContactMessage(Base):
    __tablename__ = "contact_messages"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    email = Column(String)
    message = Column(String)
    created_at = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None))

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    title = Column(String)
    message = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None))

    user = relationship("User", back_populates="notifications")

class SubscriptionPlan(Base):
    __tablename__ = "subscription_plans"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String) # e.g. "Two-Wheeler Monthly Pass"
    vehicle_type = Column(String) # "Two-Wheeler" or "Four-Wheeler"
    duration_days = Column(Integer) # e.g. 30
    price = Column(Float)

class UserSubscription(Base):
    __tablename__ = "user_subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    plan_id = Column(Integer, ForeignKey("subscription_plans.id"))
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    status = Column(String, default="Active")

    user = relationship("User")
    plan = relationship("SubscriptionPlan")

class PendingOTP(Base):
    __tablename__ = "pending_otps"

    email = Column(String, primary_key=True, index=True)
    otp = Column(String)
    expiry = Column(DateTime)
