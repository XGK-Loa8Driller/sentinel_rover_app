# 📁 Project Structure

Complete file tree and component organization for the Sentinel Rover Defense System.

```
sentinel-rover-app/
│
├── 📱 lib/                          # Flutter Application
│   ├── main.dart                    # App entry point & theme configuration
│   │
│   ├── screens/                     # UI Screens
│   │   ├── splash_screen.dart       # Animated loading screen
│   │   ├── login_screen.dart        # Biometric-style authentication
│   │   └── dashboard_screen.dart    # Main control interface
│   │
│   ├── widgets/                     # Reusable Components
│   │   ├── rover_status_card.dart   # Live rover metrics display
│   │   ├── threat_alert_card.dart   # Threat detection cards
│   │   ├── system_stats.dart        # Performance charts & stats
│   │   └── threat_map.dart          # Interactive tactical map
│   │
│   ├── models/                      # Data Models
│   │   └── threat_model.dart        # Threat data structure
│   │
│   └── services/                    # Business Logic
│       └── websocket_service.dart   # Real-time communication
│
├── 🖥️ backend/                       # Node.js Server
│   ├── server.js                    # Main server with REST API & WebSocket
│   ├── package.json                 # Node dependencies
│   └── .env.template                # Environment variables template
│
├── 📄 Configuration Files
│   ├── pubspec.yaml                 # Flutter dependencies
│   ├── .gitignore                   # Git ignore rules
│   ├── README.md                    # Main documentation
│   └── API_TESTING.md               # API testing guide
│
└── 📊 Project Documentation
    └── PROJECT_STRUCTURE.md         # This file
```

## 🎯 Component Breakdown

### Flutter App (`lib/`)

#### **Main Entry (`main.dart`)**
- Application initialization
- Theme configuration (dark tactical theme)
- Route definitions
- Global services setup

**Key Features:**
- Orbitron font for headers (tactical aesthetic)
- Inter font for body text (readability)
- Dark color scheme with accent colors
- Material 3 design system

#### **Screens**

**1. Splash Screen (`splash_screen.dart`)**
- Animated company logo with pulsing effect
- Grid background animation
- 3-second auto-transition to login
- Loading progress indicator

**2. Login Screen (`login_screen.dart`)**
- Biometric scanner animation
- Username/password authentication
- Restricted access warning
- Gradient background with tactical aesthetic

**3. Dashboard Screen (`dashboard_screen.dart`)**
- Tab-based navigation (Overview, Map, Alerts, Settings)
- Real-time status header
- Threat level indicator
- Bottom navigation bar

**Tabs:**
- **Overview**: Rover status, system stats, recent detections
- **Map**: Live tactical map with threat markers
- **Alerts**: Full threat history
- **Settings**: System configuration toggles

#### **Widgets**

**1. Rover Status Card (`rover_status_card.dart`)**
- Live battery level
- Laser system status
- GPS coordinates
- Pulsing status indicator
- Last update timestamp

**2. Threat Alert Card (`threat_alert_card.dart`)**
- Severity badge (color-coded)
- Location coordinates
- Detection time (relative)
- Distance from rover
- Alert dispatch status

**3. System Stats (`system_stats.dart`)**
- CPU usage meter
- RAM usage meter
- Temperature reading
- Detection accuracy chart (Line chart)

**4. Threat Map (`threat_map.dart`)**
- Animated grid background
- Rover position (center, pulsing)
- Threat markers (color-coded by severity)
- Map legend
- Coordinate overlay
- Real-time position tracking

#### **Models**

**Threat Model (`threat_model.dart`)**
```dart
{
  id: String,
  severity: String,      // 'low', 'medium', 'high', 'critical'
  latitude: double,
  longitude: double,
  distance: double,      // in meters
  timestamp: DateTime,
  neutralized: bool,
  alerts_sent: List<String>
}
```

#### **Services**

**WebSocket Service (`websocket_service.dart`)**
- Socket.IO client
- Reactive state management (GetX)
- Auto-reconnection
- Event handlers:
  - `rover_status` - Rover updates
  - `threat_detected` - New threats
  - `threat_neutralized` - Eliminated threats
  - `laser_result` - Laser engagement results

**Observable States:**
- `isConnected` - Connection status
- `roverStatus` - Rover operational state
- `batteryLevel` - Battery percentage
- `laserStatus` - Laser system availability
- `latitude/longitude` - GPS position
- `threatLevel` - Overall threat assessment
- `threatsDetected` - Active threat count
- `recentThreats` - Threat history

### Backend (`backend/`)

