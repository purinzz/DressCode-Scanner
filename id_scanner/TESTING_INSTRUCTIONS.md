# 🧪 Testing Instructions - Image Attachment Feature

## Overview
This guide will walk you through testing the new image attachment feature in the ID Scanner app.

---

## ✅ Pre-Testing Checklist

Before you begin testing, make sure you have:

- ✅ **Device**: CPH2773 (or any Android device with API 33+)
- ✅ **Internet Connection**: Required for Google Drive and backend
- ✅ **Google Account**: dresscodescanner@gmail.com (has access to the folder)
- ✅ **Backend Running**: `http://192.168.100.12:8000` accessible
- ✅ **Flutter Installed**: Run `flutter --version` to confirm
- ✅ **Project Dependencies**: Run `flutter pub get`

---

## 🚀 How to Build and Run

### Step 1: Prepare the Project
```bash
cd C:\Users\balaj\StudioProjects\id_scanner

# Clean previous builds
flutter clean

# Get latest dependencies
flutter pub get

# Check for errors
flutter analyze
```

### Step 2: Run on Device
```bash
# Connect your device via USB and enable USB debugging

# Run the app
flutter run

# Or with verbose output for debugging
flutter run -v
```

### Step 3: Wait for Build
The build process will take 2-5 minutes. You'll see:
- Gradle building
- APK compilation
- App installation
- App launch

---

## 🧪 Test Scenarios

### Test 1: Navigation to Report Page ✅

**Goal**: Verify the Report Page loads correctly

**Steps**:
1. Open the app
2. Login if needed
3. Tap the QR scanner button
4. Scan any QR code (or use test data if available)
5. Report Page should open with student info

**Expected Result**:
- ✅ Student information displayed
- ✅ Date/time shown
- ✅ Violation checkboxes visible
- ✅ "Attach Evidence Image (Optional)" section visible
- ✅ "Open Google Drive Folder" button visible

---

### Test 2: Open Google Drive Folder ✅

**Goal**: Verify the Google Drive folder opens in browser

**Steps**:
1. On Report Page, tap **"Open Google Drive Folder"** button
2. Wait 2-3 seconds for browser to open
3. Verify Google Drive folder loads
4. Look for image files in the folder

**Expected Result**:
- ✅ Browser opens (Chrome/Firefox/etc)
- ✅ Google Drive folder visible
- ✅ Images (PNG files) visible in folder
- ✅ Snackbar message appears with instructions
- ⏱️ Instructions snackbar message:
  ```
  📂 Opening Google Drive folder. Right-click on the image 
  and select "Get link" to copy the share link, 
  then paste it in the field below.
  ```

**If Browser Doesn't Open**:
- Check internet connection
- Verify `url_launcher` package is working
- Check device browser permissions
- Look in logcat for errors

---

### Test 3: Copy Image Link from Google Drive ✅

**Goal**: Get a shareable link for an image

**Steps**:
1. In the Google Drive folder (from Test 2)
2. Right-click on any PNG image
3. Select **"Get link"**
4. Verify sharing is set to "Anyone with the link"
5. Copy the link

**Expected Result**:
- ✅ Link dialog opens
- ✅ Link is shareable (not "Restricted")
- ✅ Link copied to clipboard
- ✅ Example link format:
  ```
  https://drive.google.com/file/d/1ABC123DEF456.../view?usp=sharing
  ```

**Troubleshooting**:
- If "Restricted": Change sharing to "Anyone with link"
- If link isn't sharing: Contact folder owner

---

### Test 4: Paste Image Link in App ✅

**Goal**: Verify image link can be pasted into the text field

**Steps**:
1. Return to app (Report Page should still be visible)
2. Locate **"Paste Image Link from Google Drive"** text field
3. Tap the text field
4. Paste the link you copied (Ctrl+V or long-press > Paste)
5. Verify link appears in field

**Expected Result**:
- ✅ Text field is active and editable
- ✅ Link appears in text field
- ✅ "Clear" button (X) appears on right side
- ✅ Link is intact and readable

