import os
import uuid
import asyncio
import edge_tts

async def generate_turkish_audio(text: str) -> str:
    """
    Verilen metni sese dönüştürür.
    Edge TTS (Microsoft Azure Altyapısı) kullanarak çook hızlı ve ultra gerçekçi bir ses üretir.
    """
    filename = f"{uuid.uuid4()}.mp3"
    filepath = os.path.join("static", "audio", filename)
    
    # TR-AhmetNeural: Microsoft'un en kaliteli, doğal Türkçe seslerinden biridir.
    VOICE = "tr-TR-AhmetNeural" 
    
    # Kısaltmaları düzeltelim
    clean_text = text.replace(" m.", " metre.").replace(" cm.", " santimetre.")
    
    # Sesi oluştur ve kaydet (Saniyeler içinde biter)
    communicate = edge_tts.Communicate(clean_text, VOICE)
    await communicate.save(filepath)
    
    return filename
