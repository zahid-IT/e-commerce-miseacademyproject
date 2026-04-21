const Cart = require('../schemas/cart');

module.exports = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user?.id || 'temp_user_id';
    
    const cart = await Cart.findOne({ userId });
    
    if (!cart) {
      return res.status(404).json({ error: 'Cart not found' });
    }
    
    cart.items = cart.items.filter(item => item._id.toString() !== id);
    cart.totalAmount = cart.items.reduce((total, item) => total + (item.price * item.quantity), 0);
    
    await cart.save();
    res.json({ success: true, cart });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
