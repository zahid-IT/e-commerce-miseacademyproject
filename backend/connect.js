const mongoose = require('mongoose');
const logger = require('./logger'); // Optional: Add logging

class DatabaseConnection {
    constructor() {
        this.isConnected = false;
    }

    async connect() {
        const mongoURI = process.env.MONGODB_URI || 'mongodb://localhost:27017/ecommerce';
        const options = {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            maxPoolSize: 10,
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
            family: 4,
            retryWrites: true,
            retryReads: true
        };

        try {
            await mongoose.connect(mongoURI, options);
            this.isConnected = true;
            logger.info(`MongoDB connected successfully to ${process.env.NODE_ENV} environment`);
            
            // Handle connection events
            mongoose.connection.on('error', (err) => {
                logger.error('MongoDB connection error:', err);
            });
            
            mongoose.connection.on('disconnected', () => {
                logger.warn('MongoDB disconnected');
                this.isConnected = false;
            });
            
            mongoose.connection.on('reconnected', () => {
                logger.info('MongoDB reconnected');
                this.isConnected = true;
            });
            
            return mongoose.connection;
        } catch (error) {
            logger.error('MongoDB connection failed:', error);
            process.exit(1);
        }
    }

    async disconnect() {
        if (this.isConnected) {
            await mongoose.disconnect();
            this.isConnected = false;
            logger.info('MongoDB disconnected');
        }
    }

    getStatus() {
        return {
            isConnected: this.isConnected,
            readyState: mongoose.connection.readyState,
            host: mongoose.connection.host,
            name: mongoose.connection.name
        };
    }
}

module.exports = new DatabaseConnection();
