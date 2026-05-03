from PIL import Image, UnidentifiedImageError
import io
import logging

logger = logging.getLogger("voiceguide.image")

def process_image_sync(image_bytes: bytes, max_size: tuple = (1024, 1024), quality: int = 85) -> bytes:
    """
    Synchronous image processing function intended to be run in a separate thread.
    - Resizes image to save bandwidth and reduce AI latency.
    - Converts to RGB (JPEG).
    - Compresses the payload.
    """
    try:
        # Load image from bytes
        with Image.open(io.BytesIO(image_bytes)) as img:
            # Drop alpha channel or other modes if converting to JPEG
            if img.mode != "RGB":
                img = img.convert("RGB")
            
            # Thumbnail maintains aspect ratio. LANCZOS is high quality downsampling.
            img.thumbnail(max_size, Image.Resampling.LANCZOS)
            
            # Save optimized JPEG to memory
            output_io = io.BytesIO()
            img.save(output_io, format="JPEG", quality=quality, optimize=True)
            return output_io.getvalue()
            
    except UnidentifiedImageError:
        logger.error("Failed to process image: Invalid or unsupported image format.")
        raise ValueError("Invalid image format.")
    except Exception as e:
        logger.error(f"Image processing error: {str(e)}")
        raise e
