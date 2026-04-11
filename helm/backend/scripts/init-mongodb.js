// MongoDB initialization script for seeding data
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

async function initializeDatabase() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB for initialization');
        
        // Create indexes
        console.log('Creating indexes...');
        await mongoose.connection.db.collection('users').createIndex({ email: 1 }, { unique: true });
        await mongoose.connection.db.collection('products').createIndex({ name: 'text', description: 'text' });
        await mongoose.connection.db.collection('orders').createIndex({ orderNumber: 1 }, { unique: true });
        await mongoose.connection.db.collection('orders').createIndex({ user: 1, createdAt: -1 });
        
        // Seed admin user if not exists
        const User = require('../schemas/users');
        const adminExists = await User.findOne({ role: 'admin' });
        
        if (!adminExists && process.env.NODE_ENV !== 'production') {
            console.log('Creating admin user...');
            await User.create({
                email: 'admin@ecommerce.com',
                password: 'Admin123!',
                name: 'Admin User',
                role: 'admin'
            });
            console.log('Admin user created');
        }
        
        // Seed sample products for dev/staging
        if (process.env.NODE_ENV !== 'production') {
            const Product = require('../schemas/products');
            const productCount = await Product.countDocuments();
            
            if (productCount === 0) {
                console.log('Seeding sample products...');
                const sampleProducts = [
                    {
                        name: 'Sample Product 1',
                        description: 'This is a sample product',
                        price: 29.99,
                        quantity: 100,
                        category: 'Electronics',
                        images: [{ url: 'https://via.placeholder.com/300', isMain: true }]
                    },
                    {
                        name: 'Sample Product 2',
                        description: 'Another sample product',
                        price: 49.99,
                        quantity: 50,
                        category: 'Clothing',
                        images: [{ url: 'https://via.placeholder.com/300', isMain: true }]
                    }
                ];
                await Product.insertMany(sampleProducts);
                console.log('Sample products seeded');
            }
        }
        
        console.log('Database initialization completed');
        process.exit(0);
    } catch (error) {
        console.error('Database initialization failed:', error);
        process.exit(1);
    }
}

initializeDatabase();
