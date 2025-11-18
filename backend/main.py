from fastapi import FastAPI, File, UploadFile, Query, HTTPException, Depends, Form, Body, Request
from fastapi.security import OAuth2PasswordBearer
from pydantic import BaseModel
from pymongo import MongoClient
from bson import ObjectId
from datetime import datetime, timedelta
from dotenv import load_dotenv
from fastapi.staticfiles import StaticFiles
from passlib.context import CryptContext
from jose import JWTError, jwt
import os, shutil, base64
from typing import Optional, Union, List, Dict

# ------------------------------
# Load environment variables
# ------------------------------
load_dotenv()

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/qr_scanner_db")
DB_NAME = os.getenv("DB_NAME", "qr_scanner_db")
SECRET_KEY = os.getenv("SECRET_KEY", "my_secret")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# ------------------------------
# MongoDB connection
# ------------------------------
client = MongoClient(MONGO_URI)
db = client[DB_NAME]
reports_collection = db["reports"]
users_collection = db["users"]

# ------------------------------
# FastAPI app
# ------------------------------
app = FastAPI(title="QR Scanner Backend", version="1.0")

# ------------------------------
# Static file mount
# ------------------------------
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

# ------------------------------
# Password hashing & JWT
# ------------------------------
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str):
    return pwd_context.hash(password[:72])  # bcrypt safety limit


def create_access_token(data: dict):
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    data.update({"exp": expire})
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)


def get_current_user(token: str = Depends(oauth2_scheme)):
    """Extract user info from token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# ------------------------------
# Auth Routes
# ------------------------------
@app.post("/auth/signup")
async def signup(request: Request):
    """Register using form-data or JSON"""
    try:
        data = await request.json()
        email = data.get("email")
        password = data.get("password")
    except:
        form = await request.form()
        email = form.get("email")
        password = form.get("password")

    if not email or not password:
        raise HTTPException(status_code=400, detail="Email & password required")

    if users_collection.find_one({"email": email}):
        raise HTTPException(status_code=400, detail="Email already exists")

    hashed_pw = get_password_hash(password)

    users_collection.insert_one({
        "email": email,
        "password": hashed_pw,
        "created_at": datetime.utcnow()
    })

    return {"message": "User created successfully"}


@app.post("/auth/login")
async def login(request: Request):
    """Login via JSON or form-data"""
    try:
        data = await request.json()
        email = data.get("email")
        password = data.get("password")
    except:
        form = await request.form()
        email = form.get("email")
        password = form.get("password")

    user = users_collection.find_one({"email": email})
    if not user or not verify_password(password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_access_token({"sub": str(user["_id"])})

    return {"access_token": token, "token_type": "bearer"}


# ------------------------------
# Report Model
# ------------------------------
class ReportIn(BaseModel):
    student_info: str
    violations: Union[str, List[str]]
    scan_date: Optional[datetime] = None
    scanned_at: Optional[datetime] = None
    image_path: Optional[str] = None
    image_name: Optional[str] = None
    image_base64: Optional[str] = None
    image_source: Optional[str] = None  # "drive_link" / "local"
    reporter_name: Optional[str] = None  # Name of person submitting report


# ------------------------------
# Submit Report (FINAL + CLEAN)
# ------------------------------
@app.post("/submit_report/")
async def submit_report(report: ReportIn):
    # Debug log
    print("\n========== DEBUG REPORT RECEIVED ==========")
    print(report.dict())
    print("===========================================\n")

    # Normalize violations list
    if isinstance(report.violations, list):
        violation_text = ", ".join(report.violations)
    else:
        violation_text = report.violations

    # Compute offense number
    offense_number = reports_collection.count_documents({
        "student_info": report.student_info
    }) + 1

    # Handle image
    saved_image_path = None

    if report.image_source == "local" and report.image_base64:
        # Base64 -> file
        try:
            file_bytes = base64.b64decode(report.image_base64)
            filename = report.image_name or f"img_{datetime.utcnow().timestamp()}.png"
            file_path = os.path.join(UPLOAD_DIR, filename)

            with open(file_path, "wb") as f:
                f.write(file_bytes)

            saved_image_path = f"/uploads/{filename}"
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Base64 decode failed: {e}")

    elif report.image_source == "drive_link" and report.image_path:
        saved_image_path = report.image_path  # Save Google Drive URL

    # Build report data
    report_data = {
        "student_info": report.student_info,
        "violation": violation_text,
        "no_of_offense": offense_number,
        "scanned_at": report.scan_date or report.scanned_at or datetime.utcnow(),
        "image_path": saved_image_path,
        "submitted_by": report.reporter_name or "Anonymous",
        "isDeleted": False,
    }

    inserted_id = reports_collection.insert_one(report_data).inserted_id

    return {"status": "success", "id": str(inserted_id)}


# ------------------------------
# Upload image via separate API
# ------------------------------
@app.post("/upload_image/")
def upload_image(
    report_id: str = Query(...),
    file: UploadFile = File(...),
    current_user: str = Depends(get_current_user)
):
    """Old file upload API (kept for admin panel)"""
    try:
        oid = ObjectId(report_id)
    except:
        raise HTTPException(status_code=400, detail="Invalid report_id")

    filename = file.filename
    file_path = os.path.join(UPLOAD_DIR, filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    file_url = f"/uploads/{filename}"
    reports_collection.update_one({"_id": oid}, {"$set": {"image_path": file_url}})

    return {"status": "success", "file_url": file_url}


# ------------------------------
# Fetch Reports
# ------------------------------
@app.get("/reports/")
def get_reports(current_user: str = Depends(get_current_user)):
    reports = []
    for r in reports_collection.find().sort("scanned_at", -1):
        r["_id"] = str(r["_id"])
        r["no_of_offense"] = r.get("no_of_offense", 1)
        reports.append(r)
    return {"reports": reports}

