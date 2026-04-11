import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:retro_route/model/orderhistory_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/view/order/orderhistory_detail_view.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/order_view_model/order_view_model.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });

    // Fetch orders on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = ref.read(authNotifierProvider).value?.data?.token;
      if (token != null) {
        ref.read(orderHistoryProvider.notifier).fetchOrders(token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Order> _filterOrders(List<Order> orders, bool isActive) {
    var filtered = orders.where((order) {
      final matchesSearch =
          order.orderId.toLowerCase().contains(_searchQuery) ||
          order.customerNote.toLowerCase().contains(_searchQuery);

      final isActiveOrder = [
        'Pending',
        'Processing',
        'Shipped',
        'On My Way',
        'water_tested',
      ].contains(order.deliveryStatus);

      return matchesSearch && (isActive ? isActiveOrder : !isActiveOrder);
    }).toList();

    // Optional: sort by date descending
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: customText(
          text: "My Orders",
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.btnColor,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
            child: CustomTextField(
              controller: _searchController,
              hintText: "Search by Order ID or note...",
              prefixIcon: Icons.search_rounded,
              suffixIcon: _searchQuery.isNotEmpty ? Icons.clear_rounded : null,
              onSuffixTap: _searchQuery.isNotEmpty
                  ? () => _searchController.clear()
                  : null,
              borderRadius: 20.r,
              fillColor: Colors.white,
              width: 1.sw,
            ),
          ),

          // Tab content
          Expanded(
            child: ordersState.when(
              data: (orders) {
                final activeOrders = _filterOrders(orders, true);
                final completedOrders = _filterOrders(orders, false);

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(activeOrders, isActive: true),
                    _buildOrderList(completedOrders, isActive: false),
                  ],
                );
              },
              loading: () => ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: 6, // show 6 fake shimmering order cards
                itemBuilder: (context, index) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: const ShimmerOrderCard(),
                ),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    customText(
                      text: "Failed to load orders",
                      fontSize: 18.sp,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                    verticalSpacer(height: 16.h),
                    customButton(
                      context: context,
                      text: "Retry",
                      width: 240.w,
                      onPressed: () {
                        final token = ref
                            .read(authNotifierProvider)
                            .value
                            ?.data
                            ?.token;
                        if (token != null) {
                          ref
                              .read(orderHistoryProvider.notifier)
                              .fetchOrders(token);
                        }
                      },
                      fontSize: 16,
                      height: 48,
                      borderColor: AppColors.btnColor,
                      bgColor: AppColors.btnColor,
                      fontColor: AppColors.white,
                      borderRadius: 16,
                      isCircular: false,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<Order> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? Icons.hourglass_empty : Icons.check_circle_outline,
              size: 80.sp,
              color: Colors.black,
            ),
            verticalSpacer(height: 16),
            customText(
              text: isActive ? "No active orders" : "No completed orders",
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            verticalSpacer(height: 8),
            customText(
              text: "Your recent orders will appear here",
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Order Card Widget
class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd MMM yyyy • hh:mm a");
    final statusColor = _getStatusColor(order.deliveryStatus);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailsScreen(order: order)),
        );
      },
      child: Card(
        color: AppColors.cardBgColor,
        margin: EdgeInsets.only(bottom: 12.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customText(
                    text: "Order ${order.orderId}",
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      customText(
                        text: "Delivery",
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 2.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: customText(
                          text: order.deliveryStatus,
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              verticalSpacer(height: 8),
              customText(
                text: dateFormat.format(order.createdAt.toLocal()),
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
              verticalSpacer(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      customText(
                        text: "Total",
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      customText(
                        text: "\$${order.total.toStringAsFixed(2)}",
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      customText(
                        text: "Payment",
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      customText(
                        text: order.paymentStatus,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: order.paymentStatus == "Paid"
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
              verticalSpacer(height: 12.h),
              Divider(color: Colors.black26),
              verticalSpacer(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  customText(
                    text:
                        "${order.totalItemCount} item${order.totalItemCount > 1 ? 's' : ''}",
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.black,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'pending':
        return Colors.amber;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
