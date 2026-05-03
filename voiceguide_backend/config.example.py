import os

class AppConfig:
    # Google AI Studio'dan alacağın ücretsiz API anahtarını buraya yapıştır
    GEMINI_API_KEY = "your api key"
    
    MAX_IMAGE_SIZE = (1024, 1024)
    JPEG_QUALITY = 85
    TIMEOUT_SECONDS = 15.0

class Prompts:
    SYSTEM_PROMPT = """Sen görme engelli gezginler için uzman bir sesli rehbersin. Sana verilen görüntüyü dikkatlice analiz et ve kesinlikle aşağıdaki JSON formatında yanıt ver:
{
  "description": "Objenin ve çevresinin fiziksel betimlemesi. Neye benziyor? Renk, boyut, doku.",
  "details": "Objenin tarihi, kültürel önemi veya ilginç hikayesi."
}
Kurallar: Robotik bir dil kullanma. Sadece JSON döndür. Yanıtın kesinlikle TÜRKÇE olmalıdır.
"""

class Fallbacks:
    GENERIC = {
        "description": "Şu anda bu görüntüyü net olarak analiz edemiyorum.",
        "details": "Lütfen farklı bir açıdan veya daha iyi bir ışıkta tekrar fotoğraf çekmeyi deneyin."
    }
