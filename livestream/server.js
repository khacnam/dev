const express = require('express');
const NodeMediaServer = require('node-media-server');
const bodyParser = require('body-parser');
const session = require('express-session');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const { v4: uuidv4 } = require('uuid');
const path = require('path');
require('dotenv').config();

const app = express();
const HTTP_PORT = process.env.HTTP_PORT || 3000;
const RTMP_PORT = process.env.RTMP_PORT || 1935;
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this';
const DOMAIN = process.env.DOMAIN || 'localhost';

// Database setup
const db = new sqlite3.Database('./livestream.db', (err) => {
  if (err) {
    console.error('Database error:', err);
  } else {
    console.log('Connected to SQLite database');
  }
});

// Create tables
db.run(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  email TEXT,
  stream_key TEXT UNIQUE NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`);

db.run(`CREATE TABLE IF NOT EXISTS streams (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  stream_key TEXT NOT NULL,
  title TEXT,
  is_live BOOLEAN DEFAULT 0,
  viewers INTEGER DEFAULT 0,
  started_at DATETIME,
  ended_at DATETIME,
  FOREIGN KEY (user_id) REFERENCES users(id)
)`);

// Middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(session({
  secret: JWT_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false } // Set to true if using HTTPS
}));
app.use(express.static(path.join(__dirname, 'public')));

// Authentication middleware
const authenticateToken = (req, res, next) => {
  const token = req.session.token || req.headers['authorization'];

  if (!token) {
    return res.status(401).json({ error: 'Access denied' });
  }

  try {
    const verified = jwt.verify(token.replace('Bearer ', ''), JWT_SECRET);
    req.user = verified;
    next();
  } catch (err) {
    res.status(400).json({ error: 'Invalid token' });
  }
};

// API Routes

// Register
app.post('/api/register', async (req, res) => {
  const { username, password, email } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const streamKey = uuidv4();

  db.run(
    'INSERT INTO users (username, password, email, stream_key) VALUES (?, ?, ?, ?)',
    [username, hashedPassword, email, streamKey],
    function(err) {
      if (err) {
        return res.status(400).json({ error: 'Username already exists' });
      }
      res.json({
        message: 'User registered successfully',
        userId: this.lastID
      });
    }
  );
});

// Login
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;

  db.get('SELECT * FROM users WHERE username = ?', [username], async (err, user) => {
    if (err || !user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET);
    req.session.token = token;
    req.session.userId = user.id;

    res.json({
      token,
      username: user.username,
      streamKey: user.stream_key
    });
  });
});

// Get user info
app.get('/api/user', authenticateToken, (req, res) => {
  db.get('SELECT id, username, email, stream_key, created_at FROM users WHERE id = ?',
    [req.user.id],
    (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json(user);
    }
  );
});

// Get stream URLs
app.get('/api/stream-info', authenticateToken, (req, res) => {
  db.get('SELECT stream_key FROM users WHERE id = ?', [req.user.id], (err, user) => {
    if (err || !user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const streamKey = user.stream_key;
    const rtmpUrl = `rtmp://${DOMAIN}:${RTMP_PORT}/live`;
    const streamUrl = `rtmp://${DOMAIN}:${RTMP_PORT}/live/${streamKey}`;
    const viewUrl = `http://${DOMAIN}:${HTTP_PORT}/watch/${streamKey}`;
    const hlsUrl = `http://${DOMAIN}:${HTTP_PORT}/hls/${streamKey}.m3u8`;

    res.json({
      streamKey,
      rtmpUrl,
      streamUrl,
      viewUrl,
      hlsUrl,
      instructions: {
        mobile: 'Use apps like Larix Broadcaster, Streamlabs Mobile, or OBS Mobile',
        desktop: 'Use OBS Studio or similar software',
        settings: {
          server: rtmpUrl,
          streamKey: streamKey
        }
      }
    });
  });
});

