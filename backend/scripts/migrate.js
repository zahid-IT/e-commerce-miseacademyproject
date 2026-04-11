const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');

async function runMigrations() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to MongoDB');
        
        const db = mongoose.connection.db;
        const migrations = fs.readdirSync(path.join(__dirname, '../migrations'))
            .filter(f => f.endsWith('.js'))
            .sort();
        
        // Track migrations
        await db.createCollection('migrations');
        const migrated = await db.collection('migrations').find().toArray();
        const migratedNames = migrated.map(m => m.name);
        
        for (const migrationFile of migrations) {
            if (!migratedNames.includes(migrationFile)) {
                console.log(`Running migration: ${migrationFile}`);
                const migration = require(`../migrations/${migrationFile}`);
                await migration.up(db);
                await db.collection('migrations').insertOne({
                    name: migrationFile,
                    appliedAt: new Date()
                });
                console.log(`Migration ${migrationFile} completed`);
            }
        }
        
        console.log('All migrations completed');
        process.exit(0);
    } catch (error) {
        console.error('Migration failed:', error);
        process.exit(1);
    }
}

runMigrations();
