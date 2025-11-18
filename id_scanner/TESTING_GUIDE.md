# Testing Guide - Google Drive Image Picker

## Quick Start - Test This First

### Step 1: Clean & Build
```powershell
cd C:\Users\balaj\StudioProjects\id_scanner
flutter clean
flutter pub get
flutter run
```

### Step 2: Verify Folder Access
Open this in browser to confirm folder has images:
```
https://drive.google.com/drive/folders/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi
```

### Step 3: Test the Feature
1. App loads → tap "Scan QR"
2. Point at any QR code
3. Scan result page → tap "Generate Report"
4. Select a violation (e.g., "Exposed Shoulders")
5. Tap "Add Image from Google Drive"
6. **Dialog opens and auto-loads images**
7. Select an image from the grid

### Step 4: Check Console Output

**Open Android Studio Logcat:**
- View → Tool Windows → Logcat (Alt+6)

**Look for these messages:**
- ✅ `Signed in as: dresscodescanner@gmail.com`
- 📂 `Target Folder ID: 1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi`
- 📄 `Fetching page 1...`
- `Found file in folder: [filename].png`
- 🖼️ `Image files found: 4` (or number of images)

## ✅ Expected Behavior

**Success Scenario:**
- Dialog shows 4 images in grid layout
- Clicking image shows preview
- Image included when submitting report

**Failure Scenario (Debugging):**
- If you see `📁 Total files in folder: 0`
  → Folder ID or permissions issue
  → Try "Open in Google Drive" button
  
- If you see `🖼️ Image files found: 0` but files in folder exist
  → File MIME types might be different
  → Check in console what MIME types are shown
  
## 🔍 Debug Console Messages Reference

| Message | Meaning |
|---------|---------|
| 🚀 Starting Google Drive image fetch... | Request started |
| ✅ Signed in as: [email] | Authentication successful |
| 📄 Fetching page 1... | Retrieving Drive files |
| 📋 Page 1 has X files | Files retrieved from Drive |
| ✅ Found file in folder: [name] | File is in target folder |
| 🖼️ Image file: [name] | File is valid image format |
| 🖼️ Image files found: 4 | Ready to display images |
| ❌ User not signed in | Need to sign in first |
| ⚠️ No files in this page | Issue with Drive API call |

## If Images Don't Load

1. **First attempt**: Click "Retry" button in dialog
2. **Second attempt**: Check Google account
   - Click dialog close (X)
   - Sign out (Settings page)
   - Try again with correct account
3. **Manual check**: Click "Open in Google Drive" button
   - Browser opens folder
   - Verify images are there and readable
4. **Last resort**: Check console for error messages
   - Share the console output

## 📋 Test Checklist

- [ ] App builds successfully
- [ ] Can authenticate with Google
- [ ] Folder opens in browser (manual check)
- [ ] Dialog appears when tapping "Add Image"
- [ ] Dialog shows loading spinner briefly
- [ ] Images appear in grid (or error message)
- [ ] Can select an image
- [ ] Preview shows selected image
- [ ] Report submits with image attached
- [ ] Backend receives image ID/URL

## 🆘 Common Issues

**Issue**: "Build failed after dependencies"
- **Solution**: Run `flutter clean` then `flutter pub get`

**Issue**: Dialog shows but never loads images
- **Solution**: Check Logcat for errors starting with ❌
- **Likely cause**: Authentication timeout or permission issue

**Issue**: See files but not images
- **Solution**: Check console output for MIME types
- PNG/JPG/WebP are supported, other formats ignored

**Issue**: Images load sometimes, fail other times
- **Solution**: Could be timeout issue
- Try clicking "Retry" button

## 📞 Information to Share If Issues Persist

Gather these from console and share:
1. **Logcat output** from the moment you tap "Add Image" button
2. **Google account email** being used
3. **Number of images** showing in Google Drive folder (manual check)
4. **Device model** (CPH2773 ← this one)
5. **Any error messages** starting with ❌

---

**Backend Configuration**: http://192.168.100.12:8000
**Folder Owner**: dresscodescanner@gmail.com
**Supported Image Formats**: PNG, JPG, WebP

