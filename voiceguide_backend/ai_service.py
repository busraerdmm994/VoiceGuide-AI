import json
import io
from google import genai
from google.genai import types
from PIL import Image
from config import AppConfig, Prompts, Fallbacks

# Yeni ve güncel Google GenAI istemcisi
client = genai.Client(api_key=AppConfig.GEMINI_API_KEY)

async def analyze_image_with_ai(image_bytes: bytes) -> dict:
    """
    Ücretsiz Google Gemini API entegrasyonu. (Güncel google-genai kütüphanesi)
    """
    try:
        # Gelen bayt verisini Gemini'nin okuyabilmesi için PIL nesnesine çeviriyoruz
        img = Image.open(io.BytesIO(image_bytes))
        
        # Yapay zekaya resmi ve promptumuzu gönderiyoruz (Asenkron - aio)
        response = await client.aio.models.generate_content(
            model='gemini-2.5-flash', # En yeni, ücretsiz ve çok hızlı model
            contents=[
                Prompts.SYSTEM_PROMPT,
                img
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json" # API'yi JSON dönmeye zorluyoruz
            )
        )
        
        content = response.text
        parsed_data = json.loads(content)
        
        description = parsed_data.get("description", "").strip()
        details = parsed_data.get("details", "").strip()
        
        if not description or not details:
            return Fallbacks.GENERIC
            
        return {
            "description": description,
            "details": details
        }
        
    except Exception as e:
        print(f"Gemini API Hatası: {e}")
        return Fallbacks.GENERIC
