const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const winston = require('winston');
require('dotenv').config();

// Safe import helper
function safeImport(modulePath, fallback) {
  try {
    return require(modulePath);
  } catch (error) {
    console.warn(`Warning: Could not load ${modulePath}:`, error.message);
    return fallback || ((req, res) => res.status(501).json({ error: `${modulePath} not implemented` }));
  }
}

// Initialize express app
const app = express();
const PORT = process.env.PORT || 3000;

// Logger setup
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'error.log', level: 'error' })
  ]
});

// Middleware
app.use(helmet({
  crossOriginResourcePolicy: { policy: "cross-origin" }
}));
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const limiter = rateLimit({
  windowMs: process.env.RATE_LIMIT_WINDOW_MS || 15 * 60 * 1000,
  max: process.env.RATE_LIMIT_MAX || 100
});
app.use('/api/', limiter);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'E-commerce Backend API',
    version: '1.0.0',
    status: 'running',
    endpoints: {
      health: '/health',
      api: '/api/*',
      test: '/api/test'
    }
<<<<<<< HEAD
    await signup(req, res)
    await mail(req, res)
})
app.post("/oauth", async (req, res) => {
    await oauth(req, res)
})
app.post("/login", [
    body("email").isEmail().withMessage("Email is not valid"),
    body("password").isLength({ 
        min: 8
     }).withMessage("Password must be at least 8 characters long")
],async (req, res) => {
    const errors = validationResult(req)
    if (!errors.isEmpty()) {
        res.status(400).json({
            errors: errors.array()
        })
    }
    await login(req, res)
})
app.post("/products", verifyToken, checkRole("Retailer"), upload.single("image"), async (req, res) => {
    await addProduct(req, res)
})
app.get("/products", async (req, res) => {
    await listProducts(req, res)
})
app.post("/cart", verifyToken, async (req, res) => {
    await addToCart(req, res)
})
app.get("/cart", verifyToken, async (req, res) => {
    await showCart(req, res)
})
app.delete("/cart", verifyToken, async (req, res) => {
    await deleteCart(req, res)
})
app.post("/searchProducts", async (req, res) => {
    await searchProducts(req, res)
})
app.post("/reviews", verifyToken, async (req, res) => {
    await saveComment(req, res)
})
app.get("/reviews", async (req, res) => {
    await showReview(req, res)
})
app.get("/:id", async (req, res) => {
    await showProduct(req, res)
})
app.listen(5000, () => {
    console.log("Server is running at port 5000")   
})
=======
  });
});

// Test endpoint
app.get('/api/test', (req, res) => {
  res.json({ message: 'API is working!', timestamp: new Date().toISOString() });
});

// Safely import handlers
const auth = safeImport('./handlers/auth', null);
const addProduct = safeImport('./handlers/addProduct');
const addToCart = safeImport('./handlers/addToCart');
const checkRole = safeImport('./handlers/checkRole', () => (req, res, next) => next());
const deleteCart = safeImport('./handlers/deleteCart');
const jwts = safeImport('./handlers/jwts', { verifyToken: (req, res, next) => next() });
const listProducts = safeImport('./handlers/listProducts');
const mail = safeImport('./handlers/mail', { sendContactEmail: (req, res) => res.json({ message: 'Email endpoint' }) });
const saveComment = safeImport('./handlers/saveComment');
const searchProducts = safeImport('./handlers/searchProducts');
const showCart = safeImport('./handlers/showCart');
const showProduct = safeImport('./handlers/showProduct');
const showReview = safeImport('./handlers/showReview');
const upload = safeImport('./handlers/upload');

// API Routes - only add if handlers exist
if (auth) {
  if (auth.signup) app.post('/api/auth/signup', auth.signup);
  if (auth.login) app.post('/api/auth/login', auth.login);
  if (auth.refreshToken) app.post('/api/auth/refresh', auth.refreshToken);
  if (auth.logout) app.post('/api/auth/logout', auth.logout);
}

if (listProducts) app.get('/api/products', listProducts);
if (showProduct) app.get('/api/products/:id', showProduct);
if (addProduct) app.post('/api/products', addProduct);
if (searchProducts) app.get('/api/products/search', searchProducts);
if (showCart) app.get('/api/cart', showCart);
if (addToCart) app.post('/api/cart', addToCart);
if (deleteCart) app.delete('/api/cart/:id', deleteCart);
if (showReview) app.get('/api/products/:id/reviews', showReview);
if (saveComment) app.post('/api/products/:id/reviews', saveComment);
if (mail && mail.sendContactEmail) app.post('/api/contact', mail.sendContactEmail);
if (upload) app.post('/api/upload', upload.single('file'), (req, res) => {
  res.json({ url: req.file ? `/uploads/${req.file.filename}` : null });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: `Route ${req.method} ${req.url} not found` });
});

// Error handling middleware
app.use((err, req, res, next) => {
  logger.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Internal server error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// MongoDB connection (optional)
if (process.env.MONGODB_URI) {
  mongoose.connect(process.env.MONGODB_URI)
    .then(() => console.log('✅ MongoDB connected'))
    .catch(err => console.error('❌ MongoDB connection error:', err.message));
} else {
  console.log('⚠️ No MONGODB_URI provided, running without database');
}

// Start server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`========================================`);
  console.log(`🚀 E-commerce Backend API`);
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🔗 Port: ${PORT}`);
  console.log(`💚 Health: http://localhost:${PORT}/health`);
  console.log(`🧪 Test: http://localhost:${PORT}/api/test`);
  console.log(`========================================`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received');
  server.close(() => {
    mongoose.connection.close(false, () => process.exit(0));
  });
});

module.exports = app;
>>>>>>> main
