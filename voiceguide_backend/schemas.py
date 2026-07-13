from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class HistoryResponse(BaseModel):
    id: str
    type: str
    place_name: str
    location_name: Optional[str]
    image_url: Optional[str]
    description: Optional[str]
    details: Optional[str]
    audio_url: Optional[str]
    duration_str: Optional[str]
    rating: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True

class WishlistCreate(BaseModel):
    place_name: str
    location_name: Optional[str] = None
    tag: Optional[str] = None

class WishlistResponse(WishlistCreate):
    id: str
    user_id: str
    created_at: datetime

    class Config:
        from_attributes = True

class VisitedPlaceResponse(BaseModel):
    id: str
    place_name: str
    location_lat: Optional[float]
    location_lng: Optional[float]
    visited_at: datetime

    class Config:
        from_attributes = True
