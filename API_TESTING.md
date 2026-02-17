# 🧪 API Testing Guide

Quick reference for testing the Sentinel Rover API endpoints.

## Setup

Make sure the backend server is running:
```bash
cd backend
npm start
```

## Test Endpoints with cURL

### 1. Health Check
```bash
curl http://localhost:3000/api/health
```

**Expected Response:**
```json
{
  "status": "online",
  "timestamp": "2024-02-10T12:00:00.000Z",
  "rover": {
    "status": "ACTIVE",
    "battery": 85,
    "laser_status": "READY",
    ...
  }
}
```

### 2. Get Rover Status
```bash
curl http://localhost:3000/api/rover/status
```

### 3. Update Rover Status
```bash
curl -X POST http://localhost:3000/api/rover/status \
  -H "Content-Type: application/json" \
  -d '{
    "battery": 90,
    "laser_status": "READY",
    "latitude": 13.0827,
    "longitude": 80.2707
  }'
```

### 4. Get All Threats
```bash
curl http://localhost:3000/api/threats
```

### 5. Report New Threat
```bash
curl -X POST http://localhost:3000/api/threats \
  -H "Content-Type: application/json" \
  -d '{
    "severity": "critical",
    "latitude": 13.0830,
    "longitude": 80.2710,
    "distance": 250.5
  }'
```

**Expected Response:**
```json
{
  "success": true,
  "threat": {
    "id": "uuid-here",
    "severity": "critical",
    "latitude": 13.0830,
    "longitude": 80.2710,
    "distance": 250.5,
    "timestamp": "2024-02-10T12:00:00.000Z",
    "neutralized": false,
    "alerts_sent": ["Police", "Fire Department", "Medical"]
  },
  "alerts_sent": ["Police", "Fire Department", "Medical"]
}
```

### 6. Neutralize Threat
```bash
# Replace <THREAT_ID> with actual threat ID
curl -X POST http://localhost:3000/api/threats/<THREAT_ID>/neutralize
```

### 7. Get Alert History
```bash
curl http://localhost:3000/api/alerts
```

### 8. Manual Alert Dispatch
```bash
curl -X POST http://localhost:3000/api/alerts/dispatch \
  -H "Content-Type: application/json" \
  -d '{
    "type": "emergency",
    "location": {
      "latitude": 13.0827,
      "longitude": 80.2707
    },
    "message": "Hostile drone detected in sector 7"
  }'
```

## Test WebSocket Connection

### Using Node.js
```javascript
const io = require('socket.io-client');

const socket = io('http://localhost:3000');

socket.on('connect', () => {
  console.log('Connected!');
});

socket.on('rover_status', (data) => {
  console.log('Rover Status:', data);
});

socket.on('threat_detected', (threat) => {
  console.log('Threat Detected!', threat);
});

socket.on('threat_neutralized', (data) => {
  console.log('Threat Neutralized:', data);
});

// Fire laser
socket.emit('fire_laser', {
  target_id: 'threat-123',
  coordinates: { lat: 13.0830, lng: 80.2710 }
});

socket.on('laser_result', (result) => {
  console.log('Laser Result:', result);
});
```

### Using Browser Console
```javascript
// Include socket.io client script first
// <script src="https://cdn.socket.io/4.6.1/socket.io.min.js"></script>

const socket = io('http://localhost:3000');

socket.on('connect', () => console.log('Connected'));
socket.on('rover_status', data => console.log('Rover:', data));
socket.on('threat_detected', threat => console.log('Threat:', threat));
```

## Postman Collection

Import this JSON into Postman:

```json
{
  "info": {
    "name": "Sentinel Rover API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Health Check",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "http://localhost:3000/api/health",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "health"]
        }
      }
    },
    {
      "name": "Get Rover Status",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "http://localhost:3000/api/rover/status",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "rover", "status"]
        }
      }
    },
    {
      "name": "Update Rover Status",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"battery\": 90,\n  \"laser_status\": \"READY\"\n}"
        },
        "url": {
          "raw": "http://localhost:3000/api/rover/status",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "rover", "status"]
        }
      }
    },
    {
      "name": "Report Threat",
      "request": {
        "method": "POST",
        "header": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ],
        "body": {
          "mode": "raw",
          "raw": "{\n  \"severity\": \"critical\",\n  \"latitude\": 13.0830,\n  \"longitude\": 80.2710,\n  \"distance\": 250.5\n}"
        },
        "url": {
          "raw": "http://localhost:3000/api/threats",
          "protocol": "http",
          "host": ["localhost"],
          "port": "3000",
          "path": ["api", "threats"]
        }
      }
    }
  ]
}
```

## Testing Checklist

- [ ] Backend server starts without errors
- [ ] Health check endpoint responds
- [ ] Can retrieve rover status
- [ ] Can update rover status
- [ ] Can report new threats
- [ ] High/Critical threats trigger auto-alerts
- [ ] Can neutralize threats
- [ ] WebSocket connection established
- [ ] Real-time updates working
- [ ] Flutter app connects successfully

## Common Issues

### Backend won't start
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install
```

### WebSocket connection failed
- Check if backend is running
- Verify port 3000 is not blocked
- Update IP address in Flutter app

### CORS errors
- Backend includes CORS middleware
- Check origin settings in server.js

## Production Testing

Before deploying to production:

1. Load testing (use tools like Apache Bench or k6)
2. Security scanning (npm audit)
3. API rate limiting tests
4. Failover scenarios
5. Alert system integration tests
6. Real GPS coordinate validation
7. Multi-client WebSocket stress test

---

**Need Help?** Check the main README.md for full documentation.
