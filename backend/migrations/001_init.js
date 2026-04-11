// MongoDB initialization script
async function up(db) {
    console.log('Running migration 001: Initial schema setup');
    
    // Create collections
    await db.createCollection('users');
    await db.createCollection('products');
    await db.createCollection('orders');
    await db.createCollection('reviews');
    await db.createCollection('carts');
    
    // Create indexes
    await db.collection('users').createIndex({ email: 1 }, { unique: true });
    await db.collection('products').createIndex({ name: 'text', description: 'text' });
    await db.collection('products').createIndex({ category: 1 });
    await db.collection('products').createIndex({ price: 1 });
    await db.collection('orders').createIndex({ userId: 1, createdAt: -1 });
    await db.collection('orders').createIndex({ orderNumber: 1 }, { unique: true });
    await db.collection('reviews').createIndex({ productId: 1, userId: 1 }, { unique: true });
    
    console.log('Migration 001 completed');
}

async function down(db) {
    console.log('Rolling back migration 001');
    await db.dropCollection('users');
    await db.dropCollection('products');
    await db.dropCollection('orders');
    await db.dropCollection('reviews');
    await db.dropCollection('carts');
}

module.exports = { up, down };