**Example Visible Link**:
```
https://drive.google.com/file/d/1ABC123DEF456.../view?usp=sharing
```

---

### Test 5: Submit Report with Image Link ✅

**Goal**: Submit a report with an image link

**Steps**:
1. Select a violation (e.g., "Exposed Shoulders")
2. Paste an image link (from Test 4)
3. Tap **"Submit Report"** button
4. Wait for response

**Expected Result**:
- ✅ Success message appears:
  ```
  ✅ Report submitted successfully!
  ```
- ✅ App redirects to home screen after ~1 second
- ✅ No error messages

**If Error Appears**:
- Check backend is running: `http://192.168.100.12:8000`
- Verify network connection
- Check console logs for details
- See "Troubleshooting" section below

---

### Test 6: Submit Report without Image ✅

**Goal**: Verify reports can be submitted without images

**Steps**:
1. On Report Page, select a violation (e.g., "Exposed Navel")
2. Leave image link field empty
3. Tap **"Submit Report"** button
4. Wait for response

**Expected Result**:
- ✅ Success message appears
- ✅ App redirects to home screen
- ✅ Report submitted without image_url

---

### Test 7: Clear Image Link ✅

**Goal**: Test the clear button functionality

**Steps**:
1. Paste an image link in the text field
2. Verify "X" clear button appears on right side
3. Tap the "X" button
4. Verify field clears

**Expected Result**:
- ✅ Text field clears
- ✅ X button disappears
- ✅ Field is empty and ready for new input

---

### Test 8: Select "Others" Violation ✅

**Goal**: Test the "Others" violation type with custom text

**Steps**:
1. On Report Page, check the "Others:" checkbox
2. Text field appears for custom violation
3. Type custom violation (e.g., "Dirty uniform")
4. Paste an image link
5. Submit report

**Expected Result**:
- ✅ Text field appears when "Others" is checked
- ✅ Custom text is accepted
- ✅ Report submitted with custom violation and image
- ✅ Success message appears

---

### Test 9: Multiple Violations ✅

**Goal**: Test selecting multiple violations

**Steps**:
1. On Report Page, select multiple violations:
   - ✅ "Exposed Shoulders"
   - ✅ "Exposed Knees"
   - ☐ Others (optional)
2. Optionally add image link
3. Submit report

**Expected Result**:
- ✅ All selected violations are included in report
- ✅ Report submitted successfully
- ✅ Backend receives all violation types

---

### Test 10: Verify Backend Receives Image URL ✅

**Goal**: Confirm backend gets the image_url in payload

**Steps**:
1. Before submitting, check your backend logs/database
2. Submit a report with an image link
3. Check backend for received data

**Expected Payload**:
```json
{
  "student_info": "Student information",
  "scan_date": "2025-11-17T14:30:00.000000",
  "violations": ["Exposed Shoulders"],
  "image_source": "drive_link",
  "image_url": "https://drive.google.com/file/d/..."
}
```

**Backend Check**:
- Database should have `image_url` field with the Google Drive link
- Admin website should be able to access this URL

---

## 📊 Test Results Template

Use this table to track your testing:

| Test # | Scenario | Expected | Actual | Status |
|--------|----------|----------|--------|--------|
| 1 | Navigation to Report Page | Page loads | ? | ⏳ |
| 2 | Open Google Drive Folder | Browser opens | ? | ⏳ |
| 3 | Copy Image Link | Link copied | ? | ⏳ |
| 4 | Paste Image Link | Link in field | ? | ⏳ |
| 5 | Submit with Image | Success ✅ | ? | ⏳ |
| 6 | Submit without Image | Success ✅ | ? | ⏳ |
| 7 | Clear Image Link | Field clears | ? | ⏳ |
| 8 | Others Violation | Custom text works | ? | ⏳ |
| 9 | Multiple Violations | All included | ? | ⏳ |
| 10 | Backend Receives URL | image_url in DB | ? | ⏳ |

