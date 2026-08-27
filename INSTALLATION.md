# 📦 COMPLETE INSTALLATION GUIDE v2.0

Step-by-step guide to get your enhanced Sentinel Rover app running with all new features!

## 🎯 What You'll Have After Setup

✅ Flutter app with real Google Maps  
✅ Bluetooth connectivity to rover  
✅ Live camera streaming  
✅ Distance tracking  
✅ Real-time threat detection  
✅ Auto-alert system  
✅ Professional tactical UI  

---

## 📋 Prerequisites

### Required Software
- Flutter SDK 3.0+ ([Install Guide](https://docs.flutter.dev/get-started/install))
- Node.js 16+ ([Download](https://nodejs.org/))
- Git
- Android Studio (for Android) OR Xcode (for iOS)
- Google Cloud account (for Maps API key)

### Check Your Setup
```bash
flutter doctor
node --version
npm --version
```

---

## 🚀 PART 1: Backend Setup (5 minutes)

### Step 1: Install Dependencies
```bash
cd sentinel-rover-app/backend
npm install
```

### Step 2: Configure Environment
```bash
cp .env.template .env
# Edit .env with your settings (optional for testing)
```

### Step 3: Start Server
```bash
npm start
```

**✅ Success looks like:**
```
╔════════════════════════════════════════╗
║   SENTINEL ROVER DEFENSE SYSTEM API    ║
╚════════════════════════════════════════╝

🚀 Server running on port 3000
📡 WebSocket endpoint: ws://localhost:3000
System Status: ONLINE ✓
```

### Step 4: Test API
Open browser: `http://localhost:3000/api/health`

You should see JSON response with rover data.

---

## 📱 PART 2: Flutter App Setup (10 minutes)

### Step 1: Get Dependencies
```bash
cd sentinel-rover-app
flutter pub get
```

### Step 2: Get Google Maps API Key

#### For Android:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create new project: "Sentinel Rover"
3. Enable APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if using iOS)
4. Create Credentials → API Key
5. Copy your API key

#### For iOS:
- Same as above, but enable "Maps SDK for iOS"

### Step 3: Configure Android

**File:** `android/app/src/main/AndroidManifest.xml`

Add inside `<application>` tag:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

See `android_config.md` for complete configuration.

### Step 4: Configure iOS

**File:** `ios/Runner/Info.plist`

Add:
```xml
<key>GMSApiKey</key>
<string>YOUR_API_KEY_HERE</string>
```

Then install pods:
```bash
cd ios
pod install
cd ..
```

See `ios_config.md` for complete configuration.

### Step 5: Update Backend URL (if needed)

**File:** `lib/services/websocket_service.dart`

Line ~48, change if not using localhost:
```dart
socket = IO.io(
  'http://YOUR_COMPUTER_IP:3000',  // Replace with your IP
  ...
);
```

To find your IP:
- **Mac/Linux**: `ifconfig | grep inet`
- **Windows**: `ipconfig`

### Step 6: Run the App!

```bash
# For Android
flutter run -d android

# For iOS  
flutter run -d ios

# For web (testing only - limited features)
flutter run -d chrome
```

---

## 🎮 PART 3: First Launch & Testing

### Expected Flow:

#### 1. Splash Screen (3 seconds)
- Animated logo with grid background
- "Initializing Defense Protocol..."

#### 2. Login Screen
- Username: anything
- Password: anything  
- Tap "AUTHENTICATE"

#### 3. Dashboard Loads
- Check **GREEN "ONLINE"** indicator (top right)
- Should see "Threat Level: LOW"

### Test Each Feature:

#### ✅ Camera Feed (Overview Tab)
- Should see "LIVE" badge
- Connection mode shown
- Camera controls at bottom

**If black screen:**
- Backend must be running
- Check URL in `live_camera_feed.dart`
- Test in browser: `http://localhost:3000/camera/stream`

#### ✅ Google Maps (Map Tab)
- Real satellite imagery loads
- Cyan rover marker in center
- Detection radius circle (500m)
- Map controls at bottom

**If maps don't load:**
- Verify API key is correct
- Check API is enabled in Google Cloud
- Look for errors in console

#### ✅ Bluetooth (Connection Mode)
- Tap connection mode selector
- Switch to "BLUETOOTH"
- Tap "SCAN FOR ROVERS"

**If scan fails:**
- Enable Bluetooth on phone
- Enable location services (required for BLE!)
- Check permissions granted

#### ✅ Distance Tracking
- Look at Rover Status Card
- Should see "DISTANCE: 0 m"
- Increases as rover moves (simulated in demo)
- Also visible on map (top-left card)

#### ✅ Threat Detection
- Auto-generated every 10 seconds (demo mode)
- Appears on map as colored markers
- Shows in Recent Detections list
- Threat counter updates (top-right on map)

---

## 🔧 PART 4: Troubleshooting

### Backend Won't Start

**Error: Port 3000 in use**
```bash
# Kill process using port 3000
lsof -ti:3000 | xargs kill -9  # Mac/Linux
netstat -ano | findstr :3000   # Windows
```

Or change port in `backend/server.js`:
```javascript
const PORT = process.env.PORT || 3001;
```

**Error: Module not found**
```bash
rm -rf node_modules package-lock.json
npm install
```

### Flutter App Issues

**Error: Packages not found**
```bash
flutter clean
flutter pub get
```

**Error: WebSocket connection failed**
- Ensure backend is running
- Check firewall allows port 3000
- Use computer's IP address, not localhost (for devices)

**Error: Google Maps not loading**
- Verify API key in manifest files
- Enable billing on Google Cloud (free tier OK)
- Check API is enabled

**Error: Bluetooth permissions**
```bash
# iOS - edit Info.plist with bluetooth usage descriptions
# Android - check AndroidManifest.xml has bluetooth permissions
```

### Camera Stream Issues

**Black screen on camera:**
- Backend must be running
- Check endpoint: `/camera/stream`
- Test in browser first
- Verify internet connection

**High latency:**
- Switch to Bluetooth mode
- Reduce FPS in backend
- Check WiFi signal strength

### Map Issues

**Markers not appearing:**
- Wait for backend to generate threats (10s interval)
- Check WebSocket connection (green status)
- Look at console for errors

**Path not drawing:**
- GPS must update (simulated in demo)
- Check location permissions
- Enable location services

---

## 🎨 PART 5: Customization

### Change Colors

**File:** `lib/main.dart`

```dart
primaryColor: const Color(0xFFFF3366),  // Threat Red
secondary: const Color(0xFF00F5FF),     // Cyber Blue
```

### Change App Name

**File:** `pubspec.yaml`
```yaml
name: your_app_name
description: Your custom description
```

**Android:** `android/app/src/main/AndroidManifest.xml`
```xml
android:label="Your App Name"
```

**iOS:** `ios/Runner/Info.plist`
```xml
<key>CFBundleName</key>
<string>Your App Name</string>
```

### Adjust Detection Radius

**File:** `lib/widgets/real_time_threat_map.dart`

Line ~180:
```dart
radius: 500, // Change from 500 to your value (in meters)
```

### Change Camera FPS

**File:** `lib/widgets/live_camera_feed.dart`

Line ~64:
```dart
await Future.delayed(const Duration(milliseconds: 100)); // 10 FPS
// Change to 33ms for 30 FPS, 50ms for 20 FPS, etc.
```

---

## 🔌 PART 6: Hardware Integration (Optional)

If you have actual rover hardware:

### 1. Flash ESP32 Firmware
See `HARDWARE_INTEGRATION.md` for:
- Complete Arduino/PlatformIO code
- BLE server implementation
- Camera setup
- GPS integration

### 2. Connect via Bluetooth
- Power on ESP32
- App → Bluetooth mode
- Scan & connect
- Real telemetry starts flowing!

### 3. Test Camera Stream
- ESP32-CAM setup in docs
- Stream to app via WiFi
- Or send frames via Bluetooth

---

## 📊 PART 7: Performance Optimization

### For Best Performance:

1. **Use Bluetooth for local control** (lowest latency)
2. **Use WiFi for camera** (better bandwidth)
3. **Enable satellite view sparingly** (uses more data)
4. **Clear rover path regularly** (reduces memory)
5. **Close background apps** (more resources)

### Recommended Settings:
- Camera: 720p @ 20 FPS (balance quality/performance)
- GPS: 1 Hz update rate
- Map: Hybrid view for best visibility
- Detection radius: 500m (adjustable)

---

## ✅ Final Checklist

Before declaring victory:

- [ ] Backend running and responding
- [ ] App installed on device/emulator
- [ ] GREEN "ONLINE" status showing
- [ ] Camera feed visible (even if black)
- [ ] Google Maps loading
- [ ] Can see rover marker on map
- [ ] Bluetooth scan works
- [ ] Distance counter visible
- [ ] Threats appearing automatically
- [ ] Map controls functioning

**All checked?** You're ready to dominate! 🎉

---

## 🚀 Next Steps

1. **Read NEW_FEATURES.md** for feature deep-dive
2. **Check HARDWARE_INTEGRATION.md** for ESP32 setup
3. **Deploy backend** to cloud (Heroku/AWS/DigitalOcean)
4. **Build app** for production: `flutter build apk/ios`
5. **Customize** colors, icons, and features
6. **Add real rover** hardware
7. **Test in field** conditions

---

## 📚 Documentation Index

- `README.md` - Main documentation
- `NEW_FEATURES.md` - All v2.0 features explained
- `QUICK_START.md` - 5-minute quickstart
- `API_TESTING.md` - API endpoint testing
- `HARDWARE_INTEGRATION.md` - ESP32 firmware & wiring
- `PROJECT_STRUCTURE.md` - Code architecture
- `android_config.md` - Android setup details
- `ios_config.md` - iOS setup details

---

## 🆘 Still Having Issues?

### Common Problems:

**"I see 'OFFLINE' status"**
→ Backend isn't running or wrong IP address

**"Maps are blank"**
→ Missing/incorrect Google Maps API key

**"Can't connect via Bluetooth"**
→ Location services must be enabled for BLE

**"Camera is black"**
→ Backend camera endpoint not configured yet (normal for demo)

**"Threats not appearing"**
→ Wait 10 seconds, they auto-generate in demo mode

### Get Help:

1. Check console for error messages
2. Review relevant documentation file
3. Verify all steps completed
4. Try on different device/emulator

---

## 🎊 Congratulations!

You now have a **professional-grade tactical defense system** with:

- Real-time threat detection 🎯
- Live camera streaming 📹
- Bluetooth direct control 📡
- Satellite map visualization 🗺️
- Distance tracking 📏
- Auto-alert dispatching 🚨
- Beautiful tactical UI 🎨

**Build something amazing!** 🚀

---

**Version:** 2.0.0  
**Installation Time:** ~20 minutes  
**Difficulty:** Intermediate  
**Support:** See documentation files
