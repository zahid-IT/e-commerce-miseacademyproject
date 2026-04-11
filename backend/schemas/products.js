const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
        index: true
    },
    description: {
        type: String,
        required: true
    },
    price: {
        type: Number,
        required: true,
        min: 0
    },
    compareAtPrice: {
        type: Number,
        min: 0
    },
    costPerItem: {
        type: Number,
        min: 0
    },
    sku: {
        type: String,
        unique: true,
        sparse: true
    },
    barcode: String,
    quantity: {
        type: Number,
        default: 0,
        min: 0
    },
    trackQuantity: {
        type: Boolean,
        default: true
    },
    category: {
        type: String,
        required: true,
        index: true
    },
    tags: [String],
    images: [{
        url: String,
        alt: String,
        isMain: Boolean
    }],
    variants: [{
        name: String,
        sku: String,
        price: Number,
        quantity: Number,
        attributes: Map
    }],
    attributes: {
        type: Map,
        of: String
    },
    rating: {
        average: {
            type: Number,
            default: 0
        },
        count: {
            type: Number,
            default: 0
        }
    },
    isActive: {
        type: Boolean,
        default: true
    },
    isFeatured: {
        type: Boolean,
        default: false
    },
    seo: {
        title: String,
        description: String,
        keywords: [String]
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Create text index for search
productSchema.index({ name: 'text', description: 'text', tags: 'text' });

// Update timestamp on save
productSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

module.exports = mongoose.model('Product', productSchema);
