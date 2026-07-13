from sqlalchemy import Column, String, Float, ForeignKey, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=generate_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    full_name = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    histories = relationship("History", back_populates="user", cascade="all, delete-orphan")
    wishlists = relationship("Wishlist", back_populates="user", cascade="all, delete-orphan")
    visited_places = relationship("VisitedPlace", back_populates="user", cascade="all, delete-orphan")

class History(Base):
    __tablename__ = "histories"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    type = Column(String, default="audio") # audio, photo, nav
    place_name = Column(String, nullable=False)
    location_name = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    description = Column(Text, nullable=True)
    details = Column(Text, nullable=True)
    audio_url = Column(String, nullable=True)
    duration_str = Column(String, nullable=True)
    rating = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="histories")

class Wishlist(Base):
    __tablename__ = "wishlists"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    place_name = Column(String, nullable=False)
    location_name = Column(String, nullable=True)
    tag = Column(String, nullable=True) # e.g. Doğa, Tarihi, Kültür
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="wishlists")

class VisitedPlace(Base):
    __tablename__ = "visited_places"

    id = Column(String, primary_key=True, default=generate_uuid)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    place_name = Column(String, nullable=False)
    location_lat = Column(Float, nullable=True)
    location_lng = Column(Float, nullable=True)
    visited_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="visited_places")
