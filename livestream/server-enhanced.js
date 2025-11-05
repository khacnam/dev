const express = require('express');
const http = require('http');
const socketIO = require('socket.io');
const NodeMediaServer = require('node-media-server');
const bodyParser = require('body-parser');
const session = require('express-session');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sqlite3 = require('sqlite3').verbose();
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');
const cors = require('cors');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

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
  is_admin BOOLEAN DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`);

db.run(`CREATE TABLE IF NOT EXISTS streams (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  stream_key TEXT NOT NULL,
  title TEXT,
  description TEXT,
  is_live BOOLEAN DEFAULT 0,
  viewers INTEGER DEFAULT 0,
  max_viewers INTEGER DEFAULT 0,
  started_at DATETIME,
  ended_at DATETIME,
  duration INTEGER DEFAULT 0,
  recording_path TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id)
)`);

db.run(`CREATE TABLE IF NOT EXISTS chat_messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  stream_id INTEGER NOT NULL,
  username TEXT NOT NULL,
  message TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (stream_id) REFERENCES streams(id)
)`);

db.run(`CREATE TABLE IF NOT EXISTS analytics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  stream_id INTEGER NOT NULL,
  event_type TEXT NOT NULL,
  data TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (stream_id) REFERENCES streams(id)
)`);

// Create media directories
const mediaDir = './media';
const recordingsDir = './recordings';
if (!fs.existsSync(mediaDir)) fs.mkdirSync(mediaDir);
if (!fs.existsSync(recordingsDir)) fs.mkdirSync(recordingsDir);

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(session({
  secret: JWT_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: { secure: false }
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

// Admin middleware
const isAdmin = (req, res, next) => {
  db.get('SELECT is_admin FROM users WHERE id = ?', [req.user.id], (err, user) => {
    if (err || !user || !user.is_admin) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    next();
  });
};

// ===== API Routes =====

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

    const token = jwt.sign({
      id: user.id,
      username: user.username,
      isAdmin: user.is_admin
    }, JWT_SECRET);

    req.session.token = token;
    req.session.userId = user.id;

    res.json({
      token,
      username: user.username,
      streamKey: user.stream_key,
      isAdmin: user.is_admin
    });
  });
});

// Get user info
app.get('/api/user', authenticateToken, (req, res) => {
  db.get('SELECT id, username, email, stream_key, is_admin, created_at FROM users WHERE id = ?',
    [req.user.id],
    (err, user) => {
      if (err || !user) {
        return res.status(404).json({ error: 'User not found' });
      }
      res.json(user);
    }
  );
});

// Update stream info
app.put('/api/stream/settings', authenticateToken, (req, res) => {
  const { title, description } = req.body;

  db.run(
    `UPDATE streams SET title = ?, description = ?
     WHERE user_id = ? AND is_live = 1`,
    [title, description, req.user.id],
    (err) => {
      if (err) {
        return res.status(500).json({ error: 'Failed to update stream' });
      }
      res.json({ message: 'Stream updated successfully' });
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
    const hlsUrl = `http://${DOMAIN}:8000/live/${streamKey}.m3u8`;

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
    `SELECT s.*, u.username, u.stream_key
     FROM streams s
     JOIN users u ON s.user_id = u.id
     WHERE s.is_live = 1
     ORDER BY s.started_at DESC`,
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
     WHERE u.stream_key = ? AND s.is_live = 1
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

// Get stream analytics
app.get('/api/stream/:streamKey/analytics', (req, res) => {
  const { streamKey } = req.params;

  db.all(
    `SELECT
      s.id,
      s.title,
      s.viewers,
      s.max_viewers,
      s.started_at,
      s.ended_at,
      s.duration,
      COUNT(DISTINCT cm.id) as total_messages
     FROM streams s
     LEFT JOIN users u ON s.user_id = u.id
     LEFT JOIN chat_messages cm ON s.id = cm.stream_id
     WHERE u.stream_key = ?
     GROUP BY s.id
     ORDER BY s.started_at DESC
     LIMIT 10`,
    [streamKey],
    (err, analytics) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(analytics);
    }
  );
});

// Get user's stream history
app.get('/api/user/streams/history', authenticateToken, (req, res) => {
  db.all(
    `SELECT * FROM streams
     WHERE user_id = ?
     ORDER BY started_at DESC
     LIMIT 50`,
    [req.user.id],
    (err, streams) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(streams);
    }
  );
});

