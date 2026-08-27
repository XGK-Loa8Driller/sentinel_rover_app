const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');

// Initialize Express app
const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// In-memory storage (replace with database in production)
let roverStatus = {
  status: 'ACTIVE',
  battery: 85,
  laser_status: 'READY',
  latitude: 13.0827,
  longitude: 80.2707,
  temperature: 45,
  cpu_usage: 42,
  ram_usage: 68,
  distance_traveled: 0.0 // in meters
};

let threats = [];
let alerts = [];

// =====================
// REST API ENDPOINTS
// =====================

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    timestamp: new Date().toISOString(),
    rover: roverStatus
  });
});

// Get rover status
app.get('/api/rover/status', (req, res) => {
  res.json(roverStatus);
});

// Update rover status
app.post('/api/rover/status', (req, res) => {
  roverStatus = { ...roverStatus, ...req.body };
  
  // Broadcast to all connected clients
  io.emit('rover_status', roverStatus);
  
  res.json({
    success: true,
    status: roverStatus
  });
});

// Get all threats
app.get('/api/threats', (req, res) => {
  res.json({
    total: threats.length,
    active: threats.filter(t => !t.neutralized).length,
    threats: threats
  });
});

// Report new threat
app.post('/api/threats', async (req, res) => {
  const threat = {
    id: uuidv4(),
    severity: req.body.severity || 'medium',
    latitude: req.body.latitude || roverStatus.latitude + (Math.random() * 0.01),
    longitude: req.body.longitude || roverStatus.longitude + (Math.random() * 0.01),
    distance: req.body.distance || Math.random() * 500,
    timestamp: new Date().toISOString(),
    neutralized: false,
    alerts_sent: []
  };

  // Determine if we should auto-alert authorities
  const shouldAlert = threat.severity === 'critical' || threat.severity === 'high';
  
  if (shouldAlert) {
    const alertResults = await sendAlerts(threat);
    threat.alerts_sent = alertResults;
  }

  threats.push(threat);
  
  // Broadcast to all connected clients
  io.emit('threat_detected', threat);
  
  res.json({
    success: true,
    threat: threat,
    alerts_sent: threat.alerts_sent
  });
});

// Mark threat as neutralized
app.post('/api/threats/:id/neutralize', (req, res) => {
  const threatId = req.params.id;
  const threat = threats.find(t => t.id === threatId);
  
  if (!threat) {
    return res.status(404).json({
      success: false,
      error: 'Threat not found'
    });
  }

  threat.neutralized = true;
  threat.neutralized_at = new Date().toISOString();
  
  // Broadcast to all connected clients
  io.emit('threat_neutralized', { id: threatId });
  
  res.json({
    success: true,
    threat: threat
  });
});

// Get alert history
app.get('/api/alerts', (req, res) => {
  res.json({
    total: alerts.length,
    alerts: alerts
  });
});