// Get all live streams
app.get('/api/streams/live', (req, res) => {
  db.all(
    `SELECT s.*, u.username
     FROM streams s
     JOIN users u ON s.user_id = u.id
     WHERE s.is_live = 1`,
    [],
    (err, streams) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(streams);
    }
  );
});

// Check if stream is live
app.get('/api/stream/:streamKey/status', (req, res) => {
  const { streamKey } = req.params;

  db.get(
    `SELECT s.*, u.username
     FROM streams s
     JOIN users u ON s.user_id = u.id
     WHERE s.stream_key = ? AND s.is_live = 1
     ORDER BY s.started_at DESC LIMIT 1`,
    [streamKey],
    (err, stream) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json({
        isLive: !!stream,
        stream: stream || null
      });
    }
  );
});

// Logout
app.post('/api/logout', (req, res) => {
  req.session.destroy();
  res.json({ message: 'Logged out successfully' });
});

// HTML Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/dashboard', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/watch/:streamKey', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'watch.html'));
});

// Node Media Server Configuration
const nmsConfig = {
  rtmp: {
    port: RTMP_PORT,
    chunk_size: 60000,
    gop_cache: true,
    ping: 30,
    ping_timeout: 60
  },
  http: {
    port: 8000,
    allow_origin: '*',
    mediaroot: './media'
  },
  trans: {
    ffmpeg: '/usr/bin/ffmpeg',
    tasks: [
      {
        app: 'live',
        hls: true,
        hlsFlags: '[hls_time=2:hls_list_size=3:hls_flags=delete_segments]',
        dash: false
      }
    ]
  },
  auth: {
    play: false,
    publish: true,
    secret: JWT_SECRET
  }
};

const nms = new NodeMediaServer(nmsConfig);

// Node Media Server Events
nms.on('prePublish', (id, StreamPath, args) => {
  console.log('[NodeEvent on prePublish]', `id=${id} StreamPath=${StreamPath} args=${JSON.stringify(args)}`);

  // Extract stream key from path (format: /live/streamKey)
  const streamKey = StreamPath.split('/').pop();

  // Verify stream key exists
  db.get('SELECT id FROM users WHERE stream_key = ?', [streamKey], (err, user) => {
    if (err || !user) {
      console.log('[Auth] Invalid stream key:', streamKey);
      const session = nms.getSession(id);
      session.reject();
      return;
    }

    // Update stream status
    db.run(
      `INSERT INTO streams (user_id, stream_key, is_live, started_at)
       VALUES (?, ?, 1, datetime('now'))`,
      [user.id, streamKey],
      (err) => {
        if (err) {
          console.error('Error updating stream status:', err);
        } else {
          console.log('[Stream] Started:', streamKey);
        }
      }
    );
  });
});

nms.on('donePublish', (id, StreamPath, args) => {
  console.log('[NodeEvent on donePublish]', `id=${id} StreamPath=${StreamPath} args=${JSON.stringify(args)}`);

  const streamKey = StreamPath.split('/').pop();

  // Update stream status
  db.run(
    `UPDATE streams
     SET is_live = 0, ended_at = datetime('now')
     WHERE stream_key = ? AND is_live = 1`,
    [streamKey],
    (err) => {
      if (err) {
        console.error('Error updating stream status:', err);
      } else {
        console.log('[Stream] Ended:', streamKey);
      }
    }
  );
});

nms.on('prePlay', (id, StreamPath, args) => {
  console.log('[NodeEvent on prePlay]', `id=${id} StreamPath=${StreamPath} args=${JSON.stringify(args)}`);
});

nms.on('donePlay', (id, StreamPath, args) => {
  console.log('[NodeEvent on donePlay]', `id=${id} StreamPath=${StreamPath} args=${JSON.stringify(args)}`);
});

// Start servers
app.listen(HTTP_PORT, () => {
  console.log(`HTTP Server running on port ${HTTP_PORT}`);
  console.log(`Access the application at http://${DOMAIN}:${HTTP_PORT}`);
});

nms.run();
console.log(`RTMP Server running on port ${RTMP_PORT}`);