// Admin: Get all users
app.get('/api/admin/users', authenticateToken, isAdmin, (req, res) => {
  db.all(
    'SELECT id, username, email, stream_key, is_admin, created_at FROM users ORDER BY created_at DESC',
    [],
    (err, users) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(users);
    }
  );
});

// Admin: Get all streams
app.get('/api/admin/streams', authenticateToken, isAdmin, (req, res) => {
  db.all(
    `SELECT s.*, u.username
     FROM streams s
     JOIN users u ON s.user_id = u.id
     ORDER BY s.started_at DESC
     LIMIT 100`,
    [],
    (err, streams) => {
      if (err) {
        return res.status(500).json({ error: 'Database error' });
      }
      res.json(streams);
    }
  );
});

// Admin: Get statistics
app.get('/api/admin/stats', authenticateToken, isAdmin, (req, res) => {
  const stats = {};

  db.get('SELECT COUNT(*) as total FROM users', [], (err, result) => {
    stats.totalUsers = result?.total || 0;

    db.get('SELECT COUNT(*) as total FROM streams WHERE is_live = 1', [], (err, result) => {
      stats.liveStreams = result?.total || 0;

      db.get('SELECT COUNT(*) as total FROM streams', [], (err, result) => {
        stats.totalStreams = result?.total || 0;

        db.get('SELECT SUM(viewers) as total FROM streams WHERE is_live = 1', [], (err, result) => {
          stats.currentViewers = result?.total || 0;

          res.json(stats);
        });
      });
    });
  });
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

app.get('/browse', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'browse.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'admin.html'));
});

// ===== Socket.IO for Chat =====

const streamRooms = new Map(); // streamKey -> Set of socket ids

io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  // Join stream room
  socket.on('join-stream', (streamKey) => {
    socket.join(streamKey);

    if (!streamRooms.has(streamKey)) {
      streamRooms.set(streamKey, new Set());
    }
    streamRooms.get(streamKey).add(socket.id);

    // Update viewer count
    const viewerCount = streamRooms.get(streamKey).size;
    io.to(streamKey).emit('viewer-count', viewerCount);

    // Update database
    db.run(
      `UPDATE streams SET viewers = ? WHERE stream_key =
       (SELECT stream_key FROM users WHERE stream_key = ?) AND is_live = 1`,
      [viewerCount, streamKey]
    );

    console.log(`User ${socket.id} joined stream ${streamKey}. Viewers: ${viewerCount}`);
  });

  // Leave stream room
  socket.on('leave-stream', (streamKey) => {
    socket.leave(streamKey);

    if (streamRooms.has(streamKey)) {
      streamRooms.get(streamKey).delete(socket.id);
      const viewerCount = streamRooms.get(streamKey).size;
      io.to(streamKey).emit('viewer-count', viewerCount);

      // Update database
      db.run(
        `UPDATE streams SET viewers = ? WHERE stream_key =
         (SELECT stream_key FROM users WHERE stream_key = ?) AND is_live = 1`,
        [viewerCount, streamKey]
      );
    }
  });

  // Chat message
  socket.on('chat-message', ({ streamKey, username, message }) => {
    if (!message || message.trim().length === 0) return;

    const chatMessage = {
      username: username || 'Anonymous',
      message: message.trim().substring(0, 500), // Limit message length
      timestamp: new Date().toISOString()
    };

    // Save to database
    db.get(
      'SELECT id FROM streams WHERE stream_key = (SELECT stream_key FROM users WHERE stream_key = ?) AND is_live = 1',
      [streamKey],
      (err, stream) => {
        if (!err && stream) {
          db.run(
            'INSERT INTO chat_messages (stream_id, username, message) VALUES (?, ?, ?)',
            [stream.id, chatMessage.username, chatMessage.message]
          );
        }
      }
    );

    // Broadcast to room
    io.to(streamKey).emit('chat-message', chatMessage);
    console.log(`Chat message in ${streamKey} from ${chatMessage.username}`);
  });

  // Disconnect
  socket.on('disconnect', () => {
    // Remove from all rooms
    streamRooms.forEach((sockets, streamKey) => {
      if (sockets.has(socket.id)) {
        sockets.delete(socket.id);
        const viewerCount = sockets.size;
        io.to(streamKey).emit('viewer-count', viewerCount);

        // Update database
        db.run(
          `UPDATE streams SET viewers = ? WHERE stream_key =
           (SELECT stream_key FROM users WHERE stream_key = ?) AND is_live = 1`,
          [viewerCount, streamKey]
        );
      }
    });

    console.log('User disconnected:', socket.id);
  });
});

