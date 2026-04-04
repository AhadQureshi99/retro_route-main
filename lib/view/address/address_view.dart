import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/shimmer_loading.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:retro_route/config/delivery_zones.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/address/add_address_view.dart';
import 'package:retro_route/view_model/address_view_model/address_view_model.dart';
import 'package:retro_route/view_model/address_view_model/selected_delivery_address_view_model.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';

class AddressesScreen extends ConsumerStatefulWidget {
  const AddressesScreen({super.key});

  @override
  ConsumerState<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends ConsumerState<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).value?.data;
    final address = ref.read(addressProvider);
    if (user?.token != null) {
      if (address.addresses.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(addressProvider.notifier).fetchAddresses(user!.token);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressProvider);
    final token = ref.watch(authNotifierProvider).value?.data?.token;
    final selectedAddress = ref.watch(selectedDeliveryAddressProvider);

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text(
          "My Addresses",
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: TextButton.icon(
              onPressed: () => _pushAddAddress(context),
              icon: Icon(Icons.add, size: 18.sp, color: AppColors.btnColor),
              label: Text(
                "Add Address",
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.btnColor,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAddresses(token),
        color: AppColors.primary,
        backgroundColor: Colors.white,
        displacement: 40.h,
        strokeWidth: 3,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w,
                  32.h + MediaQuery.of(context).padding.bottom),
              sliver: state.isLoading
                  ? SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: const ShimmerAddressCard(),
                        ),
                        childCount: 5,
                      ),
                    )
                  : state.error != null
                      ? SliverFillRemaining(
                          child: _buildErrorState(context, ref, token, state.error!),
                        )
                      : state.addresses.isEmpty
                          ? SliverFillRemaining(child: _buildEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, index) {
                                  final addr = state.addresses[index];
                                  final isSelected =
                                      selectedAddress?.safeId == addr.safeId;
                                  final zone = detectZoneByCity(addr.safeCity);
                                  final nextDate = zone != null
                                      ? getNextDeliveryDateFromDays(zone.deliveryDays)
                                      : null;
                                  final secondDate = nextDate != null
                                      ? nextDate.add(const Duration(days: 7))
                                      : null;

                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _AddressCard(
                                      addr: addr,
                                      isSelected: isSelected,
                                      zone: zone,
                                      nextDate: nextDate,
                                      secondDate: secondDate,
                                      onTap: () => ref
                                          .read(selectedDeliveryAddressProvider
                                              .notifier)
                                          .selectAddress(addr),
                                      onEdit: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddAddressScreen(
                                              addressToEdit: addr),
                                        ),
                                      ),
                                      onDelete: () async {
                                        final ok = await _showDeleteConfirmation(
                                            context);
                                        if (ok && token != null) {
                                          final success = await ref
                                              .read(addressProvider.notifier)
                                              .deleteAddress(
                                                token: token,
                                                addressId: addr.safeId,
                                              );
                                          if (success && context.mounted) {
                                            CustomToast.success(
                                                msg: "Address deleted");
                                          }
                                        }
                                      },
                                    ),
                                  );
                                },
                                childCount: state.addresses.length,
                              ),
                            ),
            ),
          ],
        ),
      ),

      // ── Bottom confirm button ─────────────────────────────────────────
      bottomNavigationBar: state.addresses.isNotEmpty && !state.isLoading
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                16.w,
                12.h,
                16.w,
                12.h + MediaQuery.of(context).padding.bottom,
              ),
              child: customButton(
                context: context,
                text: selectedAddress == null
                    ? "Select an Address"
                    : "Confirm & Use This Address",
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontColor: Colors.white,
                bgColor: selectedAddress == null
                    ? Colors.grey[400]!
                    : AppColors.btnColor,
                borderRadius: 14.r,
                height: 54,
                width: double.infinity,
                onPressed: selectedAddress == null
                    ? null
                    : () => Navigator.pop(context),
                borderColor: selectedAddress == null
                    ? Colors.grey[400]!
                    : AppColors.btnColor,
                isCircular: false,
              ),
            )
          : null,
    );
  }

  void _pushAddAddress(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    ).then((_) {
      final addresses = ref.read(addressProvider).addresses;
      if (addresses.isNotEmpty) {
        final current = ref.read(selectedDeliveryAddressProvider);
        if (current == null ||
            !addresses.any((a) => a.safeId == current.safeId)) {
          ref
              .read(selectedDeliveryAddressProvider.notifier)
              .selectAddress(addresses.first);
        }
      }
    });
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String? token, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56.sp, color: Colors.red[300]),
            verticalSpacer(height: 16.h),
            Text("Failed to load addresses",
                style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800)),
            verticalSpacer(height: 8.h),
            Text(error,
                style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.grey),
                textAlign: TextAlign.center),
            verticalSpacer(height: 20.h),
            if (token != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Retry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                ),
                onPressed: () =>
                    ref.read(addressProvider.notifier).fetchAddresses(token),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: AppColors.btnColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on_outlined,
                  size: 44.sp, color: AppColors.btnColor),
            ),
            verticalSpacer(height: 20.h),
            Text("No addresses saved",
                style: GoogleFonts.inter(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800)),
            verticalSpacer(height: 8.h),
            Text("Add an address for faster checkout",
                style: GoogleFonts.inter(
                    fontSize: 16.sp, color: Colors.grey.shade700),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAddresses(String? token) async {
    if (token == null || token.isEmpty) return;
    await ref.read(addressProvider.notifier).fetchAddresses(token);
    if (mounted) CustomToast.success(msg: "Addresses refreshed");
  }

  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text("Delete Address?",
                style: GoogleFonts.inter(
                    fontSize: 20.sp, fontWeight: FontWeight.w800)),
            content: Text("This action cannot be undone.",
                style: GoogleFonts.inter(
                    fontSize: 16.sp, color: Colors.grey.shade800,fontWeight: FontWeight.w500)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text("Cancel",
                    style: TextStyle(color: Colors.grey[900])),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete",
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}

// ── Address Card ────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  final dynamic addr;
  final bool isSelected;
  final DeliveryZone? zone;
  final DateTime? nextDate;
  final DateTime? secondDate;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressCard({
    required this.addr,
    required this.isSelected,
    required this.zone,
    required this.nextDate,
    required this.secondDate,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBgColor,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.btnColor : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.btnColor.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pin icon ──
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 22.sp,
                  color: isSelected
                      ? AppColors.btnColor
                      : Colors.grey.shade400,
                ),
              ),
              SizedBox(width: 12.w),

              // ── Details ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (addr.safeFullName.isNotEmpty)
                      Text(
                        addr.safeFullName,
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                    SizedBox(height: 2.h),
                    Text(
                      addr.displayAddress,
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, color: Colors.grey.shade900),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    // Text(
                    //   _locationLine(),
                    //   style: GoogleFonts.inter(
                    //       fontSize: 14.sp, color: Colors.grey.shade900),
                    // ),
                    if (addr.safeMobile.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        '📞 ${addr.safeMobile}',
                        style: GoogleFonts.inter(
                            fontSize: 14.sp, color: Colors.grey.shade900),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    zone != null ? _zoneBadge() : _noZoneWarning(),
                  ],
                ),
              ),

              SizedBox(width: 4.w),

              // ── Edit / Delete buttons ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _iconBtn(
                    icon: Icons.edit_outlined,
                    color: AppColors.btnColor,
                    onTap: onEdit,
                  ),
                  SizedBox(height: 4.h),
                  _iconBtn(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.btnColor,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _locationLine() {
    final parts = <String>[];
    if ((addr.safeCity as String).isNotEmpty) parts.add(addr.safeCity as String);
    if ((addr.state as String? ?? '').isNotEmpty) parts.add(addr.state as String);
    if ((addr.pinCode as String? ?? '').isNotEmpty) parts.add(addr.pinCode as String);
    if ((addr.country as String? ?? '').isNotEmpty) parts.add(addr.country as String);
    return parts.join(', ');
  }

  Widget _zoneBadge() {
    final color = zone!.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping_rounded, size: 13.sp, color: color),
              SizedBox(width: 5.w),
              Flexible(
                child: Text(
                  zone!.name,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          if (nextDate != null) ...[
            SizedBox(height: 4.h),
            RichText(
              text: TextSpan(
                style:
                    GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade900),
                children: [
                  const TextSpan(text: 'Delivery day: '),
                  TextSpan(
                    text: formatDeliveryDate(nextDate!),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
          if (secondDate != null) ...[
            SizedBox(height: 2.h),
            Text(
              'Next: ${formatDeliveryDate(secondDate!)}',
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey.shade900),
            ),
          ],
        ],
      ),
    );
  }

  Widget _noZoneWarning() {
    return Row(
      children: [
        Icon(Icons.warning_amber_rounded,
            size: 14.sp, color: Colors.amber[700]),
        SizedBox(width: 4.w),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: GoogleFonts.inter(
                  fontSize: 12.sp, color: Colors.amber[700]),
              children: [
                const TextSpan(text: "Your city is not in the delivery zone. We are working on it, but for now, please visit "),
                TextSpan(
                  text: "www.retrorouteco.com",
                  style: const TextStyle(
                    color: Color(0xFFE8751A),
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()..onTap = () {
                    launchUrl(Uri.parse('https://www.retrorouteco.com/?from=app'), mode: LaunchMode.externalApplication);
                  },
                ),
                const TextSpan(text: " to place an order, and we will ship it to you."),
              ],
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Icon(icon, size: 22.sp, color: color),
      ),
    );
  }
}
