import 'package:flutter/material.dart';
import 'package:ftmithaimart/components/order_tracking.dart';
import 'package:ftmithaimart/model/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../model/cart_model.dart';

class ReceiptScreen extends StatefulWidget {
  final String orderId;
  final List<Cart> cartItems;
  final DateTime orderDateTime;
  final String name;
  final double totalAmount;
  final bool isCustomized;

  const ReceiptScreen({
    Key? key,
    required this.orderId,
    required this.cartItems,
    required this.orderDateTime,
    required this.name,
    required this.totalAmount,
    required this.isCustomized,
  }) : super(key: key);

  @override
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<Offset>? _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    for (var item in widget.cartItems) {}

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF63131C),
        iconTheme: const IconThemeData(color: Colors.white),
        toolbarHeight: 100,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.all(0.0),
          child: Image.asset(
            "assets/Logo.png",
            width: 50,
            height: 50,
            // alignment: Alignment.center,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _offsetAnimation == null
                ? Container()
                : SlideTransition(
                    position: _offsetAnimation!,
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "Thank you for choosing F.T Mithai Mart",
                        style: TextStyle(
                          color: Color(0xFF63131C),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    const Text(
                      "INVOICE",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    ListTile(
                      title: Text('Order ID: ${widget.orderId}'),
                    ),
                    ListTile(
                      title: Text(
                          'Order Date & Time: ${DateFormat(' E,d MMM y hh:mm a').format(widget.orderDateTime)}'),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = widget.cartItems[index];
                        return ListTile(
                          title: Text(cartItem.productName),
                          subtitle: Text('${cartItem.formattedQuantity} kgs'),
                          trailing: Text('Rs. ${cartItem.price}'),
                        );
                      },
                    ),
                    ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount: Rs. ${widget.totalAmount.toStringAsFixed(2)}',
                          ),
                          if (widget.isCustomized)
                            const Text(
                              'Free Customization Availed!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff63131C),
                      ),
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false)
                            .resetCustomize();
                        Provider.of<CartProvider>(context, listen: false)
                            .clearCart();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderTracking(name: widget.name),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.track_changes,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Track Order",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
