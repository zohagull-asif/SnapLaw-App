"""
OCR Engine for SnapLaw Evidence Scanner.
Extracts text from images and PDFs using Tesseract OCR and PyMuPDF.
"""

import pytesseract
from PIL import Image
import fitz  # pymupdf
import io
import os
import logging

logger = logging.getLogger(__name__)

# Set Tesseract path for Windows
tesseract_path = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
if os.path.exists(tesseract_path):
    pytesseract.pytesseract.tesseract_cmd = tesseract_path


def extract_text_from_image(image_bytes: bytes) -> dict:
    """Extract text from image file using OCR."""
    try:
        image = Image.open(io.BytesIO(image_bytes))

        # Convert to RGB if needed (handles RGBA, grayscale, etc.)
        if image.mode != 'RGB':
            image = image.convert('RGB')

        # Try Urdu + English together
        text = ""
        try:
            text = pytesseract.image_to_string(
                image,
                lang='urd+eng',
                config='--psm 3'
            )
        except Exception:
            pass

        # If Urdu lang not available or no text, fall back to English only
        if not text.strip():
            text = pytesseract.image_to_string(
                image,
                lang='eng',
                config='--psm 3'
            )

        return {
            "success": True,
            "text": text.strip(),
            "pages": 1,
            "method": "image_ocr"
        }
    except Exception as e:
        logger.error(f"Image OCR failed: {e}")
        return {"success": False, "error": str(e), "text": ""}


def extract_text_from_pdf(pdf_bytes: bytes) -> dict:
    """Extract text from PDF — try direct extraction first, then OCR."""
    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        full_text = ""
        page_count = len(doc)

        for page_num, page in enumerate(doc):
            # Try direct text extraction first (faster, works for digital PDFs)
            text = page.get_text()
            if text.strip():
                full_text += f"--- Page {page_num + 1} ---\n{text}\n\n"
            else:
                # If no text (scanned PDF), use OCR on page image
                pix = page.get_pixmap(dpi=200)
                img_bytes = pix.tobytes("png")
                result = extract_text_from_image(img_bytes)
                if result["success"] and result["text"]:
                    full_text += f"--- Page {page_num + 1} ---\n{result['text']}\n\n"

        doc.close()

        return {
            "success": True,
            "text": full_text.strip(),
            "pages": page_count,
            "method": "pdf_extraction"
        }
    except Exception as e:
        logger.error(f"PDF extraction failed: {e}")
        return {"success": False, "error": str(e), "text": ""}


def process_document(file_bytes: bytes, filename: str) -> dict:
    """Main function - detect file type and extract text."""
    filename_lower = filename.lower()

    if filename_lower.endswith('.pdf'):
        return extract_text_from_pdf(file_bytes)
    elif filename_lower.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp')):
        return extract_text_from_image(file_bytes)
    else:
        return {
            "success": False,
            "error": "Unsupported file type. Use PDF, JPG, or PNG.",
            "text": ""
        }
