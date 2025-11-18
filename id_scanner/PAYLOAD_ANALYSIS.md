# 📤 Current Payload & Database Structure Analysis

## Current Database Record (Your Example)

```json
{
  "_id": "691a8fc4f69fb08df936b636",
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "violation": "Exposed Shoulders, Exposed Knees",
  "no_of_offense": 16,
  "scanned_at": "2025-11-17T03:00:20.261+00:00",
  "image_path": null,
  "submitted_by": "Anonymous",
  "isDeleted": false
}
```

---

## What Flutter App Is Currently Sending

### Without Image (Works ✅)
```json
{
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "scan_date": "2025-11-17T15:45:00.000Z",
  "violations": ["Exposed Shoulders", "Exposed Knees"]
}
```

### With Google Drive Image (Already Implemented ✅)
```json
{
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "scan_date": "2025-11-17T15:45:00.000Z",
  "violations": ["Exposed Shoulders", "Exposed Knees"],
  "image_source": "drive_link",
  "image_url": "https://drive.google.com/file/d/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi/view?usp=sharing"
}
```

### With Local Image (Already Implemented ✅)
```json
{
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "scan_date": "2025-11-17T15:45:00.000Z",
  "violations": ["Exposed Shoulders", "Exposed Knees"],
  "image_source": "local",
  "image_name": "evidence_photo.png",
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA..."
}
```

---

## What Backend Needs to Accept

Currently your backend likely has:
```python
@csrf_exempt
def submit_report(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        report = ViolationReport.objects.create(
            student_info=data.get('student_info'),
            scan_date=data.get('scan_date'),
            violations=data.get('violations'),
            # ❌ MISSING: image_url, image_source, image_name
        )
```

**Should be:**
```python
@csrf_exempt
def submit_report(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        report = ViolationReport.objects.create(
            student_info=data.get('student_info'),
            scan_date=data.get('scan_date'),
            violations=data.get('violations'),
            # ✅ ADD THESE:
            image_url=data.get('image_url'),
            image_source=data.get('image_source'),
            image_name=data.get('image_name'),
        )
```

---

## What Database Needs to Store

### Old Structure (Current)
```python
class ViolationReport(models.Model):
    _id = models.ObjectIdField(primary_key=True)
    student_info = models.TextField()
    violation = models.TextField()
    no_of_offense = models.IntegerField()
    scanned_at = models.DateTimeField()
    image_path = models.CharField(max_length=255, null=True, blank=True)
    submitted_by = models.CharField(max_length=100)
    isDeleted = models.BooleanField(default=False)
```

### New Structure (With Image URL)
```python
class ViolationReport(models.Model):
    _id = models.ObjectIdField(primary_key=True)
    student_info = models.TextField()
    violation = models.TextField()
    no_of_offense = models.IntegerField()
    scanned_at = models.DateTimeField()
    image_path = models.CharField(max_length=255, null=True, blank=True)
    # ✅ NEW FIELDS:
    image_url = models.URLField(max_length=500, null=True, blank=True)
    image_source = models.CharField(
        max_length=50,
        choices=[('drive_link', 'Google Drive'), ('local', 'Local')],
        null=True, 
        blank=True
    )
    image_name = models.CharField(max_length=255, null=True, blank=True)
    # END NEW FIELDS
    submitted_by = models.CharField(max_length=100)
    isDeleted = models.BooleanField(default=False)
```

---

## Expected Database Record After Implementation

### Without Image
```json
{
  "_id": "691a8fc4f69fb08df936b637",
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "violation": "Exposed Shoulders, Exposed Knees",
  "no_of_offense": 16,
  "scanned_at": "2025-11-17T15:45:00.000Z",
  "image_path": null,
  "image_url": null,
  "image_source": null,
  "image_name": null,
  "submitted_by": "Anonymous",
  "isDeleted": false
}
```

