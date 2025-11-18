# 🛠️ Backend Implementation - Code Snippets

## Django Model Update

### Location: `your_app/models.py`

```python
from django.db import models
from django.core.validators import URLValidator
from bson import ObjectId

class ViolationReport(models.Model):
    """
    Report model to store student violation records with optional image evidence.
    """
    _id = models.ObjectIdField(primary_key=True, default=ObjectId)
    
    # Core fields (existing)
    student_info = models.TextField(
        help_text="Student ID, Name, and Course info"
    )
    violation = models.TextField(
        help_text="Comma-separated list of violations"
    )
    no_of_offense = models.IntegerField(
        default=0,
        help_text="Number of times this student has violated"
    )
    scanned_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When the report was created"
    )
    image_path = models.CharField(
        max_length=255, 
        null=True, 
        blank=True,
        help_text="Legacy field - for local file paths"
    )
    submitted_by = models.CharField(
        max_length=100,
        default="Anonymous",
        help_text="Who submitted the report"
    )
    isDeleted = models.BooleanField(
        default=False,
        help_text="Soft delete flag"
    )
    
    # ===== NEW FIELDS FOR IMAGE SUPPORT =====
    image_url = models.URLField(
        max_length=500,
        null=True,
        blank=True,
        default=None,
        help_text="Google Drive image link or external image URL"
    )
    image_source = models.CharField(
        max_length=50,
        choices=[
            ('drive_link', 'Google Drive Link'),
            ('local', 'Local Upload'),
            ('base64', 'Base64 Encoded'),
        ],
        null=True,
        blank=True,
        default=None,
        help_text="Source of the image (where it came from)"
    )
    image_name = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        default=None,
        help_text="Original name of the image file"
    )
    # ===== END NEW FIELDS =====
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'violation_reports'
        ordering = ['-scanned_at']
        indexes = [
            models.Index(fields=['-scanned_at']),
            models.Index(fields=['student_info']),
        ]
    
    def __str__(self):
        return f"Report: {self.student_info} - {self.violation}"
    
    def has_image(self):
        """Check if report has any image attached"""
        return bool(self.image_url or self.image_path)
    
    def get_image_url(self):
        """Get the appropriate image URL for display"""
        if self.image_source == 'drive_link' and self.image_url:
            return self.image_url
        elif self.image_source == 'local' and self.image_path:
            return f"/media/{self.image_path}"
        return None
```

---

## Django View Update

### Location: `your_app/views.py`

