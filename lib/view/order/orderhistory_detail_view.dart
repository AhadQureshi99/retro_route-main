import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/model/orderhistory_model.dart';
import 'package:retro_route/utils/app_colors.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd MMM yyyy • hh:mm a");

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: customText(text: "Order Details", fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.white),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildInfoCard(
              title: "Order Summary",
              children: [
                _buildRow("Order ID", order.orderId),
                _buildRow("Placed on", dateFormat.format(order.createdAt.toLocal())),
                _buildRow("Status", order.deliveryStatus,
                    color: _getStatusColor(order.deliveryStatus)),
                _buildRow("Payment", order.paymentStatus,
                    color: order.paymentStatus == "Paid" ? Colors.green : Colors.orange),
                _buildRow("Total Amount", "\$${order.total.toStringAsFixed(2)}",
                    isBold: true),
                if (order.deliveryZone.isNotEmpty)
                  _buildRow("Zone", order.deliveryZone),
                if (order.deliveryDay.isNotEmpty)
                  _buildRow("Delivery Day", order.deliveryDay),
                if (order.scheduledDeliveryDate != null)
                  _buildRow("Delivery Date", dateFormat.format(order.scheduledDeliveryDate!.toLocal())),
              ],
            ),

            verticalSpacer(height: 16),

            // Delivery Address
            _buildInfoCard(
              title: "Delivery Address",
              children: [
                if (order.deliveryAddress != null) ...[
                  customText(
                    text: order.deliveryAddress!.addressLine,
                    fontSize: 15,
                    maxLine: 3, fontWeight: FontWeight.w500, color: AppColors.black,
                  ),
                  verticalSpacer(height: 4),
                  customText(
                    text:
                        "${order.deliveryAddress!.city}, ${order.deliveryAddress!.state}, ${order.deliveryAddress!.country}",
                    fontSize: 14,
                    color: Colors.black, fontWeight: FontWeight.w500,
                  ),
                ] else
                  customText(text: "No address info", color: Colors.black, fontWeight: FontWeight.w500,
                   fontSize: 16),
              ],
            ),

            verticalSpacer(height: 16),

            // Items
            _buildInfoCard(
              title: "Items (${order.products.length})",
              children: order.products.map((p) {
                final prod = p.productId;
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: CachedNetworkImage(
                          imageUrl: prod.images.isNotEmpty ? prod.images.first : '',
                          width: 70.w,
                          height: 70.w,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported),
                        ),
                      ),
                      horizontalSpacer(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customText(
                              text: prod.name,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              maxLine: 2, color: AppColors.black,
                            ),
                            verticalSpacer(height: 4.h),
                            customText(
                              text: "Qty: ${p.quantity} • \$${p.priceAtPurchase.toStringAsFixed(2)}",
                              fontSize: 13,
                              color: Colors.black, fontWeight: FontWeight.w400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            verticalSpacer(height: 16),

            // Price Breakdown
            _buildInfoCard(
              title: "Price Breakdown",
              children: [
                _buildPriceRow("Subtotal", order.subtotal),
                if (order.waterTestDiscount > 0)
                  _buildPriceRow("Water Test Discount", -order.waterTestDiscount),
                _buildPriceRow("Delivery Charges", order.deliveryCharges),
                _buildPriceRow("HST (13%)", order.hst),
                Divider(height: 24.h),
                _buildPriceRow("Total", order.total, isBold: true),
              ],
            ),

            verticalSpacer(height: 24),

            // Note
            if (order.customerNote.isNotEmpty)
              _buildInfoCard(
                title: "Customer Note",
                children: [
                  customText(
                    text: order.customerNote,
                    fontSize: 14,
                    color: Colors.black, fontWeight: FontWeight.w500,
                  ),
                ],
              ),

            verticalSpacer(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: AppColors.cardBgColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customText(
              text: title,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            verticalSpacer(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          customText(
            text: label,
            fontSize: 14,
            color: Colors.black, fontWeight: FontWeight.w500,
          ),
          customText(
            text: value,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          customText(
            text: label,
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: AppColors.black,
          ),
          customText(
            text: "\$${amount.toStringAsFixed(2)}",
            fontSize: isBold ? 17 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? AppColors.primary : AppColors.black,
          ),
        ],
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