#### **Server (`server.js`)**

**REST API Endpoints:**
```
GET  /api/health                    - System health check
GET  /api/rover/status              - Get rover status
POST /api/rover/status              - Update rover status
GET  /api/threats                   - List all threats
POST /api/threats                   - Report new threat
POST /api/threats/:id/neutralize    - Mark threat neutralized
GET  /api/alerts                    - Get alert history
POST /api/alerts/dispatch           - Manual alert dispatch
```

**WebSocket Events:**

*Client → Server:*
- `fire_laser` - Command laser engagement

*Server → Client:*
- `rover_status` - Status update broadcast
- `threat_detected` - New threat alert
- `threat_neutralized` - Threat elimination
- `laser_result` - Laser operation result

**Alert System:**
- `alertPolice()` - Police dispatch integration
- `alertFire()` - Fire department notification
- `alertMedical()` - Medical services alert

**Auto-dispatched when:**
- Threat severity: HIGH or CRITICAL
- Configurable threshold in code

**Simulation Features:**
- Periodic rover status updates (5s intervals)
- Random threat generation (10s intervals)
- Battery drain simulation
- System metric variations

## 🎨 Design System

### Color Palette

```
Background:     #0A0E17  (Deep space blue)
Surface:        #151B2B  (Elevated panels)
Primary:        #FF3366  (Alert red - threats/danger)
Secondary:      #00F5FF  (Cyber blue - active/info)
Success:        #00FF88  (Status green)
Warning:        #FF9500  (Caution orange)
Caution:        #FFCC00  (Medium yellow)
```

### Typography

```
Display:  Orbitron (Bold, 900 weight)
Headers:  Orbitron (Bold, 700 weight)
Body:     Inter (Regular/Medium)
Code:     JetBrains Mono (alternative)
```

### Component Styling

**Cards:**
- Border radius: 12-16px
- Border: 1px, semi-transparent
- Background: Gradient or solid surface color
- Shadow: Colored glow for emphasis

**Buttons:**
- Rounded corners (12px)
- Bold text (Orbitron)
- Letter spacing: 2-3px
- Uppercase labels

**Status Indicators:**
- Pulsing animation (1s fade in/out)
- Colored glow shadow
- Circular shape (8-12px diameter)

## 🔌 Integration Points

### Mobile → Backend
```
WebSocket: ws://localhost:3000
Protocol: Socket.IO
Auth: None (add JWT in production)
```

### Backend → Emergency Services
```
Police API:  alertPolice()
Fire API:    alertFire()
Medical API: alertMedical()
```

*Note: Currently simulated, integrate with real APIs*

### Rover → Backend
```
POST /api/rover/status  - Periodic status updates
POST /api/threats       - Threat detection reports
```

## 📦 Dependencies

### Flutter
- `get`: State management
- `google_fonts`: Typography
- `flutter_animate`: Animations
- `socket_io_client`: WebSocket
- `fl_chart`: Charts & graphs
- `google_maps_flutter`: Maps (future)
- `geolocator`: GPS (future)

### Backend
- `express`: Web framework
- `socket.io`: WebSocket server
- `cors`: Cross-origin support
- `body-parser`: JSON parsing
- `uuid`: ID generation
- `axios`: HTTP client (future)
- `dotenv`: Environment config

## 🚀 Development Workflow

### 1. Start Backend
```bash
cd backend
npm install
npm run dev
```

### 2. Run Flutter App
```bash
flutter pub get
flutter run
```

### 3. Test Integration
- Login to app
- Verify WebSocket connection (green status)
- Watch for auto-generated threats
- Test manual threat reporting via API

### 4. Deploy
- Build Flutter app: `flutter build apk/ios`
- Deploy backend: Heroku, AWS, DigitalOcean
- Update WebSocket URL in app
- Configure environment variables

## 🔐 Security Checklist

- [ ] Add JWT authentication
- [ ] Implement API rate limiting
- [ ] Use HTTPS/WSS in production
- [ ] Validate all inputs
- [ ] Sanitize user data
- [ ] Implement RBAC (Role-Based Access Control)
- [ ] Add audit logging
- [ ] Encrypt sensitive data
- [ ] Set up CORS properly
- [ ] Use environment variables for secrets

## 📝 Notes

- All coordinates use decimal degrees format
- Distances measured in meters
- Timestamps in ISO 8601 format
- Battery level: 0-100 percentage
- Threat levels: LOW, MEDIUM, HIGH, CRITICAL

---

**Version**: 1.0.0
**Last Updated**: February 2024
**Maintained By**: Development Team