```python
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
import logging

logger = logging.getLogger(__name__)

@csrf_exempt
@require_http_methods(["POST"])
def submit_report(request):
    """
    Submit a new violation report with optional image evidence.
    
    Expected payload:
    {
        "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
        "scan_date": "2025-11-17T15:45:00.000Z",
        "violations": ["Exposed Shoulders", "Exposed Knees"],
        "image_url": "https://drive.google.com/file/d/...",  # Optional
        "image_source": "drive_link",  # Optional: "drive_link", "local", "base64"
        "image_name": "evidence.png"  # Optional
    }
    """
    try:
        # Parse request body
        data = json.loads(request.body)
        
        # Log received data
        logger.info(f"📥 Received report submission:")
        logger.info(f"   Student: {data.get('student_info')[:50]}...")
        logger.info(f"   Violations: {data.get('violations')}")
        logger.info(f"   Image URL: {data.get('image_url', 'None')[:80]}..." if data.get('image_url') else "   Image URL: None")
        
        # Validate required fields
        required_fields = ['student_info', 'scan_date', 'violations']
        for field in required_fields:
            if not data.get(field):
                return JsonResponse({
                    'status': 'error',
                    'message': f'Missing required field: {field}'
                }, status=400)
        
        # Extract fields
        student_info = data.get('student_info').strip()
        scan_date = data.get('scan_date')
        violations = data.get('violations')
        image_url = data.get('image_url', '').strip() or None
        image_source = data.get('image_source', None)
        image_name = data.get('image_name', '').strip() or None
        
        # Validate violations is a list
        if not isinstance(violations, list) or len(violations) == 0:
            return JsonResponse({
                'status': 'error',
                'message': 'Violations must be a non-empty list'
            }, status=400)
        
        # Validate image_url if provided
        if image_url and not image_url.startswith('http'):
            return JsonResponse({
                'status': 'error',
                'message': 'Invalid image URL format'
            }, status=400)
        
        # Create report
        report = ViolationReport.objects.create(
            student_info=student_info,
            scan_date=scan_date,
            violations=violations,
            image_url=image_url,
            image_source=image_source,
            image_name=image_name,
            submitted_by=data.get('submitted_by', 'Anonymous'),
        )
        
        logger.info(f"✅ Report created successfully: {report._id}")
        
        return JsonResponse({
            'status': 'success',
            'message': 'Report submitted successfully',
            'id': str(report._id),
            'has_image': bool(image_url)
        }, status=201)
        
    except json.JSONDecodeError:
        logger.error("❌ Invalid JSON received")
        return JsonResponse({
            'status': 'error',
            'message': 'Invalid JSON format'
        }, status=400)
    
    except Exception as e:
        logger.error(f"❌ Error creating report: {str(e)}")
        return JsonResponse({
            'status': 'error',
            'message': f'Server error: {str(e)}'
        }, status=500)


@csrf_exempt
def get_reports(request):
    """
    Retrieve all violation reports (for admin panel).
    """
    try:
        reports = ViolationReport.objects.filter(isDeleted=False).order_by('-scanned_at')
        
        data = []
        for report in reports:
            data.append({
                'id': str(report._id),
                'student_info': report.student_info,
                'violations': report.violation,
                'scan_date': report.scanned_at.isoformat(),
                'image_url': report.image_url,
                'image_source': report.image_source,
                'image_name': report.image_name,
                'submitted_by': report.submitted_by,
                'no_of_offense': report.no_of_offense,
            })
        
        return JsonResponse({
            'status': 'success',
            'count': len(data),
            'data': data
        })
    
    except Exception as e:
        logger.error(f"❌ Error fetching reports: {str(e)}")
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)


@csrf_exempt
def get_report_detail(request, report_id):
    """
    Get a single report with full details including image.
    """
    try:
        report = ViolationReport.objects.get(_id=report_id, isDeleted=False)
        
        return JsonResponse({
            'status': 'success',
            'data': {
                'id': str(report._id),
                'student_info': report.student_info,
                'violations': report.violation,
                'scan_date': report.scanned_at.isoformat(),
                'image_url': report.image_url,
                'image_source': report.image_source,
                'image_name': report.image_name,
                'image_display_url': report.get_image_url(),
                'submitted_by': report.submitted_by,
                'no_of_offense': report.no_of_offense,
            }
        })
    
    except ViolationReport.DoesNotExist:
        return JsonResponse({
            'status': 'error',
            'message': 'Report not found'
        }, status=404)
    
    except Exception as e:
        logger.error(f"❌ Error fetching report detail: {str(e)}")
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)
```

---

## Django Serializer (Optional but Recommended)

### Location: `your_app/serializers.py`

```python
from rest_framework import serializers
from .models import ViolationReport

class ViolationReportSerializer(serializers.ModelSerializer):
    id = serializers.SerializerMethodField()
    
    class Meta:
        model = ViolationReport
        fields = [
            'id',
            'student_info',
            'violation',
            'no_of_offense',
            'scanned_at',
            'image_url',
            'image_source',
            'image_name',
            'submitted_by',
            'isDeleted',
        ]
        read_only_fields = ['id', 'scanned_at']
    
    def get_id(self, obj):
        return str(obj._id)
    
    def validate_image_url(self, value):
        if value and not value.startswith('http'):
            raise serializers.ValidationError("Invalid image URL format")
        return value
    
    def validate_image_source(self, value):
        valid_sources = ['drive_link', 'local', 'base64']
        if value and value not in valid_sources:
            raise serializers.ValidationError(
                f"Image source must be one of: {', '.join(valid_sources)}"
            )
        return value
```

