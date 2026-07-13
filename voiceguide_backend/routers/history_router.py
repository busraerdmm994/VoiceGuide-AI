from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Request
from sqlalchemy.orm import Session
from typing import List, Optional
import asyncio
from database import get_db
import models, schemas, auth
from config import AppConfig
from image_utils import process_image_sync
from ai_service import analyze_image_with_ai
from tts_service import generate_turkish_audio

router = APIRouter(prefix="/api/v1/user", tags=["user"])

@router.get("/history", response_model=List[schemas.HistoryResponse])
def get_user_history(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    histories = db.query(models.History).filter(models.History.user_id == current_user.id).order_by(models.History.created_at.desc()).all()
    return histories

@router.get("/visited-places", response_model=List[schemas.VisitedPlaceResponse])
def get_visited_places(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    places = db.query(models.VisitedPlace).filter(
        models.VisitedPlace.user_id == current_user.id
    ).order_by(models.VisitedPlace.visited_at.desc()).all()
    return places

@router.get("/wishlist", response_model=List[schemas.WishlistResponse])
def get_user_wishlist(db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    return db.query(models.Wishlist).filter(models.Wishlist.user_id == current_user.id).order_by(models.Wishlist.created_at.desc()).all()

@router.post("/wishlist", response_model=schemas.WishlistResponse)
def add_to_wishlist(wish: schemas.WishlistCreate, db: Session = Depends(get_db), current_user: models.User = Depends(auth.get_current_user)):
    new_wish = models.Wishlist(**wish.dict(), user_id=current_user.id)
    db.add(new_wish)
    db.commit()
    db.refresh(new_wish)
    return new_wish

@router.post("/analyze-authenticated")
async def analyze_image_authenticated(
    request: Request,
    image: UploadFile = File(...),
    lang: str = Form("tr"),
    lat: Optional[float] = Form(None),
    lng: Optional[float] = Form(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    contents = await image.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Boş dosya gönderildi.")
    
    try:
        optimized_bytes = await asyncio.to_thread(
            process_image_sync, contents, AppConfig.MAX_IMAGE_SIZE, AppConfig.JPEG_QUALITY
        )
        ai_result = await analyze_image_with_ai(optimized_bytes)
        
        full_text = f"{ai_result['description']} {ai_result['details']}"
        audio_url = ""
        duration_str = "1dk 10sn"
        try:
            audio_filename = await generate_turkish_audio(full_text)
            base_url = str(request.base_url)
            audio_url = f"{base_url}static/audio/{audio_filename}"
        except Exception as tts_err:
            print(f"TTS Error: {tts_err}")

        place_name = ai_result['description'][:40].rstrip() + "…" if ai_result.get('description') else "Bilinmeyen Yer"

        # History kaydı
        new_history = models.History(
            user_id=current_user.id,
            type="audio",
            place_name=place_name,
            location_name="Türkiye",
            description=ai_result['description'],
            details=ai_result.get('details'),
            audio_url=audio_url,
            duration_str=duration_str,
            rating=5.0
        )
        db.add(new_history)

        # Visited place kaydı — lat/lng geldiyse kaydet
        if lat is not None and lng is not None:
            new_visit = models.VisitedPlace(
                user_id=current_user.id,
                place_name=place_name,
                location_lat=lat,
                location_lng=lng,
            )
            db.add(new_visit)

        db.commit()

        ai_result["audio_url"] = audio_url
        return {"status": "success", "data": ai_result}
    except Exception as e:
        print(f"Analyze Error: {e}")
        raise HTTPException(status_code=500, detail="Görüntü analiz edilemedi.")