### With Google Drive Image
```json
{
  "_id": "691a8fc4f69fb08df936b638",
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "violation": "Exposed Shoulders, Exposed Knees",
  "no_of_offense": 16,
  "scanned_at": "2025-11-17T15:45:00.000Z",
  "image_path": null,
  "image_url": "https://drive.google.com/file/d/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi/view?usp=sharing",
  "image_source": "drive_link",
  "image_name": "evidence.png",
  "submitted_by": "Anonymous",
  "isDeleted": false
}
```

### With Local Image
```json
{
  "_id": "691a8fc4f69fb08df936b639",
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "violation": "Exposed Shoulders, Exposed Knees",
  "no_of_offense": 16,
  "scanned_at": "2025-11-17T15:45:00.000Z",
  "image_path": "/media/uploads/evidence.png",
  "image_url": null,
  "image_source": "local",
  "image_name": "evidence.png",
  "submitted_by": "Anonymous",
  "isDeleted": false
}
```

---

## How to Test the Payload

### Step 1: Check What the App Sends
When you submit a report with a Google Drive image, check the console logs in Flutter:
```
📤 Sending payload to backend:
URL: http://192.168.100.12:8000/submit_report/
Payload: {
  "student_info": "...",
  "scan_date": "...",
  "violations": [...],
  "image_source": "drive_link",
  "image_url": "https://drive.google.com/file/d/..."
}
```

### Step 2: Check What Backend Receives
Add logging to your Django view:
```python
@csrf_exempt
def submit_report(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        print("📥 Received payload:")
        print(json.dumps(data, indent=2))
        # ... rest of code
```

Then check your terminal output.

### Step 3: Check What Database Stores
```bash
# In Django shell
python manage.py shell
```

```python
from yourapp.models import ViolationReport

# Get the last report
report = ViolationReport.objects.last()
print(f"Image URL: {report.image_url}")
print(f"Image Source: {report.image_source}")
print(f"Image Name: {report.image_name}")
```

---

## Comparison: Before vs After

| Field | Current Payload | Expected with Image |
|-------|-----------------|---------------------|
| student_info | ✅ Yes | ✅ Yes |
| scan_date | ✅ Yes | ✅ Yes |
| violations | ✅ Yes | ✅ Yes |
| image_url | ❌ No | ✅ Yes (if user adds) |
| image_source | ❌ No | ✅ Yes (if user adds) |
| image_name | ❌ No | ✅ Yes (if user adds) |

---

## Flow Diagram

```
User Action
    ↓
┌─────────────────────────┐
│ Tap "Open Google Drive" │
│ Copy image link         │
│ Paste in app field      │
│ Submit Report           │
└─────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ Flutter builds payload with:    │
│ - student_info                  │
│ - scan_date                     │
│ - violations                    │
│ - image_url (Google Drive link) │
│ - image_source: "drive_link"    │
└─────────────────────────────────┘
    ↓
┌────────────────────────────────────┐
│ Sends POST to Backend              │
│ http://192.168.100.12:8000/...     │
└────────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ Django view receives payload    │
│ Extracts all fields including   │
│ image_url, image_source         │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ ViolationReport.objects.create()│
│ Stores in MongoDB               │
└─────────────────────────────────┘
    ↓
┌─────────────────────────────────┐
│ Admin Website queries MongoDB   │
│ Retrieves image_url field       │
│ Displays image thumbnail        │
└─────────────────────────────────┘
```

---

## Key Points to Remember

1. **Mobile app is ready** - Already sends `image_url` ✅
2. **Backend needs update** - Must accept and store `image_url` ⏳
3. **Database needs update** - Must have `image_url` field ⏳
4. **Website needs update** - Must display `image_url` as image ⏳

---

## Summary

**Status**: 
- ✅ Flutter app: Ready to send image URLs
- ⏳ Backend: Needs to accept image URLs
- ⏳ Database: Needs image_url field
- ⏳ Website: Needs to display images

**Next Step**: Update your Django model and view to accept and store `image_url`


