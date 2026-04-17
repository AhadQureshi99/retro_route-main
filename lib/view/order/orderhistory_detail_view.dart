import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/model/orderhistory_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_urls.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("dd MMM yyyy • hh:mm a");
    final dateOnlyFormat = DateFormat("dd MMM yyyy");

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
                _buildRow("Total Amount", "\$${_combinedTotal(order).toStringAsFixed(2)}",
                    isBold: true),
                if (order.deliveryZone.isNotEmpty)
                  _buildRow("Zone", order.deliveryZone),
                if (order.deliveryDay.isNotEmpty)
                  _buildRow("Delivery Day", order.deliveryDay),
                if (order.scheduledDeliveryDate != null)
                  _buildRow("Delivery Date", dateOnlyFormat.format(order.scheduledDeliveryDate!.toLocal())),
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
                ] else if (order.addressSnapshot != null &&
                    (order.addressSnapshot!['addressLine'] ?? '').toString().isNotEmpty) ...[
                  customText(
                    text: order.addressSnapshot!['addressLine']?.toString() ?? '',
                    fontSize: 15,
                    maxLine: 3, fontWeight: FontWeight.w500, color: AppColors.black,
                  ),
                  verticalSpacer(height: 4),
                  customText(
                    text:
                        "${order.addressSnapshot!['city'] ?? ''}, ${order.addressSnapshot!['state'] ?? ''}, ${order.addressSnapshot!['country'] ?? ''}",
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
                          imageUrl: prod.firstImage,
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
                              text: "Qty: ${p.quantity} • \$${(p.priceAtPurchase > 0 ? p.priceAtPurchase : prod.price).toStringAsFixed(2)}",
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

            // Water Test Crate Items (if any)
            if (order.pendingCrate != null &&
                (order.pendingCrate!['items'] as List?)?.isNotEmpty == true &&
                ['approved', 'paid', 'delivered'].contains(order.pendingCrate!['status'])) ...[
              _buildInfoCard(
                title: "Water Test Crate (${(order.pendingCrate!['items'] as List).length})",
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    margin: EdgeInsets.only(bottom: 12.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.science_outlined, size: 16.w, color: const Color(0xFF2E7D32)),
                        horizontalSpacer(width: 6.w),
                        customText(
                          text: "Recommended from water test",
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                  ...(order.pendingCrate!['items'] as List).map((item) {
                    final name = item['name']?.toString() ?? 'Product';
                    final qty = (item['qty'] as num?)?.toInt() ?? 1;
                    final price = (item['price'] as num?)?.toDouble() ?? 0;
                    final reason = item['reason']?.toString() ?? '';
                    final size = item['size']?.toString() ?? '';
                    final rawImage = item['image']?.toString() ?? '';
                    final image = rawImage.startsWith('/') ? '${AppUrls.baseUrl}$rawImage' : rawImage;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: image,
                                    width: 70.w,
                                    height: 70.w,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.science, color: Colors.grey[400], size: 28.w),
                                  )
                                : Container(
                                    width: 70.w,
                                    height: 70.w,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(Icons.science, color: Colors.grey[400], size: 28.w),
                                  ),
                          ),
                          horizontalSpacer(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                customText(
                                  text: name,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  maxLine: 2,
                                  color: AppColors.black,
                                ),
                                if (size.isNotEmpty) ...[
                                  verticalSpacer(height: 2.h),
                                  customText(
                                    text: "Size: $size",
                                    fontSize: 12,
                                    color: Colors.grey[600]!,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ],
                                verticalSpacer(height: 4.h),
                                customText(
                                  text: "Qty: $qty • \$${price.toStringAsFixed(2)}",
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                                if (reason.isNotEmpty) ...[
                                  verticalSpacer(height: 2.h),
                                  customText(
                                    text: reason,
                                    fontSize: 11,
                                    color: Colors.grey[500]!,
                                    fontWeight: FontWeight.w400,
                                    maxLine: 2,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  // Crate price breakdown
                  Divider(height: 16.h),
                  _buildPriceRow("Crate Items Subtotal", (order.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0),
                  _buildPriceRow("HST (13%)", (order.pendingCrate!['hst'] as num?)?.toDouble() ?? 0),
                  Divider(height: 16.h),
                  _buildPriceRow("Total Before Credit", ((order.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0) + ((order.pendingCrate!['hst'] as num?)?.toDouble() ?? 0), isBold: true),
                  if ((order.pendingCrate!['credit'] as num?)?.toDouble() != null &&
                      (order.pendingCrate!['credit'] as num).toDouble() > 0)
                    _buildColoredPriceRow("Water Test Credit (incl. HST)", -(order.pendingCrate!['credit'] as num).toDouble(), const Color(0xFFE65100)),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: List.generate(
                            (constraints.maxWidth / 8).floor(),
                            (i) => Expanded(
                              child: Container(
                                height: 1,
                                color: (i % 2 == 0) ? Colors.grey.shade300 : Colors.transparent,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildPriceRow("Total Paid", (order.pendingCrate!['total'] as num?)?.toDouble() ?? 0, isBold: true),
                ],
              ),
              verticalSpacer(height: 16),
            ],

            // Price Breakdown
            _buildInfoCard(
              title: "Price Breakdown",
              children: [
                _buildPriceRow("Subtotal", order.subtotal),
                if (order.waterTestDiscount > 0) ...[                  
                  _buildColoredPriceRow("Water Test Discount", -order.waterTestDiscount, const Color(0xFFE65100)),
                  _buildPriceRow("After Discount", (order.subtotal - order.waterTestDiscount).clamp(0, double.infinity), isBold: true),
                ],
                if (order.deliveryCharges > 0)
                  _buildPriceRow("Delivery Charges", order.deliveryCharges),
                _buildPriceRow("Tax (HST 13%)", order.hst),
                Divider(height: 24.h),
                _buildPriceRow("Total", order.total, isBold: true),
                if (_crateTotal(order) > 0) ...[                  
                  _buildPriceRow("Crate Total", _crateTotal(order), isBold: true),
                  Divider(height: 24.h),
                  _buildPriceRow("Combined Total", _combinedTotal(order), isBold: true),
                ],
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

  Widget _buildColoredPriceRow(String label, double amount, Color labelColor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          customText(
            text: label,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
          customText(
            text: "\$${amount.toStringAsFixed(2)}",
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: labelColor,
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

  double _crateTotal(Order order) {
    final crate = order.pendingCrate;
    if (crate == null) return 0;
    final status = crate['status']?.toString() ?? '';
    if (!['approved', 'paid', 'delivered'].contains(status)) return 0;
    return (crate['total'] as num?)?.toDouble() ?? 0;
  }

  double _combinedTotal(Order order) => order.total + _crateTotal(order);
}