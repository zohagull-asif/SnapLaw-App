import fitz  # pymupdf
import pytesseract
from PIL import Image
import io
import os

pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'


def extract_from_pdf(pdf_bytes: bytes) -> dict:
    """Extract text from PDF — direct first, OCR fallback for scanned pages"""
    try:
        doc = fitz.open(stream=pdf_bytes, filetype="pdf")
        full_text = ""
        page_count = len(doc)

        for page_num, page in enumerate(doc):
            text = page.get_text()
            if text.strip():
                full_text += f"\n--- Page {page_num + 1} ---\n{text}"
            else:
                # Scanned page — use OCR
                pix = page.get_pixmap(dpi=200)
                img_bytes = pix.tobytes("png")
                image = Image.open(io.BytesIO(img_bytes))
                ocr_text = pytesseract.image_to_string(
                    image, lang='eng', config='--psm 3'
                )
                full_text += f"\n--- Page {page_num + 1} (OCR) ---\n{ocr_text}"

        doc.close()
        return {
            "success": True,
            "text": full_text.strip(),
            "pages": page_count,
            "method": "pdf"
        }
    except Exception as e:
        return {"success": False, "error": str(e), "text": ""}


def extract_from_image(image_bytes: bytes) -> dict:
    """Extract text from image using OCR"""
    try:
        image = Image.open(io.BytesIO(image_bytes))
        text = pytesseract.image_to_string(
            image, lang='eng', config='--psm 3'
        )
        if not text.strip():
            text = pytesseract.image_to_string(image, config='--psm 3')
        return {
            "success": True,
            "text": text.strip(),
            "pages": 1,
            "method": "image_ocr"
        }
    except Exception as e:
        return {"success": False, "error": str(e), "text": ""}


def extract_text(file_bytes: bytes, filename: str) -> dict:
    """Main function — detect file type and extract"""
    fname = filename.lower()
    if fname.endswith('.pdf'):
        return extract_from_pdf(file_bytes)
    elif fname.endswith(('.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp')):
        return extract_from_image(file_bytes)
    else:
        return {
            "success": False,
            "error": "Unsupported file. Upload PDF, JPG, or PNG.",
            "text": ""
        }