---

## 🐛 Troubleshooting

### Issue: "Could not open Google Drive"

**Cause**: Browser or URL launcher not working

**Solutions**:
1. Check internet connection
2. Verify device has a browser installed
3. Check app permissions for browser access
4. Try running `flutter run -v` to see detailed logs

**Logs to Check**:
```
I/UrlLauncher: component name for https://drive.google.com/...
E/UrlLauncher: Could not launch
```

---

### Issue: "No images found in Google Drive"

**Cause**: Images not visible or not in folder

**Solutions**:
1. Verify folder ID is correct: `1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi`
2. Check folder has images (PNG, JPG, WebP)
3. Verify sharing settings allow access
4. Try signing in with correct Google account

---

### Issue: "Could not open Google Drive" in Reports

**Cause**: Link share permissions

**Solutions**:
1. Ensure image link is shareable
2. Check link isn't "Restricted"
3. Try "Anyone with link" setting
4. Verify image file isn't deleted

---

### Issue: Backend Returns Error (400/500)

**Cause**: Backend not receiving data correctly

**Solutions**:
1. Check backend is running: `http://192.168.100.12:8000`
2. Verify network connectivity: Can you ping 192.168.100.12?
3. Check backend logs for errors
4. Verify payload structure matches backend expectations

**Test Connection**:
```bash
curl http://192.168.100.12:8000/submit_report/
```

---

### Issue: App Crashes After Submitting

**Cause**: Navigation or state error

**Solutions**:
1. Check console logs for stack trace
2. Run with verbose: `flutter run -v`
3. Check `report_page.dart` for errors
4. Verify all controllers are disposed

**Check Logs**:
```
flutter run -v 2>&1 | grep -E "(ERROR|Exception|FATAL)"
```

---

## 📱 Console Output to Expect

### Successful Google Drive Open:
```
I/UrlLauncher: Launching with mode: externalApplication
D/ViewRootImplExtImpl: the up motion event handled by client, just return
```

### Successful Report Submission:
```
I/Flutter: Report submitted successfully!
D/TransportRuntime: Storing event with priority=VERY_LOW
```

### Error Example:
```
E/Flutter: Network error: SocketException - Connection refused
```

---

## ✅ Sign-Off Checklist

After completing all tests, verify:

- ✅ All 10 test scenarios passed
- ✅ No critical errors in console
- ✅ Backend received image_url
- ✅ Images visible to admin on website
- ✅ Multiple reports submitted successfully
- ✅ App is stable and responsive
- ✅ No crashes or freezes

---

## 📝 When to Report Issues

Report issues if:
1. ❌ Browser won't open Google Drive
2. ❌ Image link won't paste in field
3. ❌ Backend returns error
4. ❌ App crashes during submission
5. ❌ Images don't appear on admin website
6. ❌ Performance issues (app slow/freezes)

---

## 🎯 Success Criteria

The feature is working correctly when:

✅ User can open Google Drive folder with one tap
✅ User can copy image links from Google Drive
✅ User can paste links into the app
✅ Reports submit successfully with image links
✅ Backend receives image_url in payload
✅ Admin website displays images from links
✅ App is stable and responsive
✅ No critical errors in console

---

## 📞 Need Help?

### Reference Documents
- `IMPLEMENTATION_COMPLETE.md` - Full technical details
- `QUICK_START.md` - Quick reference guide
- `FINAL_VERIFICATION_CHECKLIST.md` - Verification checklist

### Debugging Steps
1. Check console output with `flutter run -v`
2. Verify network: Can you access `http://192.168.100.12:8000`?
3. Check Google Drive folder: https://drive.google.com/drive/u/8/folders/1N_LlrzTw0epTco3j-WSdiN7M3eOwHnKi
4. Review backend logs for errors

---

**Happy Testing! 🎉**

**Status**: Ready to Test
**Date**: November 17, 2025
**Backend IP**: 192.168.100.12:8000
**Device**: CPH2773 (or any Android API 33+)

---

