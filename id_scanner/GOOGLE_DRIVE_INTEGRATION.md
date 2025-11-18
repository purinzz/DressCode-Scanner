# Google Drive Image Integration for ID Scanner

## Overview
This implementation adds the ability to attach images from Google Drive to violation reports. Users can select an image from their Google Drive, preview it, and submit it along with the violation report.

## Features

### 1. **Google Drive Image Picker**
- Dialog-based image selector
- Displays thumbnails of images from Google Drive
- Supports JPG, PNG, and WebP formats
- Grid layout for easy browsing

### 2. **Image Preview**
- Shows selected image with filename
- Option to remove/change image before submitting
- Loading and error handling for network images

### 3. **Report Submission with Image**
- Image metadata (ID, URL, name) included in report submission
- Image URL is accessible by the admin website
- Maintains all existing violation data

## Setup Instructions

### Prerequisites
- Google Account with Google Drive access
- Flutter project with dependencies already added:
  - `google_sign_in: ^6.1.0`
  - `googleapis: ^11.0.0`

### Flutter Configuration

#### Android (`android/app/build.gradle`)
```gradle
dependencies {
    // Ensure Google Play Services are included
    implementation 'com.google.android.gms:play-services-auth:20.5.0'
}
```

#### iOS (`ios/Runner/Info.plist`)
Add the following keys:
```xml
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>YOUR_GOOGLE_SERVER_CLIENT_ID.apps.googleusercontent.com</string>
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>com.google.gms.mobilesafety</string>
</array>
```

#### Web (`web/index.html`)
Add Google API script:
```html
<script src="https://apis.google.com/js/platform.js" async defer></script>
<meta name="google-signin-client_id" content="YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com">
```

## Backend Integration

### Expected Report Data Format
When a report is submitted with an image, the JSON payload includes:

```json
{
  "student_info": "John Doe - ID: 123456",
  "scan_date": "2025-11-16T14:30:00.000Z",
  "violations": ["Exposed Shoulders", "Exposed Knees"],
  "image_id": "GOOGLE_DRIVE_FILE_ID",
  "image_url": "https://drive.google.com/uc?export=view&id=GOOGLE_DRIVE_FILE_ID",
  "image_name": "evidence_photo.jpg"
}
```

### Backend Requirements
1. **Store Image URL**: Save the `image_url` in the database for the report
2. **Optional: Download Image**: You can use the `image_id` to download and store locally if needed
3. **Display on Admin Panel**: Use the `image_url` to display the image in the violations table

### Example Backend Updates (Python/Django)

#### Models
```python
class ViolationReport(models.Model):
    student_info = models.CharField(max_length=255)
    scan_date = models.DateTimeField()
    violations = models.JSONField()
    image_id = models.CharField(max_length=255, null=True, blank=True)
    image_url = models.URLField(null=True, blank=True)
    image_name = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

#### View
```python
@csrf_exempt
def submit_report(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        report = ViolationReport.objects.create(
            student_info=data.get('student_info'),
            scan_date=data.get('scan_date'),
            violations=data.get('violations'),
            image_id=data.get('image_id'),
            image_url=data.get('image_url'),
            image_name=data.get('image_name'),
        )
        return JsonResponse({'status': 'success', 'id': report.id})
```

#### Admin Panel Display
```html
<!-- In your violations table -->
<td>
  {% if report.image_url %}
    <img src="{{ report.image_url }}" alt="Evidence" style="max-width: 200px; cursor: pointer;" onclick="viewImage('{{ report.image_url }}')">
  {% else %}
    <span>No image</span>
  {% endif %}
</td>
```

## File Structure

```
lib/
├── report_page.dart                          # Updated with image picker
├── services/
│   ├── google_drive_service.dart            # Google Drive API service
│   └── google_drive_image_picker.dart       # Image picker dialog widget
```

## Usage Flow

1. **Create Report**: User opens report page and fills in violation details
2. **Add Image**: Click "Add Image from Google Drive" button
3. **Select Image**: Dialog appears with Google Drive images
4. **Preview**: Selected image is displayed with option to remove
5. **Submit**: Report with image is submitted to backend

## Security Considerations

1. **Google Drive Link**: The image URL uses Google Drive's public sharing mechanism
2. **Permissions**: Ensure users share images with appropriate permissions
3. **Access**: The image is accessible as long as the Google Drive link remains valid
4. **Data Storage**: Store only the URL reference, not the image itself

## Troubleshooting

### Images Not Loading
- Check Google Drive file permissions
- Verify network connection
- Ensure file is shared publicly or with OSA admin

### Google Sign-In Fails
- Verify Google Client IDs are correctly configured
- Check platform-specific permissions (Android/iOS)
- Ensure device has Google Play Services installed

### Authorization Errors
- User must sign in with Google account
- Verify Drive API scope is enabled
- Check if user has access to Google Drive

## Future Enhancements

1. Filter images by folder
2. Search functionality within Google Drive
3. Image upload directly from device
4. Multiple image attachment per report
5. Image compression before submission

