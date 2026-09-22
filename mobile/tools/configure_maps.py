"""Run before flutter build web. Generated file must not be committed."""
import json
import os
from pathlib import Path
key = os.environ.get("GOOGLE_MAPS_WEB_API_KEY", "")
(Path(__file__).resolve().parents[1] / "web/maps-config.js").write_text(
    "window.GOOGLE_MAPS_API_KEY = " + json.dumps(key) + ";\n", encoding="utf-8")
