# 📸 Image URL Database Update Guide

## Current Situation

Your current database structure stores reports like this:
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

## ✅ What Needs to Be Added

### 1. **New Database Fields**

Add these fields to your ViolationReport model:

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `image_url` | String | Google Drive image link | `https://drive.google.com/file/d/1ABC123/view?usp=sharing` |
| `image_source` | String | Track where image came from | `"drive_link"` or `"local"` |
| `image_name` | String | Name of uploaded image | `"evidence_photo_001.png"` |

### 2. **Updated Database Structure**

After adding the fields:
```json
{
  "_id": "691a8fc4f69fb08df936b636",
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "violation": "Exposed Shoulders, Exposed Knees",
  "no_of_offense": 16,
  "scanned_at": "2025-11-17T03:00:20.261+00:00",
  "image_path": null,
  "image_url": "https://drive.google.com/file/d/1ABC123/view?usp=sharing",
  "image_source": "drive_link",
  "image_name": "evidence_photo.png",
  "submitted_by": "Anonymous",
  "isDeleted": false
}
```

---

## 🔧 Backend Changes Required

### Django Model Update

Your `ViolationReport` model needs these new fields:

```python
class ViolationReport(models.Model):
    # ... existing fields ...
    
    # NEW FIELDS FOR IMAGE SUPPORT
    image_url = models.URLField(
        max_length=500, 
        null=True, 
        blank=True,
        help_text="Google Drive image link"
    )
    image_source = models.CharField(
        max_length=50,
        choices=[
            ('drive_link', 'Google Drive Link'),
            ('local', 'Local Upload'),
        ],
        null=True,
        blank=True,
        default=None
    )
    image_name = models.CharField(
        max_length=255,
        null=True,
        blank=True,
        help_text="Name of the image file"
    )
    
    class Meta:
        db_table = 'violation_reports'
        ordering = ['-scanned_at']
```

### Migration Steps

```bash
# 1. Create migration
python manage.py makemigrations

# 2. Apply migration
python manage.py migrate

# 3. Verify in database
# Check that image_url, image_source, image_name fields exist
```

### Update Views (submit_report endpoint)

```python
@csrf_exempt
def submit_report(request):
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            
            # Create report with image fields
            report = ViolationReport.objects.create(
                student_info=data.get('student_info'),
                scan_date=data.get('scan_date'),
                violations=data.get('violations'),
                # NEW FIELDS
                image_url=data.get('image_url'),
                image_source=data.get('image_source'),
                image_name=data.get('image_name'),
            )
            
            return JsonResponse({
                'status': 'success', 
                'id': str(report.id),
                'message': 'Report submitted successfully'
            })
        except Exception as e:
            return JsonResponse({
                'status': 'error',
                'message': str(e)
            }, status=400)
```

---

## 💻 Frontend (Flutter) - Already Updated ✅

Your Flutter app (`report_page.dart`) already sends:

```dart
final payload = <String, dynamic>{
  "student_info": widget.studentInfo,
  "scan_date": widget.scanDate.toIso8601String(),
  "violations": selectedViolations,
};

// If a Google Drive link is provided
if (_driveImageLinkController.text.trim().isNotEmpty) {
  payload.addAll({
    "image_source": "drive_link",
    "image_url": _driveImageLinkController.text.trim(),
  });
}

// If a local file was picked
if (_pickedImageBytes != null) {
  payload.addAll({
    "image_source": "local",
    "image_name": _pickedImageName ?? 'picked_image',
    "image_base64": base64Encode(_pickedImageBytes!),
  });
}
```

---

## 🌐 Website Display - How to Show Images

### Admin Panel (Django Template)

