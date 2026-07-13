import os
from fastapi import FastAPI, File, UploadFile, Form, Request, HTTPException
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
import asyncio

from fastapi.middleware.cors import CORSMiddleware
from config import AppConfig
from image_utils import process_image_sync
from ai_service import analyze_image_with_ai
from tts_service import generate_turkish_audio

from routers import auth_router, history_router

app = FastAPI(title="VoiceGuide AI API")

# Tarayıcı üzerinden web arayüzünün bağlanabilmesi için CORS izni ekliyoruz
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router.router)
app.include_router(history_router.router)

# Sesi stream edebilmek için statik klasör
os.makedirs("static/audio", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

class TTSRequest(BaseModel):
    text: str

@app.post("/api/v1/analyze")
async def analyze_image(request: Request, image: UploadFile = File(...), lang: str = Form("tr")):
    """
    Görüntüyü analiz eder, metni üretir ve aynı anda TTS ile sesi oluşturup URL'sini döner.
    Mobil uygulamanın istediği Full Payload'u hazırlar.
    """
    contents = await image.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Boş dosya gönderildi.")
    
    # Flutter bazen Multipart olarak gönderirken resmi "application/octet-stream" 
    # MIME tipiyle yollayabiliyor. Bu yüzden content_type kısıtlamasını kaldırıp 
    # doğrudan Pillow kütüphanesine (process_image_sync) paslıyoruz.

    try:
        # 1. Image Preprocessing (Async Thread)
        optimized_bytes = await asyncio.to_thread(
            process_image_sync, contents, AppConfig.MAX_IMAGE_SIZE, AppConfig.JPEG_QUALITY
        )
        
        # 2. AI Analizi (Gemini 2.5 Flash)
        ai_result = await analyze_image_with_ai(optimized_bytes)
        
        # 3. Seslendirme (TTS) ve MP3 Kaydı
        full_text = f"{ai_result['description']} {ai_result['details']}"
        audio_url = ""
        try:
            audio_filename = await generate_turkish_audio(full_text)
            base_url = str(request.base_url)
            audio_url = f"{base_url}static/audio/{audio_filename}"
        except Exception as tts_err:
            print(f"TTS Error: {tts_err}")
            # Hata olursa audio_url boş döner, mobil uygulama Fallback (yerel TTS) yapar.
            
        ai_result["audio_url"] = audio_url

        return {
            "status": "success",
            "data": ai_result
        }
    except Exception as e:
        print(f"Analyze Error: {e}")
        raise HTTPException(status_code=500, detail="Görüntü analiz edilemedi.")


@app.post("/tts")
async def create_tts(request: Request, body: TTSRequest):
    try:
        audio_filename = await generate_turkish_audio(body.text)
        base_url = str(request.base_url)
        audio_url = f"{base_url}static/audio/{audio_filename}"
        return {"status": "success", "audio_url": audio_url}
    except Exception as e:
        print(f"TTS Error: {e}")
        raise HTTPException(status_code=500, detail="Ses üretilemedi.")
