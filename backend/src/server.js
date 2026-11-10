const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs').promises;

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../products')));

// Load product data from JSON file
let products = [];

async function loadProducts() {
  try {
    const data = await fs.readFile(path.join(__dirname, 'data/products.json'), 'utf8');
    products = JSON.parse(data);
  } catch (error) {
    console.error('Error loading products:', error);
    // Fallback to sample data if file loading fails
    products = [
      {
        id: 1,
        name: "Rubber Plant",
        description: "A beautiful rubber plant for your indoor space",
        price: 29.99,
        category: "plants",
        image: "/product_rubber_plant.png",
        stock: 15
      },
      {
        id: 2,
        name: "Monstera Deliciosa",
        description: "The perfect statement plant for your living room",
        price: 49.99,
        category: "plants",
        image: "/product_monstera_deliciosa.png",
        stock: 8
      },
      {
        id: 3,
        name: "Organic Potting Mix",
        description: "High-quality organic soil for all your plants",
        price: 12.99,
        category: "accessories",
        image: "/product_organic_potting_mix.png",
        stock: 25
      },
      {
        id: 4,
        name: "Sandstone Pot",
        description: "Elegant sandstone planter for your indoor garden",
        price: 34.99,
        category: "planters",
        image: "/product_sandstone_pot.png",
        stock: 12
      },
      {
        id: 5,
        name: "Watering Ritual Set",
        description: "Complete set for your plant watering routine",
        price: 24.99,
        category: "accessories",
        image: "/product_watering_ritual_set.png",
        stock: 20
      },
      {
        id: 6,
        name: "White Orchid",
        description: "Delicate white orchid for your home",
        price: 39.99,
        category: "plants",
        image: "/product_white_orchid.png",
        stock: 5
      }
    ];
  }
}

// Load products when server starts
loadProducts();

// Routes
app.get('/', (req, res) => {
  res.json({
    message: "Welcome to Verdant Shop API",
    version: "1.0.0",
    endpoints: {
      "GET /api/products": "Get all products",
      "GET /api/products/:id": "Get a specific product",
      "GET /api/categories": "Get all product categories",
      "GET /api/featured": "Get featured products"
    }
  });
});

// Get all products
app.get('/api/products', (req, res) => {
  res.json({
    success: true,
    data: products,
    count: products.length
  });
});

// Get a specific product
app.get('/api/products/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const product = products.find(p => p.id === id);
  
  if (!product) {
    return res.status(404).json({
      success: false,
      message: "Product not found"
    });
  }
  
  res.json({
    success: true,
    data: product
  });
});

// Get products by category
app.get('/api/categories/:category', (req, res) => {
  const category = req.params.category;
  const categoryProducts = products.filter(p => p.category === category);
  
  res.json({
    success: true,
    data: categoryProducts,
    count: categoryProducts.length,
    category: category
  });
});

// Get all categories
app.get('/api/categories', (req, res) => {
  const categories = [...new Set(products.map(p => p.category))];
  
  res.json({
    success: true,
    data: categories,
    count: categories.length
  });
});

// Get featured products (top 3)
app.get('/api/featured', (req, res) => {
  const featured = products.slice(0, 3);
  
  res.json({
    success: true,
    data: featured,
    count: featured.length
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;