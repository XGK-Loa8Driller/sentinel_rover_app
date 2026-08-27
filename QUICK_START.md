# ⚡ QUICK START GUIDE
## Get Your Sentinel Rover App Running in 5 Minutes!

### 🎯 What You're Getting

✅ **Complete Flutter mobile app** with tactical UI
✅ **Node.js backend** with REST API + WebSocket
✅ **Real-time threat tracking** system
✅ **Auto-alert dispatching** to emergency services
✅ **Professional, production-ready code**

---

## 📦 Step 1: Backend Setup (2 minutes)

### Install & Run

```bash
# Navigate to backend folder
cd sentinel-rover-app/backend

# Install dependencies
npm install

# Start the server
npm start
```

**You should see:**
```
╔════════════════════════════════════════╗
║   SENTINEL ROVER DEFENSE SYSTEM API    ║
╚════════════════════════════════════════╝

🚀 Server running on port 3000
📡 WebSocket endpoint: ws://localhost:3000
🌐 REST API: http://localhost:3000/api

System Status: ONLINE ✓
Defense Protocol: ACTIVE ✓
```

### Test It Works

Open browser to: `http://localhost:3000/api/health`

You should see JSON response with rover status.

---

## 📱 Step 2: Flutter App Setup (3 minutes)

### Prerequisites

Make sure you have Flutter installed:
```bash
flutter doctor
```

### Install & Run

```bash
# Navigate to project root
cd sentinel-rover-app

# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run
```

**Choose your platform:**
- iOS: `flutter run -d ios`
- Android: `flutter run -d android`  
- Web (testing): `flutter run -d chrome`

### First Launch

1. **Splash Screen** appears with pulsing logo (3 seconds)
2. **Login Screen** shows biometric scanner
   - Username: anything
   - Password: anything (demo mode)
3. **Dashboard** loads with live connection

**Look for green "ONLINE" indicator** in top-right!

---

## 🎮 Step 3: Test the System

### From the App

1. **Overview Tab**: See live rover status
2. **Map Tab**: View tactical threat map
3. **Watch for threats**: Auto-generated every 10 seconds in demo mode

### Using API (Optional)

Create a test threat:

```bash
curl -X POST http://localhost:3000/api/threats \
  -H "Content-Type: application/json" \
  -d '{
    "severity": "critical",
    "latitude": 13.0830,
    "longitude": 80.2710,
    "distance": 250
  }'
```

Watch it appear in the app instantly! 🎯

---

## 🔧 Troubleshooting

### Backend Issues

**Port already in use:**
```bash
# Change port in backend/server.js
const PORT = process.env.PORT || 3001;  // Use 3001 instead
```

**Dependencies won't install:**
```bash
rm -rf node_modules package-lock.json
npm install
```

### Flutter Issues

**WebSocket won't connect:**

Edit `lib/services/websocket_service.dart`:
```dart
socket = IO.io(
  'http://YOUR_IP:3000',  // Use your computer's IP
  // ...
);
```

Find your IP:
- Mac/Linux: `ifconfig | grep inet`
- Windows: `ipconfig`

**Dependencies fail:**
```bash
flutter clean
flutter pub get
```

### Connection Issues

**Testing on physical device?**

Replace `localhost` with your computer's IP address:

```dart
// In websocket_service.dart
socket = IO.io(
  'http://192.168.1.100:3000',  // Your IP here
  // ...
);
```

---

## 🎨 Customize Your App

### Change Colors

Edit `lib/main.dart`:
```dart
primaryColor: const Color(0xFFFF3366),  // Your color
secondary: const Color(0xFF00F5FF),     // Your color
```

### Change App Name

Edit `pubspec.yaml`:
```yaml
name: your_app_name
description: Your description
```

---

## 📁 Project Files Overview

```
📦 Your Download Contains:

├── lib/
│   ├── main.dart              ← App entry point
│   ├── screens/               ← All UI screens
│   ├── widgets/               ← Reusable components
│   ├── models/                ← Data structures
│   └── services/              ← WebSocket & APIs
│
├── backend/
│   ├── server.js              ← API & WebSocket server
│   └── package.json           ← Node dependencies
│
└── Documentation:
    ├── README.md              ← Full documentation
    ├── API_TESTING.md         ← API testing guide
    └── PROJECT_STRUCTURE.md   ← Code architecture
```

---

## 🚀 Next Steps

### Make It Your Own

1. **Add Real Authentication**
   - Implement Firebase Auth
   - Add JWT tokens to API

2. **Connect Real Hardware**
   - Update GPS coordinates
   - Add camera feed
   - Integrate laser controls

3. **Production Deployment**
   - Deploy backend to Heroku/AWS
   - Build app: `flutter build apk`
   - Submit to app stores

### Learn More

- **API Docs**: See `API_TESTING.md`
- **Architecture**: See `PROJECT_STRUCTURE.md`
- **Full Guide**: See `README.md`

---

## 🎯 Key Features Demo

### Real-Time Updates ✨

The app automatically shows:
- Battery drain simulation
- Random threat generation  
- Auto-alert dispatching
- Live system metrics

### Alert System 📢

Threats marked "HIGH" or "CRITICAL" automatically trigger:
- Police notification
- Fire department alert
- Medical services dispatch

Check backend console for alert logs!

### Beautiful UI 🎨

- Tactical military aesthetic
- Smooth animations
- Responsive design
- Dark theme optimized

---

## 💡 Pro Tips

1. **Test Mode**: Backend includes simulation - perfect for demos
2. **Multiple Devices**: Run app on phone + tablet simultaneously
3. **Debug Mode**: Check backend console for detailed logs
4. **Custom Alerts**: Modify `alertPolice()` etc. in `server.js`

---

## 🆘 Need Help?

### Common Questions

**Q: Where's my API key?**
A: No API key needed for local testing! Add authentication later.

**Q: Can I use real GPS?**
A: Yes! Add `geolocator` package and update rover status endpoint.

**Q: How do I add more threats?**
A: POST to `/api/threats` endpoint or let auto-generation run.

**Q: App won't connect to backend?**
A: Check firewall, use correct IP, ensure backend is running.

### Resources

- Flutter Docs: https://flutter.dev
- Socket.IO Guide: https://socket.io
- Express.js: https://expressjs.com

---

## ✅ Success Checklist

- [ ] Backend server running on port 3000
- [ ] Flutter app installed and running
- [ ] Green "ONLINE" status showing
- [ ] Threats appearing on map
- [ ] Backend console showing alerts

**All checked?** You're ready to build! 🎉

---

**Version**: 1.0.0  
**Build Time**: 5 minutes  
**Skill Level**: Beginner-friendly  
**Support**: Check documentation files

---

# 🎊 You're All Set!

Your Sentinel Rover Defense System is now operational.

**What to do next:**
1. Explore all 4 tabs in the app
2. Test API endpoints (see API_TESTING.md)
3. Customize colors and features
4. Build something amazing!

*Built with ❤️ using Flutter & Node.js*