// ===== Node Media Server Configuration =====

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
    mediaroot: mediaDir
  },
  trans: {
    ffmpeg: process.env.FFMPEG_PATH || '/usr/bin/ffmpeg',
    tasks: [
      {
        app: 'live',
        hls: true,
        hlsFlags: '[hls_time=2:hls_list_size=3:hls_flags=delete_segments]',
        dash: false
      }
    ]
  }
};

const nms = new NodeMediaServer(nmsConfig);

// ===== Node Media Server Events =====

nms.on('prePublish', (id, StreamPath, args) => {
  console.log('[NodeEvent on prePublish]', `id=${id} StreamPath=${StreamPath}`);

  const streamKey = StreamPath.split('/').pop();

  // Verify stream key exists
  db.get('SELECT id, username FROM users WHERE stream_key = ?', [streamKey], (err, user) => {
    if (err || !user) {
      console.log('[Auth] Invalid stream key:', streamKey);
      const session = nms.getSession(id);
      session.reject();
      return;
    }

    console.log(`[Auth] User ${user.username} starting stream with key ${streamKey}`);

    // Create stream record
    db.run(
      `INSERT INTO streams (user_id, stream_key, title, is_live, started_at)
       VALUES (?, ?, ?, 1, datetime('now'))`,
      [user.id, streamKey, `${user.username}'s Live Stream`],
      function(err) {
        if (err) {
          console.error('Error creating stream record:', err);
        } else {
          console.log('[Stream] Started:', streamKey, 'Stream ID:', this.lastID);

          // Log analytics
          db.run(
            'INSERT INTO analytics (stream_id, event_type, data) VALUES (?, ?, ?)',
            [this.lastID, 'stream_start', JSON.stringify({ streamKey, userId: user.id })]
          );
        }
      }
    );
  });
});

nms.on('donePublish', (id, StreamPath, args) => {
  console.log('[NodeEvent on donePublish]', `id=${id} StreamPath=${StreamPath}`);

  const streamKey = StreamPath.split('/').pop();

  // Update stream record
  db.get(
    `SELECT id, started_at, max_viewers FROM streams
     WHERE stream_key = (SELECT stream_key FROM users WHERE stream_key = ?)
     AND is_live = 1`,
    [streamKey],
    (err, stream) => {
      if (err || !stream) {
        console.error('Error finding stream:', err);
        return;
      }

      const duration = Math.floor((Date.now() - new Date(stream.started_at).getTime()) / 1000);

      db.run(
        `UPDATE streams
         SET is_live = 0, ended_at = datetime('now'), duration = ?
         WHERE id = ?`,
        [duration, stream.id],
        (err) => {
          if (err) {
            console.error('Error updating stream status:', err);
          } else {
            console.log('[Stream] Ended:', streamKey, 'Duration:', duration, 'seconds');

            // Log analytics
            db.run(
              'INSERT INTO analytics (stream_id, event_type, data) VALUES (?, ?, ?)',
              [stream.id, 'stream_end', JSON.stringify({
                streamKey,
                duration,
                maxViewers: stream.max_viewers
              })]
            );
          }
        }
      );
    }
  );

  // Clear room
  if (streamRooms.has(streamKey)) {
    io.to(streamKey).emit('stream-ended');
    streamRooms.delete(streamKey);
  }
});

nms.on('prePlay', (id, StreamPath, args) => {
  console.log('[NodeEvent on prePlay]', `id=${id} StreamPath=${StreamPath}`);
});

nms.on('donePlay', (id, StreamPath, args) => {
  console.log('[NodeEvent on donePlay]', `id=${id} StreamPath=${StreamPath}`);
});

// Update max viewers periodically
setInterval(() => {
  streamRooms.forEach((sockets, streamKey) => {
    const viewerCount = sockets.size;
    if (viewerCount > 0) {
      db.run(
        `UPDATE streams
         SET max_viewers = MAX(max_viewers, ?)
         WHERE stream_key = (SELECT stream_key FROM users WHERE stream_key = ?)
         AND is_live = 1`,
        [viewerCount, streamKey]
      );
    }
  });
}, 30000); // Every 30 seconds

// ===== Start Servers =====

server.listen(HTTP_PORT, () => {
  console.log(`HTTP Server running on port ${HTTP_PORT}`);
  console.log(`Access the application at http://${DOMAIN}:${HTTP_PORT}`);
});

nms.run();
console.log(`RTMP Server running on port ${RTMP_PORT}`);
