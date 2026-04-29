const Cart = require('../schemas/cart');

module.exports = async (req, res) => {
  try {
    const { productId, quantity, price } = req.body;
    const userId = req.user?.id || 'temp_user_id';
    
    let cart = await Cart.findOne({ userId });
    
    if (!cart) {
      cart = new Cart({
        userId,
        items: [{ productId, quantity, price }],
        totalAmount: price * quantity
      });
    } else {
      const itemIndex = cart.items.findIndex(item => item.productId.toString() === productId);
      
      if (itemIndex > -1) {
        cart.items[itemIndex].quantity += quantity;
      } else {
        cart.items.push({ productId, quantity, price });
      }
      
      cart.totalAmount = cart.items.reduce((total, item) => total + (item.price * item.quantity), 0);
    }
    
    await cart.save();
    res.json({ success: true, cart });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
