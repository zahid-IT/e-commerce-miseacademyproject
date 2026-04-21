const Cart = require('../schemas/cart');

module.exports = async (req, res) => {
  try {
    const userId = req.user?.id || 'temp_user_id';
    const cart = await Cart.findOne({ userId }).populate('items.productId');
    
    if (!cart) {
      return res.json({ items: [], totalAmount: 0 });
    }
    
    res.json(cart);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