```html
{% if report.image_url %}
  <a href="{{ report.image_url }}" target="_blank" title="View Evidence Image">
    <img src="{{ report.image_url }}" alt="Evidence" 
         style="max-width: 200px; height: auto; cursor: pointer; border-radius: 4px;">
  </a>
{% elif report.image_name %}
  <img src="/media/{{ report.image_name }}" alt="Evidence" 
       style="max-width: 200px; height: auto;">
{% else %}
  <span style="color: #999;">No image</span>
{% endif %}
```

### Table Display with Icons

```html
<td class="text-center">
  {% if report.image_source == "drive_link" %}
    <a href="{{ report.image_url }}" target="_blank" class="btn btn-sm btn-info">
      <i class="fab fa-google"></i> View Drive Image
    </a>
  {% elif report.image_source == "local" %}
    <img src="/media/{{ report.image_name }}" alt="Local image" 
         style="max-width: 150px; cursor: pointer;" 
         onclick="showImageModal('{{ report.image_name }}')">
  {% else %}
    <span class="badge badge-secondary">No Image</span>
  {% endif %}
</td>
```

---

## ✅ Step-by-Step Implementation

### Step 1: Update Django Model
- [ ] Add `image_url` field
- [ ] Add `image_source` field  
- [ ] Add `image_name` field
- [ ] Create migration: `python manage.py makemigrations`
- [ ] Run migration: `python manage.py migrate`

### Step 2: Update View
- [ ] Update `submit_report` view to accept new fields
- [ ] Test endpoint with POST request

### Step 3: Update Admin Panel
- [ ] Add image display to violations table
- [ ] Make images clickable to open in new tab
- [ ] Add fallback for missing images

### Step 4: Test End-to-End
- [ ] Submit report with Google Drive image URL
- [ ] Verify image URL stored in database
- [ ] Check admin panel displays image
- [ ] Verify image opens when clicked

---

## 🔍 Verification Checklist

After implementing, verify:

- [ ] Database has new fields (image_url, image_source, image_name)
- [ ] `/submit_report/` endpoint accepts image_url
- [ ] Reports with image_url save successfully
- [ ] Admin panel shows images from Google Drive links
- [ ] Images are clickable and open in new tab
- [ ] Reports without images still work
- [ ] Error handling for invalid image URLs

---

## 📊 Example Payload Being Sent

### With Google Drive Image:
```json
{
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "scan_date": "2025-11-17T15:45:00.000Z",
  "violations": ["Exposed Shoulders", "Exposed Knees"],
  "image_source": "drive_link",
  "image_url": "https://drive.google.com/file/d/1ABC123DEF456/view?usp=sharing"
}
```

### Without Image:
```json
{
  "student_info": "JOSEPH VON A. BALA\t2022301109\tBSIT",
  "scan_date": "2025-11-17T15:45:00.000Z",
  "violations": ["Exposed Shoulders"]
}
```

---

## 🚀 Commands to Run (Backend)

```bash
# Navigate to backend project
cd path/to/backend

# Make migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Check migration status
python manage.py showmigrations

# Verify data
python manage.py shell
# In shell: ViolationReport.objects.first()
# Should show all fields including image_url

# Restart server
python manage.py runserver 192.168.100.12:8000
```

---

## 🎯 Success Indicators

You'll know it's working when:

✅ Mobile app submits report with image_url
✅ Backend receives and stores image_url
✅ Database shows image_url field populated
✅ Admin website displays the image
✅ Clicking image opens Google Drive in new tab
✅ Reports without images still work normally

---

## 📝 Notes

- Images are stored as **links only**, not as files on the server
- Google Drive links remain valid as long as the image file exists and sharing is enabled
- If image is deleted from Google Drive, the link will become invalid (show broken image)
- Consider adding image validation/proxy if you want more control

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| Image URL stored as null | Check backend is receiving the field |
| Backend returns 400 error | Verify payload structure matches model |
| Admin panel shows broken image | Check Google Drive link is still valid and shared |
| Images not visible in admin | Check Django settings allow external URLs |

---

**Status**: Ready to Implement
**Last Updated**: November 17, 2025