// Camera stream endpoint (for WebSocket/HTTP streaming)
app.get('/camera/stream', (req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.send(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Rover Camera Stream</title>
      <style>
        body {
          margin: 0;
          padding: 0;
          background: #000;
          display: flex;
          justify-content: center;
          align-items: center;
          height: 100vh;
        }
        #stream {
          max-width: 100%;
          max-height: 100%;
        }
      </style>
    </head>
    <body>
      <img id="stream" src="/camera/feed" alt="Camera Stream">
      <script>
        // Refresh stream every 100ms for live feed
        setInterval(() => {
          document.getElementById('stream').src = '/camera/feed?' + new Date().getTime();
        }, 100);
      </script>
    </body>
    </html>
  `);
});

// Camera feed image endpoint (replace with actual camera integration)
app.get('/camera/feed', (req, res) => {
  // In production, this would stream from actual camera
  // For now, send a placeholder or test pattern
  res.setHeader('Content-Type', 'image/jpeg');
  res.setHeader('Cache-Control', 'no-cache');
  
  // Send a test pattern or actual camera frame
  // You would integrate with your rover's camera module here
  res.end(''); // Placeholder
});

// Manual alert dispatch
app.post('/api/alerts/dispatch', async (req, res) => {
  const { type, location, message } = req.body;
  
  const alert = {
    id: uuidv4(),
    type: type || 'emergency',
    location: location || {
      latitude: roverStatus.latitude,
      longitude: roverStatus.longitude
    },
    message: message || 'Hostile drone detected',
    timestamp: new Date().toISOString(),
    dispatched_to: []
  };

  const results = await sendAlerts(alert);
  alert.dispatched_to = results;
  alerts.push(alert);
  
  res.json({
    success: true,
    alert: alert
  });
});

// =====================
// WEBSOCKET HANDLERS
// =====================

io.on('connection', (socket) => {
  console.log('New client connected:', socket.id);
  
  // Send initial rover status
  socket.emit('rover_status', roverStatus);
  
  // Send recent threats
  socket.emit('recent_threats', threats.slice(-10));
  
  // Handle disconnect
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
  
  // Handle laser fire command
  socket.on('fire_laser', (data) => {
    console.log('Laser fired at target:', data);
    socket.emit('laser_result', {
      success: true,
      target: data,
      timestamp: new Date().toISOString()
    });
  });
});

// =====================
// ALERT SYSTEM
// =====================

async function sendAlerts(threat) {
  const dispatched = [];
  
  // Simulate alert to police
  if (await alertPolice(threat)) {
    dispatched.push('Police');
  }
  
  // Simulate alert to fire department
  if (threat.severity === 'critical') {
    if (await alertFire(threat)) {
      dispatched.push('Fire Department');
    }
  }
  
  // Simulate alert to medical services
  if (await alertMedical(threat)) {
    dispatched.push('Medical');
  }
  
  return dispatched;
}

async function alertPolice(threat) {
  // In production, integrate with actual emergency dispatch API
  console.log('[POLICE ALERT]', {
    threat_id: threat.id,
    severity: threat.severity,
    location: {
      lat: threat.latitude || roverStatus.latitude,
      lng: threat.longitude || roverStatus.longitude
    },
    message: `Hostile drone detected - ${threat.severity} threat level`
  });
  
  // Simulate API call delay
  await new Promise(resolve => setTimeout(resolve, 100));
  return true;
}

async function alertFire(threat) {
  console.log('[FIRE DEPARTMENT ALERT]', {
    threat_id: threat.id,
    severity: threat.severity,
    location: {
      lat: threat.latitude || roverStatus.latitude,
      lng: threat.longitude || roverStatus.longitude
    }
  });
  
  await new Promise(resolve => setTimeout(resolve, 100));
  return true;
}

async function alertMedical(threat) {
  console.log('[MEDICAL ALERT]', {
    threat_id: threat.id,
    severity: threat.severity,
    location: {
      lat: threat.latitude || roverStatus.latitude,
      lng: threat.longitude || roverStatus.longitude
    }
  });
  
  await new Promise(resolve => setTimeout(resolve, 100));
  return true;
}

// =====================
// SIMULATION / DEMO
// =====================

// Simulate periodic rover updates (for demo)
setInterval(() => {
  roverStatus.battery = Math.max(0, roverStatus.battery - 0.1);
  roverStatus.cpu_usage = 35 + Math.random() * 20;
  roverStatus.ram_usage = 60 + Math.random() * 15;
  roverStatus.temperature = 40 + Math.random() * 10;
  
  // Simulate small movement (odometry)
  const movement = Math.random() * 2; // 0-2 meters per update
  roverStatus.distance_traveled += movement;
  roverStatus.latitude += (Math.random() - 0.5) * 0.00001;
  roverStatus.longitude += (Math.random() - 0.5) * 0.00001;
  
  io.emit('rover_status', roverStatus);
}, 5000);

// Simulate random threat detection (for demo)
setInterval(() => {
  if (Math.random() > 0.85) { // 15% chance every 10 seconds
    const severities = ['low', 'medium', 'high', 'critical'];
    const severity = severities[Math.floor(Math.random() * severities.length)];
    
    const threat = {
      id: uuidv4(),
      severity: severity,
      latitude: roverStatus.latitude + (Math.random() * 0.01 - 0.005),
      longitude: roverStatus.longitude + (Math.random() * 0.01 - 0.005),
      distance: Math.random() * 500,
      timestamp: new Date().toISOString(),
      neutralized: false,
      alerts_sent: []
    };

    if (severity === 'critical' || severity === 'high') {
      sendAlerts(threat).then(results => {
        threat.alerts_sent = results;
        threats.push(threat);
        io.emit('threat_detected', threat);
      });
    } else {
      threats.push(threat);
      io.emit('threat_detected', threat);
    }
  }
}, 10000);

// =====================
// START SERVER
// =====================

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log('╔════════════════════════════════════════╗');
  console.log('║   SENTINEL ROVER DEFENSE SYSTEM API    ║');
  console.log('╚════════════════════════════════════════╝');
  console.log('');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📡 WebSocket endpoint: ws://localhost:${PORT}`);
  console.log(`🌐 REST API: http://localhost:${PORT}/api`);
  console.log('');
  console.log('Endpoints:');
  console.log('  GET  /api/health');
  console.log('  GET  /api/rover/status');
  console.log('  POST /api/rover/status');
  console.log('  GET  /api/threats');
  console.log('  POST /api/threats');
  console.log('  POST /api/threats/:id/neutralize');
  console.log('  GET  /api/alerts');
  console.log('  POST /api/alerts/dispatch');
  console.log('');
  console.log('System Status: ONLINE ✓');
  console.log('Defense Protocol: ACTIVE ✓');
  console.log('');
});

module.exports = { app, server, io };
