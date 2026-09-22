import os
import io
import uuid
from pathlib import Path
from PIL import Image, UnidentifiedImageError
from fastapi import UploadFile, HTTPException
from app.core.config import settings

MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
MIME = {
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "webp": "image/webp",
    "gif": "image/gif",
    "bmp": "image/bmp",
    "pdf": "application/pdf",
}

class StorageService:
    def __init__(self, base_dir: str = settings.UPLOAD_DIR):
        self.base_dir = base_dir
        os.makedirs(self.base_dir, exist_ok=True)

    async def save_file(self, file: UploadFile) -> dict:
        filename = Path((file.filename or "").replace("\\", "/")).name
        extension = Path(filename).suffix.lower().lstrip(".")
        if not extension and file.content_type:
            for ext, m in MIME.items():
                if file.content_type.lower() == m:
                    extension = ext
                    break
        if not extension:
            extension = "jpg"

        content = await file.read(MAX_FILE_SIZE + 1)
        if not content or len(content) > MAX_FILE_SIZE:
            raise HTTPException(400, "File kosong atau melebihi batas maksimal 10MB.")

        # Determine type & validate
        actual_ext = extension
        actual_mime = MIME.get(extension, "image/jpeg")

        if extension == "pdf" or content.startswith(b"%PDF-"):
            if not content.startswith(b"%PDF-"):
                raise HTTPException(400, "Berkas PDF tidak valid.")
            actual_ext = "pdf"
            actual_mime = "application/pdf"
        else:
            try:
                with Image.open(io.BytesIO(content)) as img:
                    if img.width * img.height > 35000000:
                        raise ValueError("Resolusi gambar terlalu tinggi.")
                    fmt = (img.format or "JPEG").upper()
                    if fmt == "PNG":
                        actual_ext = "png"
                        actual_mime = "image/png"
                    elif fmt == "WEBP":
                        actual_ext = "webp"
                        actual_mime = "image/webp"
                    elif fmt == "GIF":
                        actual_ext = "gif"
                        actual_mime = "image/gif"
                    elif fmt == "BMP":
                        actual_ext = "bmp"
                        actual_mime = "image/bmp"
                    else:
                        actual_ext = "jpg"
                        actual_mime = "image/jpeg"
            except (UnidentifiedImageError, OSError, ValueError):
                raise HTTPException(400, "Berkas gambar tidak valid atau format tidak didukung.")

        stored_filename = f"{uuid.uuid4().hex}.{actual_ext}"
        dest_path = Path(self.base_dir).resolve() / stored_filename
        dest_path.write_bytes(content)

        return {
            "file_name": filename or stored_filename,
            "stored_filename": stored_filename,
            "file_path": f"/uploads/{stored_filename}",
            "file_type": actual_mime,
            "file_size_bytes": len(content)
        }

    def resolve(self, file_path: str):
        name = Path(file_path).name
        path = (Path(self.base_dir).resolve() / name).resolve()
        if path.parent != Path(self.base_dir).resolve() or not path.is_file():
            raise HTTPException(404, 'Berkas tidak ditemukan.')
        return path




storage_service = StorageService()