---

## Migration Commands

```bash
# Step 1: Create migration file
python manage.py makemigrations

# Step 2: Review migration file
cat yourapp/migrations/000X_auto_YYYYMMDD_HHMM.py

# Step 3: Apply migration
python manage.py migrate

# Step 4: Verify migration
python manage.py showmigrations

# Step 5: Check database
python manage.py shell
```

### In Django Shell:
```python
from yourapp.models import ViolationReport
from django.db import connection

# Check if fields exist
cursor = connection.cursor()
cursor.execute("""
    PRAGMA table_info(violation_reports);
""")
columns = cursor.fetchall()
for col in columns:
    print(col)

# Or for MongoDB
db = ViolationReport._meta.database
collection = db['violation_reports']
print(collection.find_one())
```

---

## URL Configuration

### Location: `urls.py`

```python
from django.urls import path
from . import views

urlpatterns = [
    # ... existing URLs ...
    
    # Report endpoints with image support
    path('submit_report/', views.submit_report, name='submit_report'),
    path('get_reports/', views.get_reports, name='get_reports'),
    path('get_report/<str:report_id>/', views.get_report_detail, name='get_report_detail'),
    
    # ... more URLs ...
]
```

---

## Testing with cURL

```bash
# Test 1: Without image
curl -X POST http://192.168.100.12:8000/submit_report/ \
  -H "Content-Type: application/json" \
  -d '{
    "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
    "scan_date": "2025-11-17T15:45:00.000Z",
    "violations": ["Exposed Shoulders"],
    "submitted_by": "Anonymous"
  }'

# Test 2: With Google Drive image
curl -X POST http://192.168.100.12:8000/submit_report/ \
  -H "Content-Type: application/json" \
  -d '{
    "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
    "scan_date": "2025-11-17T15:45:00.000Z",
    "violations": ["Exposed Shoulders", "Exposed Knees"],
    "image_url": "https://drive.google.com/file/d/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi/view?usp=sharing",
    "image_source": "drive_link",
    "image_name": "evidence.png",
    "submitted_by": "Anonymous"
  }'

# Test 3: Fetch all reports
curl http://192.168.100.12:8000/get_reports/

# Test 4: Get single report
curl http://192.168.100.12:8000/get_report/691a8fc4f69fb08df936b636/
```

---

## Expected Response

### Success (201 Created):
```json
{
  "status": "success",
  "message": "Report submitted successfully",
  "id": "691a8fc4f69fb08df936b640",
  "has_image": true
}
```

### Error (400 Bad Request):
```json
{
  "status": "error",
  "message": "Invalid image URL format"
}
```

### Error (500 Server Error):
```json
{
  "status": "error",
  "message": "Server error: Database connection failed"
}
```

---

## Logging Configuration

### Location: `settings.py`

```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '[{levelname}] {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': 'reports.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'yourapp': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
    },
}
```

---

## Debugging Tips

### Check if migration ran:
```bash
python manage.py showmigrations
# Should show: [X] yourapp 000X_add_image_fields
```

### Check if fields exist in database:
```bash
python manage.py shell
from django.db import connection
cursor = connection.cursor()
cursor.execute("PRAGMA table_info(violation_reports)")
print(cursor.fetchall())
```

### Test the view directly:
```bash
python manage.py runserver 192.168.100.12:8000
# In another terminal:
curl -X POST http://192.168.100.12:8000/submit_report/ \
  -H "Content-Type: application/json" \
  -d '{"student_info":"Test","scan_date":"2025-11-17T15:45:00Z","violations":["Test"]}'
```

---

## Checklist

- [ ] Add new fields to ViolationReport model
- [ ] Run `makemigrations`
- [ ] Run `migrate`
- [ ] Update `submit_report` view to accept image fields
- [ ] Test with cURL (without image first)
- [ ] Test with cURL (with image)
- [ ] Verify database has image_url field
- [ ] Restart backend server
- [ ] Test with mobile app
- [ ] Check admin panel can display images

---

**Ready to implement?** Start with Step 1: Add the fields to your model.


