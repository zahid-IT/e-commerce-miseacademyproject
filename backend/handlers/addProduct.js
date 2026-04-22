const Product = require("../schemas/products");

module.exports = async (req, res) => {
  try {
    const { name, description, price, category, stock } = req.body;
    
    // Validate required fields
    if (!name || !price) {
      return res.status(400).json({ error: "Name and price are required" });
    }
    
    const product = new Product({
      name,
      description: description || "",
      price: parseFloat(price),
      category: category || "Uncategorized",
      stock: parseInt(stock) || 0
    });
    
    await product.save();
    res.status(201).json({ success: true, product });
  } catch (error) {
    console.error("Error adding product:", error);
    res.status(500).json({ error: error.message });
  }
}

