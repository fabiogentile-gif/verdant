const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const path = require("path");
const fs = require("fs").promises;

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, "../products")));

// Load product data from JSON file
let products = [];

async function loadProducts() {
  try {
    const data = await fs.readFile(
      path.join(__dirname, "data/products.json"),
      "utf8",
    );
    products = JSON.parse(data);
  } catch (error) {
    console.error("Error loading products:", error);
  }
}

// Load products when server starts
loadProducts();

// Routes
app.get("/", (req, res) => {
  res.json({
    message: "Welcome to Verdant Shop API",
    version: "1.0.0",
    endpoints: {
      "GET /api/products": "Get all products (optional ?category=)",
      "GET /api/products/:id": "Get a specific product",
      "GET /api/categories": "Get all product categories",
      "GET /api/featured": "Get featured products",
    },
  });
});

// Get all products (optionally filtered by ?category=)
app.get("/api/products", (req, res) => {
  const { category } = req.query;
  const result = category
    ? products.filter((p) => p.category === category)
    : products;

  res.json({
    success: true,
    data: result,
    count: result.length,
  });
});

// Get a specific product
app.get("/api/products/:id", (req, res) => {
  const id = parseInt(req.params.id, 10);
  const product = products.find((p) => p.id === id);

  if (!product) {
    return res.status(404).json({
      success: false,
      message: "Product not found",
    });
  }

  const { relatedIds = [], ...rest } = product;
  const related = relatedIds
    .map((rid) => products.find((p) => p.id === rid))
    .filter(Boolean)
    .map(({ id, name, price, image, tag }) => ({ id, name, price, image, tag }));

  res.json({
    success: true,
    data: { ...rest, related },
  });
});

// Get products by category
app.get("/api/categories/:category", (req, res) => {
  const category = req.params.category;
  const categoryProducts = products.filter((p) => p.category === category);

  res.json({
    success: true,
    data: categoryProducts,
    count: categoryProducts.length,
    category: category,
  });
});

// Get all categories
app.get("/api/categories", (req, res) => {
  const categories = [...new Set(products.map((p) => p.category))];

  res.json({
    success: true,
    data: categories,
    count: categories.length,
  });
});

// Get featured products (top 3)
app.get("/api/featured", (req, res) => {
  const featured = products.filter((p) => p.featured);

  res.json({
    success: true,
    data: featured,
    count: featured.length,
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
