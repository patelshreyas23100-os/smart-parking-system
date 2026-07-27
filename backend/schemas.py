from pydantic import BaseModel, EmailStr
from typing import List, Optional
from datetime import datetime

class VehicleBase(BaseModel):
    name: str
    plate_number: str
    type: str

class VehicleCreate(VehicleBase):
    pass

class Vehicle(VehicleBase):
    id: int
    owner_id: int

    class Config:
        from_attributes = True

class UserBase(BaseModel):
    email: EmailStr
    name: str
    phone: str
    licence_no: Optional[str] = None
    wallet_balance: float = 0.0

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    licence_no: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class OTPRequest(BaseModel):
    email: EmailStr
    type: Optional[str] = "login" # "login" or "signup"

class OTPVerify(BaseModel):
    email: EmailStr
    otp: str
    password: Optional[str] = None

class UserSignupWithOTP(BaseModel):
    email: EmailStr
    otp: str
    name: str
    phone: str
    password: str # Still keeping password for fallback/traditional login
    licence_no: Optional[str] = None

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class UserPasswordReset(BaseModel):
    email: EmailStr
    otp: str
    new_password: str

class User(UserBase):
    id: int
    vehicles: List[Vehicle] = []

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class AuthResponse(BaseModel):
    user: User
    token: Token

class TokenData(BaseModel):
    email: Optional[str] = None

class ParkingSlotBase(BaseModel):
    slot_number: str
    type: str
    location: str = "General"
    price_per_hour: float
    is_available: bool

class ParkingSlotUpdate(BaseModel):
    is_available: Optional[bool] = None
    type: Optional[str] = None
    location: Optional[str] = None
    price_per_hour: Optional[float] = None

class ParkingSlot(ParkingSlotBase):
    id: int

    class Config:
        from_attributes = True

class BookingBase(BaseModel):
    slot_id: int
    vehicle_id: int
    start_time: datetime
    end_time: datetime
    payment_method: str

class BookingCreate(BookingBase):
    pass

class Booking(BookingBase):
    id: int
    user_id: int
    total_price: float
    status: str
    created_at: datetime
    location: Optional[str] = "General" # Added for easier display in logs
    slot: Optional[ParkingSlot] = None
    vehicle: Optional[Vehicle] = None
    user: Optional[UserBase] = None

    class Config:
        from_attributes = True

class ContactMessageBase(BaseModel):
    name: str
    email: str
    message: str

class ContactMessageCreate(ContactMessageBase):
    pass

class ContactMessage(ContactMessageBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class NotificationBase(BaseModel):
    title: str
    message: str

class Notification(NotificationBase):
    id: int
    user_id: int
    is_read: bool
    created_at: datetime

    class Config:
        from_attributes = True
class AdminStats(BaseModel):
    total_users: int
    total_bookings: int
    active_bookings: int
    total_revenue: float
    available_slots: int
    total_slots: int

class SubscriptionPlanBase(BaseModel):
    name: str
    vehicle_type: str
    duration_days: int
    price: float

class SubscriptionPlan(SubscriptionPlanBase):
    id: int

    class Config:
        from_attributes = True

class UserSubscriptionBase(BaseModel):
    plan_id: int
    start_date: datetime
    end_date: datetime
    status: str

class UserSubscription(UserSubscriptionBase):
    id: int
    user_id: int
    plan: SubscriptionPlan
    user: Optional[UserBase] = None

    class Config:
        from_attributes = True

class PurchaseSubscriptionRequest(BaseModel):
    plan_id: int
    payment_method: str # Wallet, UPI

class ParkingLocationBase(BaseModel):
    name: str
    area: str
    latitude: float
    longitude: float

class ParkingLocationCreate(ParkingLocationBase):
    pass

class ParkingLocation(ParkingLocationBase):
    id: int
    total_slots: Optional[int] = 0
    available_slots: Optional[int] = 0
    distance: Optional[str] = None
    price_per_hour: Optional[float] = 20.0

    class Config:
        from_attributes = True

class LocationSuggestion(BaseModel):
    name: str
    area: str
    type: str # Area, Mall, Landmark, etc.
