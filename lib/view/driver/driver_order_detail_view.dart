import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/utils/app_urls.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverOrderDetailScreen extends ConsumerStatefulWidget {
  final DriverDelivery delivery;

  const DriverOrderDetailScreen({super.key, required this.delivery});

  @override
  ConsumerState<DriverOrderDetailScreen> createState() =>
      _DriverOrderDetailScreenState();
}

class _DriverOrderDetailScreenState
    extends ConsumerState<DriverOrderDetailScreen> {
  bool _isUpdating = false;
  final TextEditingController _notesController = TextEditingController();
  File? _proofImage;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus == 'Delivered' && _proofImage == null) {
      CustomToast.error(msg: 'Please select a delivery proof image');
      return;
    }

    setState(() => _isUpdating = true);

    final token = ref.read(authNotifierProvider).value?.data?.token ?? '';
    final orderId = widget.delivery.id ?? '';

    if (token.isEmpty || orderId.isEmpty) {
      CustomToast.error(msg: 'Invalid order or session');
      setState(() => _isUpdating = false);
      return;
    }

    bool success;
    if (newStatus == 'Delivered') {
      success = await ref
          .read(driverDeliveriesProvider.notifier)
          .updateDeliveryStatusWithProof(
            token: token,
            orderId: orderId,
            status: newStatus,
            driverNotes: _notesController.text.trim(),
            deliveryProofImage: _proofImage!,
          );
    } else {
      // Get driver's current location for ETA calculation
      double? driverLat;
      double? driverLon;
      if (newStatus == 'On My Way') {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          driverLat = pos.latitude;
          driverLon = pos.longitude;
        } catch (_) {}
      }
      success = await ref
          .read(driverDeliveriesProvider.notifier)
          .updateDeliveryStatus(
            token: token,
            orderId: orderId,
            status: newStatus,
            driverNotes: _notesController.text.trim(),
            driverLat: driverLat,
            driverLon: driverLon,
          );
    }

    setState(() => _isUpdating = false);

    if (success) {
      CustomToast.success(
        msg: newStatus == 'On My Way'
            ? 'Status updated to On My Way!'
            : 'Delivery marked as completed!',
      );
      if (mounted) {
        goRouter.pop();
      }
    } else {
      final errorMsg = ref.read(driverDeliveriesProvider).error ?? 'Failed to update status';
      CustomToast.error(msg: errorMsg.contains('active delivery') ? errorMsg : 'Failed to update status');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _openDirectionsToDelivery(DriverDelivery delivery) async {
    final deliveryLat = delivery.deliveryAddress?.deliveryLat;
    final deliveryLon = delivery.deliveryAddress?.deliveryLon;
    final address = delivery.deliveryAddress?.fullAddress;
    if (deliveryLat == null || deliveryLon == null) {
      if (address == null || address.isEmpty) return;
    }

    // Use delivery coordinates as destination (more reliable than text address)
    final destination = (deliveryLat != null && deliveryLon != null)
        ? '$deliveryLat,$deliveryLon'
        : Uri.encodeComponent(address!);

    // Get driver's current GPS position
    String origin = 'My+Location';
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        origin = '${pos.latitude},${pos.longitude}';
      }
    } catch (_) {}

    final url = 'https://www.google.com/maps/dir/?api=1'
        '&origin=$origin'
        '&destination=$destination'
        '&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final city = (delivery.deliveryAddress?.city ?? '').trim();
    final inferredZone = city.isNotEmpty ? detectZoneByCity(city) : null;
    final zoneText = (delivery.deliveryZone ?? '').trim().isNotEmpty
      ? delivery.deliveryZone!.trim()
      : inferredZone != null
        ? 'Zone ${inferredZone.id}'
        : '—';
    final dayText = (delivery.deliveryDay ?? '').trim().isNotEmpty
      ? _formatEnumValue(delivery.deliveryDay)
      : inferredZone != null
        ? inferredZone.deliveryDay
        : '—';
    final statusColor = _getStatusColor(delivery.deliveryStatus);
    final isPending = delivery.deliveryStatus?.toLowerCase() == 'pending' ;
    final isOnMyWay = delivery.deliveryStatus?.toLowerCase() == 'on my way' ||
        delivery.deliveryStatus?.toLowerCase() == 'water_tested';
    final isDelivered = delivery.deliveryStatus?.toLowerCase() == 'delivered';

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => goRouter.pop(),
        ),
        title: customText(
          text: 'Order ${delivery.safeOrderId}',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              color: statusColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getStatusIcon(delivery.deliveryStatus),
                    color: statusColor,
                    size: 24.sp,
                  ),
                  horizontalSpacer(width: 8),
                  customText(
                    text: 'Status: ${delivery.safeDeliveryStatus}',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Card
                  _buildSectionCard(
                    title: 'Customer Information',
                    icon: Icons.person,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Name',
                          delivery.safeCustomerName,
                          Icons.badge,
                        ),
                        _buildInfoRow(
                          'Email',
                          delivery.safeCustomerEmail,
                          Icons.email,
                        ),
                        if (delivery.deliveryAddress?.phoneNumber != null ||
                            delivery.userId?.phone != null)
                          _buildInfoRow(
                            'Phone',
                            delivery.deliveryAddress?.phoneNumber ??
                                delivery.userId?.phone ??
                                '',
                            Icons.phone,
                          ),
                      ],
                    ),
                  ),

                  verticalSpacer(height: 16),

                  // Delivery Address Card
                  _buildSectionCard(
                    title: 'Delivery Address',
                    icon: Icons.location_on,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        customText(
                          text: delivery.deliveryAddress?.fullName ?? 'N/A',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                       
                        verticalSpacer(height: 4),
                        customText(
                          text:
                              delivery.deliveryAddress?.fullAddress ??
                              'No address available',
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                        verticalSpacer(height: 10),
                        GestureDetector(
                          onTap: () => _openDirectionsToDelivery(delivery),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.directions,
                                    color: Colors.white, size: 16.sp),
                                SizedBox(width: 6.w),
                                Text('Navigate',
                                    style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Drop-off info shown prominently above the expandable section
                  if (delivery.userId?.deliverySafety != null &&
                      ((delivery.userId!.deliverySafety!.dropOffSpot?.trim().isNotEmpty == true) ||
                       (delivery.userId!.deliverySafety!.dropOffDetails?.trim().isNotEmpty == true))) ...[
                    verticalSpacer(height: 16),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.orange.withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.place, color: Colors.orange, size: 20.sp),
                              SizedBox(width: 8.w),
                              customText(
                                text: 'Drop-off Info',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _buildCompactInfoRow('Drop-off Spot', delivery.userId!.deliverySafety!.dropOffSpot, highlightColor: Colors.orange),
                          _buildCompactInfoRow('Drop-off Details', delivery.userId!.deliverySafety!.dropOffDetails, highlightColor: Colors.orange),
                        ],
                      ),
                    ),
                  ],

                  if (delivery.userId?.deliverySafety != null ||
                      delivery.userId?.waterSetup != null ||
                      delivery.userId?.onboardingData != null) ...[
                    verticalSpacer(height: 16),
                    _buildSectionCard(
                      title: 'Delivery Safety & Water Setup',
                      icon: Icons.shield,
                      child: _buildSafetyAndWaterSection(delivery),
                    ),
                  ],

                  verticalSpacer(height: 16),

                  // Order Details Card
                  _buildSectionCard(
                    title: 'Order Details',
                    icon: Icons.receipt_long,
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Order ID',
                          delivery.safeOrderId,
                          Icons.tag,
                        ),
                        _buildInfoRow(
                          'Payment Status',
                          delivery.safePaymentStatus,
                          Icons.payment,
                        ),
                        _buildInfoRow('Delivery Zone', zoneText, Icons.map_outlined),
                        _buildInfoRow('City', city.isNotEmpty ? city : '—', Icons.location_city_outlined),
                        _buildInfoRow('Delivery Day', dayText, Icons.today_outlined),
                        if (delivery.scheduledDeliveryDate != null)
                          _buildInfoRow(
                            'Scheduled Date',
                            DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(delivery.scheduledDeliveryDate!),
                            Icons.schedule,
                          ),
                        if (delivery.createdAt != null)
                          _buildInfoRow(
                            'Order Date',
                            DateFormat(
                              'MMM dd, yyyy',
                            ).format(delivery.createdAt!),
                            Icons.calendar_today,
                          ),
                      ],
                    ),
                  ),

                  verticalSpacer(height: 16),

                  // Products Card
                  _buildSectionCard(
                    title: 'Products (${delivery.products?.length ?? 0})',
                    icon: Icons.shopping_bag,
                    child: Column(
                      children:
                          delivery.products
                              ?.map((product) => _buildProductItem(product))
                              .toList() ??
                          [],
                    ),
                  ),

                  // Water Test Crate Items (if any)
                  if (delivery.pendingCrate != null &&
                      (delivery.pendingCrate!['items'] as List?)?.isNotEmpty == true &&
                      ['approved', 'paid', 'delivered'].contains(delivery.pendingCrate!['status'])) ...[
                    verticalSpacer(height: 16),
                    _buildSectionCard(
                      title: 'Water Test Crate (${(delivery.pendingCrate!['items'] as List).length})',
                      icon: Icons.science,
                      child: Column(
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
                          ...(delivery.pendingCrate!['items'] as List).map((item) {
                            final name = item['name']?.toString() ?? 'Product';
                            final qty = (item['qty'] as num?)?.toInt() ?? 1;
                            final price = (item['price'] as num?)?.toDouble() ?? 0;
                            final reason = item['reason']?.toString() ?? '';
                            final rawImage = item['image']?.toString() ?? '';
                            final image = rawImage.startsWith('/') ? '${AppUrls.baseUrl}$rawImage' : rawImage;
                            return Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              decoration: BoxDecoration(
                                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.r),
                                    child: Container(
                                      width: 44.w,
                                      height: 44.w,
                                      color: AppColors.bgColor,
                                      child: image.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: image,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                                              errorWidget: (context, url, error) =>
                                                  Icon(Icons.science, color: AppColors.primary, size: 20.sp),
                                            )
                                          : Icon(Icons.science, color: AppColors.primary, size: 20.sp),
                                    ),
                                  ),
                                  horizontalSpacer(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        customText(
                                          text: name,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        customText(
                                          text: 'Qty: $qty',
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                          color: AppColors.primary.withOpacity(0.75),
                                        ),
                                        if (reason.isNotEmpty)
                                          customText(
                                            text: reason,
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal,
                                            color: Colors.grey[500]!,
                                            maxLine: 2,
                                          ),
                                      ],
                                    ),
                                  ),
                                  customText(
                                    text: '\$${price.toStringAsFixed(2)}',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            );
                          }),
                          Divider(height: 16.h),
                          _buildPriceRow(
                            'Crate Items Subtotal',
                            '\$${((delivery.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                          _buildPriceRow(
                            'HST (13%)',
                            '\$${((delivery.pendingCrate!['hst'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          ),
                          Divider(height: 16.h),
                          _buildPriceRow(
                            'Total Before Credit',
                            '\$${(((delivery.pendingCrate!['subtotal'] as num?)?.toDouble() ?? 0) + ((delivery.pendingCrate!['hst'] as num?)?.toDouble() ?? 0)).toStringAsFixed(2)}',
                            isBold: true,
                          ),
                          if ((delivery.pendingCrate!['credit'] as num?)?.toDouble() != null &&
                              (delivery.pendingCrate!['credit'] as num).toDouble() > 0)
                            _buildPriceRow(
                              'Water Test Credit (incl. HST)',
                              '− \$${(delivery.pendingCrate!['credit'] as num).toDouble().toStringAsFixed(2)}',
                            ),
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
                          _buildPriceRow(
                            'Total Paid',
                            '\$${((delivery.pendingCrate!['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],

                  verticalSpacer(height: 16),

                  // Price Summary Card
                  _buildSectionCard(
                    title: 'Price Summary',
                    icon: Icons.attach_money,
                    child: Column(
                      children: [
                        _buildPriceRow(
                          'Subtotal',
                          '\$${delivery.subtotal?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        if ((delivery.waterTestDiscount ?? 0) > 0) ...[
                          _buildPriceRow(
                            'Water test credit',
                            '− \$${delivery.waterTestDiscount!.toStringAsFixed(2)}',
                          ),
                          _buildPriceRow(
                            'Subtotal after credit',
                            '\$${((delivery.subtotal ?? 0) - delivery.waterTestDiscount!).toStringAsFixed(2)}',
                          ),
                        ],
                        _buildPriceRow(
                          'Delivery Charges',
                          '\$${delivery.deliveryCharges?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        _buildPriceRow(
                          'HST (13%)',
                          '\$${delivery.hst?.toStringAsFixed(2) ?? '0.00'}',
                        ),
                        Divider(height: 16.h),
                        _buildPriceRow(
                          'Total',
                          delivery.formattedTotal,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  // Customer Note
                  if (delivery.customerNote != null &&
                      delivery.customerNote!.isNotEmpty) ...[
                    verticalSpacer(height: 16),
                    _buildSectionCard(
                      title: 'Customer Note',
                      icon: Icons.note,
                      child: customText(
                        text: delivery.customerNote!,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: AppColors.primary.withOpacity(0.8),
                      ),
                    ),
                  ],

                  // Driver Notes Input (only for active orders)
                  if (isOnMyWay) ...[
                    verticalSpacer(height: 16),
                    _buildSectionCard(
                      title: 'Driver Notes (Optional)',
                      icon: Icons.edit_note,
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add notes about the delivery...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.all(12.w),
                        ),
                      ),
                    ),
                  ],

                  // Delivery Proof Image (for active orders)
                  if (isOnMyWay) ...[
                    verticalSpacer(height: 16),
                    _buildSectionCard(
                      title: 'Delivery Proof Image (Required for Delivery)',
                      icon: Icons.camera_alt,
                      child: Column(
                        children: [
                          if (_proofImage != null)
                            Container(
                              height: 200.h,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                image: DecorationImage(
                                  image: FileImage(_proofImage!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          verticalSpacer(height: 12),
                          customButton(
                            text: _proofImage != null
                                ? 'Change Image'
                                : 'Select Image',
                            onPressed: _showImagePickerDialog,
                            context: context,
                            fontSize: 16,
                            height: 48,
                            borderColor: AppColors.primary,
                            bgColor: AppColors.primary,
                            fontColor: AppColors.white,
                            borderRadius: 16,
                            isCircular: false,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    ),
                  ],

                  verticalSpacer(height: 24),

                  // Action Buttons
                  if (!isDelivered) ...[
                    if (isPending)
                      customButton(
                        context: context,
                        text: 'On My Way',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.white,
                        bgColor: AppColors.btnColor,
                        borderColor: Colors.transparent,
                        borderRadius: 12,
                        height: 52,
                        width: double.infinity,
                        isCircular: false,
                        isLoading: _isUpdating,
                        onPressed: () => _updateStatus('On My Way'),
                      ),
                   
                    if (isOnMyWay && delivery.products != null &&
                        delivery.products!.any((p) =>
                            (p.productId?.name ?? '').toLowerCase().contains('water test'))) ...[
                      customButton(
                        context: context,
                        text: 'Water Test First',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.white,
                        bgColor: AppColors.primary,
                        borderColor: Colors.transparent,
                        borderRadius: 12,
                        height: 52,
                        width: double.infinity,
                        isCircular: false,
                        onPressed: () {
                          goRouter.push(AppRoutes.driverWaterTest,
                              extra: delivery);
                        },
                      ),
                      verticalSpacer(height: 12),
                    ],
                    if (isOnMyWay) ...[
                      customButton(
                        context: context,
                        text: 'Mark as Delivered',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontColor: AppColors.btnColor,
                        bgColor: Colors.white,
                        borderColor: AppColors.btnColor,
                        borderRadius: 12,
                        height: 52,
                        width: double.infinity,
                        isCircular: false,
                        isLoading: _isUpdating,
                        onPressed: () => _updateStatus('Delivered'),
                      ),
                    ],
                  ],

                  if (isDelivered && delivery.deliveredAt != null) ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 48.sp,
                          ),
                          verticalSpacer(height: 8),
                          customText(
                            text: 'Delivered Successfully',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          verticalSpacer(height: 4),
                          customText(
                            text: DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(delivery.deliveredAt!),
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: AppColors.primary.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],

                  verticalSpacer(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20.sp),
                horizontalSpacer(width: 8),
                customText(
                  text: title,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(12.w), child: child),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16.sp),
          ),
          horizontalSpacer(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  text: label,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: AppColors.primary.withOpacity(0.75),
                ),
                customText(
                  text: value,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              CustomToast.success(msg: '$label copied');
            },
            child: Icon(Icons.copy, size: 16.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(DeliveryProduct product) {
    final imageUrl = product.productId?.firstImageUrl;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Container(
              width: 44.w,
              height: 44.w,
              color: AppColors.bgColor,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2,
                        color: AppColors.primary,
                        size: 20.sp,
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Icon(
                      Icons.inventory_2,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
            ),
          ),
          horizontalSpacer(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  text: product.productId?.name ?? 'Unknown Product',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                customText(
                  text: 'Qty: ${product.quantity ?? 1}',
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: AppColors.primary.withOpacity(0.75),
                ),
              ],
            ),
          ),
          customText(
            text: '\$${product.productId?.price?.toStringAsFixed(2) ?? '0.00'}',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          customText(
            text: label,
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : AppColors.primary.withOpacity(0.75),
          ),
          customText(
            text: value,
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppColors.primary : Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAndWaterSection(DriverDelivery delivery) {
    final safety = delivery.userId?.deliverySafety;
    final water = delivery.userId?.waterSetup;
    final onboarding = delivery.userId?.onboardingData;

    final setupCards = <Widget>[];

    if (safety != null) {
      setupCards.add(
        _buildSetupGroupCard(
          title: 'Delivery Safety',
          icon: Icons.shield_outlined,
          children: [
            _buildCompactInfoRow('Address Label', safety.addressLabel),
            _buildCompactInfoRow(
              'Backyard Access',
              _formatEnumValue(safety.backyardAccess),
            ),
            _buildCompactInfoRow(
              'Backyard Permission',
              safety.backyardPermission ? 'Yes' : 'No',
            ),
            _buildCompactInfoRow(
              'Contact Preference',
              _formatEnumValue(safety.contactPreference),
            ),
            _buildCompactInfoRow(
              'Has Dogs',
              safety.dogSafety.hasDogs ? 'Yes' : 'No',
            ),
            if (safety.dogSafety.hasDogs)
              _buildCompactInfoRow(
                'Dogs Contained',
                _formatEnumValue(safety.dogSafety.dogsContained),
              ),
            if (safety.dogSafety.hasDogs)
              _buildCompactInfoRow('Dog Notes', safety.dogSafety.dogNotes),
            if (safety.dogSafety.hasDogs)
              _buildCompactInfoRow(
                'Pets Secured Confirmed',
                safety.dogSafety.petsSecuredConfirm ? 'Yes' : 'No',
              ),
            _buildCompactInfoRow(
              'Gate Access Method',
              _formatEnumValue(safety.gateEntry.accessMethod),
            ),
            _buildCompactInfoRow(
              'Gate Location',
              _formatEnumValue(safety.gateEntry.gateLocation),
            ),
            _buildCompactInfoRow('Gate Code', safety.gateEntry.gateCode),
          ],
        ),
      );

      final hasLooseDogs =
          safety.dogSafety.hasDogs && safety.dogSafety.dogsContained == 'no';
      final noBackyardAccess = safety.backyardAccess == 'no';

      if (hasLooseDogs || noBackyardAccess) {
        setupCards.add(
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(
              color: AppColors.btnColor.withOpacity(0.1),
              border: Border.all(color: AppColors.btnColor.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.btnColor,
                  size: 18.sp,
                ),
                horizontalSpacer(width: 8),
                Expanded(
                  child: customText(
                    text: hasLooseDogs
                        ? 'Loose dog reported: delivery may need front-door drop-off.'
                        : 'No backyard access: water test may not be possible at this stop.',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.btnColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (water != null) {
      final waterRows = <Widget>[
        _buildCompactInfoRow('Water Type', _formatEnumValue(water.waterType)),
      ];

      if (water.waterType == 'pool' || water.waterType == 'both') {
        waterRows.addAll([
          _buildCompactInfoRow(
            'Pool Volume Method',
            water.pool.volumeMethod == 'notSure'
                ? 'Not Sure — needs calculation on visit'
                : _formatEnumValue(water.pool.volumeMethod),
          ),
          _buildCompactInfoRow('Pool Shape', _formatEnumValue(water.pool.shape)),
          if (water.pool.length > 0)
            _buildCompactInfoRow('Length', '${_formatFeetValue(water.pool.length)} ft'),
          if (water.pool.width > 0)
            _buildCompactInfoRow('Width', '${_formatFeetValue(water.pool.width)} ft'),
          if (water.pool.avgDepth > 0)
            _buildCompactInfoRow('Avg Depth', '${_formatFeetValue(water.pool.avgDepth)} ft'),
          if (water.pool.estimatedVolume > 0)
            _buildCompactInfoRow(
              'Pool Estimated Volume',
              '${water.pool.estimatedVolume} ${water.pool.volumeUnit.isNotEmpty ? water.pool.volumeUnit : 'gallons'}',
            ),
          _buildCompactInfoRow(
            'Pool Sanitizer',
            _formatEnumValue(water.pool.sanitizerSystem),
          ),
        ]);
      }

      if (water.waterType == 'hotTub' || water.waterType == 'both') {
        waterRows.addAll([
          _buildCompactInfoRow('Hot Tub Volume',
              water.hotTub.volume == 'notSure'
                  ? 'Not Sure — needs calculation on visit'
                  : water.hotTub.volume),
          _buildCompactInfoRow('Hot Tub Custom Volume', water.hotTub.customVolume),
          _buildCompactInfoRow(
            'Hot Tub Sanitizer',
            _formatEnumValue(water.hotTub.sanitizerSystem),
          ),
          _buildCompactInfoRow('Hot Tub Usage', _formatEnumValue(water.hotTub.usage)),
        ]);
      }

      setupCards.add(
        _buildSetupGroupCard(
          title: 'Water Setup',
          icon: Icons.water_drop_outlined,
          children: waterRows,
        ),
      );
    }

    if (onboarding != null) {
      setupCards.add(
        _buildSetupGroupCard(
          title: 'Onboarding Preferences',
          icon: Icons.tune,
          children: [
            // _buildCompactInfoRow(
            //   'Add Water Test',
            //   onboarding.addWaterTest ? 'Yes' : 'No',
            // ),
            // _buildCompactInfoRow('Testing Type', _formatEnumValue(onboarding.testingType)),
            _buildCompactInfoRow(
              'Preferred Stop Type',
              _formatEnumValue(onboarding.preferredStopType),
            ),
            if (onboarding.selectedDeliveryDate != null)
              _buildCompactInfoRow(
                'Selected Delivery Date',
                DateFormat('MMM dd, yyyy').format(onboarding.selectedDeliveryDate!),
              ),
          ],
        ),
      );
    }

    if (setupCards.isEmpty) {
      return customText(
        text: 'No delivery safety or water setup data available.',
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.primary.withOpacity(0.8),
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 10.w),
      childrenPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      backgroundColor: AppColors.cardBgColor,
      collapsedBackgroundColor: AppColors.cardBgColor,
      title: customText(
        text: 'Tap to view customer setup details',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      subtitle: customText(
        text: 'Safety notes, gate access, water setup, and preferences',
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.primary.withOpacity(0.75),
      ),
      children: setupCards,
    );
  }

  Widget _buildSetupGroupCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final visibleChildren = children.where((w) => w is! SizedBox).toList();
    if (visibleChildren.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.sp, color: AppColors.primary),
              horizontalSpacer(width: 6),
              customText(
                text: title,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ],
          ),
          verticalSpacer(height: 8),
          ...visibleChildren,
        ],
      ),
    );
  }

  Widget _buildCompactInfoRow(String label, String? value, {Color? highlightColor}) {
    final cleaned = value?.trim() ?? '';
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final bgColor = highlightColor?.withOpacity(0.15) ?? AppColors.primary.withOpacity(0.08);
    final labelColor = highlightColor?.withOpacity(0.85) ?? AppColors.primary.withOpacity(0.75);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            customText(
              text: label,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
            verticalSpacer(height: 4),
            customText(
              text: cleaned,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  String _formatEnumValue(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '';
    return v
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase() + e.substring(1))
        .join(' ');
  }

  String _formatFeetValue(double value) {
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppColors.btnColor;
      case 'on my way':
        return AppColors.primary;
      case 'delivered':
        return AppColors.primary;
      default:
        return AppColors.primary.withOpacity(0.7);
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'onmyway':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }
}
