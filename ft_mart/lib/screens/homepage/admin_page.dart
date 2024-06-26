import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ftmithaimart/components/admindrawer.dart';
import 'package:ftmithaimart/dbHelper/mongodb.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../model/orders_model.dart';
import '../../push_notifications.dart';

class admin extends StatefulWidget {
  final String name;
  final String? email;
  final String? contact;

  const admin({super.key, required this.name, this.email, this.contact});

  @override
  State<admin> createState() => _adminState();
}

class _adminState extends State<admin> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Order> orders = [];
  int selectedWeek = 1;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchOrders() async {
    final List<Order> fetchedOrders = await MongoDatabase.getOrders();
    setState(() {
      orders = fetchedOrders;
    });
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final orderIndex = orders.indexWhere((order) => order.orderId == orderId);
    if (orderIndex != -1) {
      setState(() {
        orders[orderIndex].status = newStatus;
      });
      await MongoDatabase.updateOrderStatus(orderId, newStatus);

      Order order = orders[orderIndex];

      if (newStatus == 'Ready for Pickup') {
        await PushNotifications.sendNotification(
            orderId,
            order.deviceToken,
            'Order Ready for Pickup',
            'Your order with ID $orderId is ready for pickup!\nTrack Your Order By Clicking Here.');
      } else if (newStatus == 'Ready for Delivery') {
        await PushNotifications.sendNotification(
            orderId,
            order.deviceToken,
            'Order Ready For Delivery',
            'Your order with ID $orderId is ready for delivery!\nRider on the Way! Track now.');
      } else if (newStatus == 'Delivered') {
        await PushNotifications.sendNotification(orderId, order.deviceToken,
            'Delivered!', 'Your order with ID $orderId is Delivered!\nEnjoy!');
      }
    }
  }

  Map<String, double> calculateTotalSalesPerDay(List<Order> orders) {
    Map<String, double> totalSalesPerDay = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var order in orders) {
      final dateKey = dateFormat.format(order.orderDateTime);
      totalSalesPerDay.update(dateKey, (value) => value + order.totalAmount,
          ifAbsent: () => order.totalAmount);
    }
    return totalSalesPerDay;
  }

  Map<String, int> calculateTotalOrdersPerDay(List<Order> orders) {
    Map<String, int> totalOrdersPerDay = {};
    final dateFormat = DateFormat('yyyy-MM-dd');
    for (var order in orders) {
      final dateKey = dateFormat.format(order.orderDateTime);
      totalOrdersPerDay.update(dateKey, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return totalOrdersPerDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        backgroundColor: const Color(0xff63131C),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Current Orders',
            ),
            Tab(text: 'Completed Orders'),
            Tab(text: 'Total Sales'),
          ],
          indicatorColor: Colors.white,
          labelColor: const Color(0xffffC937),
          unselectedLabelColor: Colors.white,
          labelPadding: const EdgeInsets.symmetric(horizontal: 2.0),
        ),
      ),
      drawer: AdminDrawer(
        name: widget.name,
        email: widget.email,
        contact: widget.contact,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Welcome, Admin!',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xff63131C),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildCurrentOrdersTab(),
                buildCompletedOrdersTab(),
                buildTotalSalesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCurrentOrdersTab() {
    return FutureBuilder<List<Order>>(
      future: fetchCurrentOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xff63131C),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else if (snapshot.hasData) {
          final currentOrders = snapshot.data!;
          return ListView.builder(
            itemCount: currentOrders.length,
            itemBuilder: (context, index) {
              final order = currentOrders[index];
              return buildOrderItem(order);
            },
          );
        } else {
          return const Center(
            child: Text('No data available.'),
          );
        }
      },
    );
  }

  Future<List<Order>> fetchCurrentOrders() async {
    final List<Order> fetchedOrders = await MongoDatabase.getOrders();
    return fetchedOrders.where((order) => order.status != 'Delivered').toList();
  }

  Widget buildCompletedOrdersTab() {
    final completedOrders =
        orders.where((order) => order.status == 'Delivered').toList();
    return ListView.builder(
      itemCount: completedOrders.length,
      itemBuilder: (context, index) {
        final order = completedOrders[index];
        return buildOrderItem(order);
      },
    );
  }

  Widget buildTotalSalesTab() {
    if (selectedWeek == 1 && selectedYear == DateTime.now().year) {
      selectedWeek = getIsoWeekNumber(DateTime.now());
    }

    final List<Order> selectedWeekOrders = orders.where((order) {
      final orderWeek = getIsoWeekNumber(order.orderDateTime);
      final orderYear = order.orderDateTime.year;
      return order.status == 'Delivered' &&
          orderWeek == selectedWeek &&
          orderYear == selectedYear;
    }).toList();

    final Map<String, double> totalSalesPerDay =
        calculateTotalSalesPerDay(selectedWeekOrders);
    final Map<String, int> totalOrdersPerDay =
        calculateTotalOrdersPerDay(selectedWeekOrders);

    final List<Color> fixedColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
    ];

    final List<PieChartSectionData> pieChartSections =
        List.generate(7, (index) {
      if (index < selectedWeekOrders.length) {
        final day = DateFormat('yyyy-MM-dd')
            .format(selectedWeekOrders[index].orderDateTime);
        final sales = totalSalesPerDay[day] ?? 0.0;
        final orders = totalOrdersPerDay[day] ?? 0;

        return PieChartSectionData(
          color: fixedColors[index],
          value: sales,
          title: '$day\nOrders: $orders',
          radius: 70,
        );
      } else {
        return PieChartSectionData(
          color: Colors.transparent,
          value: 0.0,
          title: 'No sales',
          radius: 70,
        );
      }
    });

    final DateTime firstDayOfWeek = DateTime(selectedYear, 1, 1)
        .add(Duration(days: (selectedWeek - 1) * 7));
    DateFormat('MMMM').format(firstDayOfWeek);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (selectedYear > 2000) selectedYear--;
                });
              },
            ),
            Text(
              '$selectedYear',
              style: const TextStyle(color: Color(0xff63131C)),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  if (selectedYear < DateTime.now().year) selectedYear++;
                });
              },
            ),
            const SizedBox(
              width: 100,
            ),
            DropdownButton<int>(
              icon: const Icon(
                Icons.calendar_today,
                color: Color(0xff63131C),
              ),
              value: selectedWeek,
              items: List.generate(52, (index) {
                final weekNumber = index + 1;
                final DateTime firstDayOfWeek = DateTime(selectedYear, 1, 1)
                    .add(Duration(days: (weekNumber - 1) * 7));
                final String monthName =
                    DateFormat('MMMM').format(firstDayOfWeek);
                return DropdownMenuItem<int>(
                  value: weekNumber,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week $weekNumber',
                        style: const TextStyle(color: Color(0xff63131C)),
                      ),
                      Text(
                        '($monthName)',
                        style: const TextStyle(color: Color(0xff63131C)),
                      ),
                    ],
                  ),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedWeek = value!;
                });
              },
            )
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Expanded(
          flex: 1,
          child: PieChart(
            PieChartData(
              sections: pieChartSections,
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('Total Sales')),
              ],
              rows: [
                ...List.generate(7, (index) {
                  final day = DateFormat('yyyy-MM-dd').format(
                      DateTime(selectedYear, 1, 1)
                          .add(Duration(days: (selectedWeek - 1) * 7 + index)));
                  final sales = totalSalesPerDay[day] ?? 0.0;
                  return DataRow(
                    cells: [
                      DataCell(Text(day)),
                      DataCell(Text('Rs.${sales.toStringAsFixed(2)}')),
                    ],
                  );
                }),
                DataRow(
                  cells: [
                    const DataCell(Text('Total Sales')),
                    DataCell(Text('Rs.${List.generate(7, (index) {
                      final day = DateFormat('yyyy-MM-dd').format(DateTime(
                              selectedYear, 1, 1)
                          .add(Duration(days: (selectedWeek - 1) * 7 + index)));
                      return totalSalesPerDay[day] ?? 0.0;
                    }).reduce((a, b) => a + b).toStringAsFixed(2)}')),
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  int getIsoWeekNumber(DateTime date) {
    // Calculate ISO week number
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));

    final diff = date.difference(firstMonday);
    final weekNumber = (diff.inDays / 7).ceil();
    return weekNumber;
  }

  Color getRandomColor() {
    final Random random = Random();
    return Color.fromARGB(
      255,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  Widget buildOrderItem(Order order) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) {
            return SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Details',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Text('Order ID: ${order.orderId}'),
                    Text('Name: ${order.name}'),
                    Text('Email: ${order.email}'),
                    Text('Contact: ${order.contact}'),
                    Text(
                        'Pickup/Delivery Date & Time: ${DateFormat('E, d MMM y | hh:mm a').format(order.orderDateTime)}'),
                    Text('Delivery Address: ${order.deliveryAddress ?? 'N/A'}'),
                    Text('Total Amount: ${order.totalAmount}'),
                    Text('Payment Method: ${order.payment}'),
                    const SizedBox(height: 10),
                    const Text('Products:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...List.generate(order.productNames.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                            '${order.productNames[index]} - ${order.quantities[index]} kg'),
                      );
                    }),
                    const SizedBox(height: 10),
                    if (order.orderDesign!.isNotEmpty) ...[
                      const Text('Order Designs:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      ...order.orderDesign!.map((design) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(design.productName!,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('Box Design: ${design.boxDesignID}'),
                            Text('Ribbon Design: ${design.ribbonDesignID}'),
                            Text('Wrapping Design: ${design.wrappingDesignID}'),
                            const SizedBox(height: 10),
                          ],
                        );
                      }).toList(),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        MongoDatabase.deleteOrder(order.orderId);
                        Navigator.of(context).pop();
                        fetchOrders();
                      },
                      icon: const Icon(
                        Icons.delete_outlined,
                        color: Color(0xFF63131C),
                      ),
                      label: const Text(
                        "Delete Order",
                        style: TextStyle(
                          color: Color(0xFF63131C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      child: Card(
        elevation: 10,
        color: const Color(0xffFFF8E6),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Stack(
          children: [
            ListTile(
              title: Text('Order No. ${order.orderId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF63131C),
                  )),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.name),
                  Text(
                    DateFormat(' E,d MMM y | hh:mm a')
                        .format(order.orderDateTime),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: order.deliveryAddress == 'Pickup'
                      ? const Color(0xffFFEC8C)
                      : const Color(0xffFFEC8C),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  order.deliveryAddress == 'Pickup' ? 'Pickup' : 'Delivery',
                  style: const TextStyle(color: Color(0xff8C7502)),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: DropdownButton<String>(
                value: order.status,
                items: <String>[
                  'In Process',
                  'Ready for Pickup',
                  'Ready for Delivery',
                  'Delivered'
                ].map((String value) {
                  Color backgroundColor;
                  Color textColor;
                  switch (value) {
                    case 'In Process':
                      backgroundColor = const Color(0xffA4202E);
                      textColor = Colors.white;
                      break;
                    case 'Ready for Pickup':
                      backgroundColor = Colors.orange;
                      textColor = Colors.white;
                      break;
                    case 'Ready for Delivery':
                      backgroundColor = Colors.blueGrey;
                      textColor = Colors.white;
                      break;
                    case 'Delivered':
                      backgroundColor = const Color(0xff038200);
                      textColor = Colors.white;
                      break;
                    default:
                      backgroundColor = Colors.white;
                      textColor = Colors.black;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Container(
                      color: backgroundColor,
                      width: 95,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          value,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    setState(() {
                      order.status = newValue;
                    });
                    updateOrderStatus(order.orderId, newValue);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
