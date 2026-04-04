import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view/profile/widgets/delivery_safety_form.dart';
import 'package:retro_route/view/profile/widgets/water_setup_form.dart';
import 'package:retro_route/view_model/auth_view_model/login_view_model.dart';
import 'package:retro_route/view_model/setup_profile_view_model/setup_profile_view_model.dart';

// ── Label maps ──────────────────────────────────────────────────────────────
const _backyardLabels = {
  'yes': 'Yes — backyard drop-off',
  'no': 'No — front door only',
  'onlyIfHome': "Only if I'm home",
};
const _gateAccessLabels = {
  'noGate': 'No gate (open access)',
  'unlocked': 'Gate is unlocked',
  'codeLock': 'Gate has a code/lock',
};
const _gateLocationLabels = {
  'left': 'Left side',
  'right': 'Right side',
  'back': 'Back',
  'other': 'Other',
};
const _contactLabels = {
  'emailNotification': 'Email/App notification',
  'textMe': 'Text me',
  'callMe': 'Call me',
  'onlyIfNecessary': 'Only if necessary',
};
const _waterTypeLabels = {
  'pool': 'Pool',
  'hotTub': 'Hot tub',
  'both': 'Pool + Hot tub',
  'notRightNow': 'Not set up yet',
};
const _sanitizerLabels = {
  'chlorine': 'Chlorine',
  'saltwater': 'Saltwater (SWG)',
  'bromine': 'Bromine',
  'notSure': 'Not sure',
  'mineral': 'Mineral + sanitizer',
  'addOther': 'Other',
};
const _usageLabels = {
  'daily': 'Daily',
  'weekly': 'Weekly',
  'occasional': 'Occasional',
};
const _coverLockLabels = {
  'noLock': 'No lock',
  'yesUnlocked': 'Yes — unlocked',
  'yesLocked': 'Yes — stays locked',
};
const _shapeLabels = {
  'rectangle': 'Rectangle',
  'round': 'Round',
  'oval': 'Oval',
};

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  // Edit flags
  bool _editingDelivery = false;
  bool _editingWater = false;
  bool _savingSetup = false;

  // Expandable sections
  bool _deliveryOpen = true;
  bool _waterOpen = true;

  // Editable copies
  DeliverySafety? _deliveryForm;
  WaterSetup? _waterForm;

  // ── Start editing delivery ──
  void _startEditDelivery(SetupProfileData? setup) {
    final ds = setup?.deliverySafety;
    _deliveryForm =
        ds != null ? DeliverySafety.fromJson(ds.toJson()) : DeliverySafety();
    setState(() => _editingDelivery = true);
  }

  // ── Save delivery ──
  Future<void> _saveDelivery() async {
    if (_deliveryForm == null) return;
    setState(() => _savingSetup = true);
    final success = await ref
        .read(setupProfileProvider.notifier)
        .saveDelivery(_deliveryForm!);
    if (success) {
      CustomToast.success(msg: "Delivery & safety updated!");
      setState(() => _editingDelivery = false);
    } else {
      CustomToast.error(msg: "Failed to save");
    }
    setState(() => _savingSetup = false);
  }

  // ── Start editing water ──
  void _startEditWater(SetupProfileData? setup) {
    final ws = setup?.waterSetup;
    _waterForm =
        ws != null ? WaterSetup.fromJson(ws.toJson()) : WaterSetup();
    setState(() => _editingWater = true);
  }

  // ── Save water ──
  Future<void> _saveWater() async {
    if (_waterForm == null) return;
    setState(() => _savingSetup = true);
    final success =
        await ref.read(setupProfileProvider.notifier).saveWater(_waterForm!);
    if (success) {
      CustomToast.success(msg: "Water setup updated!");
      setState(() => _editingWater = false);
    } else {
      CustomToast.error(msg: "Failed to save");
    }
    setState(() => _savingSetup = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider).value;
    final setupAsync = ref.watch(setupProfileProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: customText(
          text: "My Profile",
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: -0.5, end: 0),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Profile header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 32.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30.r),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45.r,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50.sp,
                      color: AppColors.primary,
                    ),
                  )
                      .animate()
                      .scale(
                          begin: Offset(0.6, 0.6),
                          end: Offset(1.0, 1.0),
                          curve: Curves.easeOutBack,
                          duration: 900.ms)
                      .fadeIn(delay: 300.ms),
                  verticalSpacer(height: 12),
                  customText(
                    text: user?.data?.user.name ?? '',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.3, end: 0),
                  verticalSpacer(height: 4),
                  customText(
                    text: user?.data?.user.email ?? '',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 800.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

            verticalSpacer(height: 20),

            // ── Edit Profile tile ──
            _profileTile(
              icon: Icons.edit_outlined,
              title: "Edit Profile",
              subtitle: "Update your name, email & photo",
              onTap: () => goRouter.push(AppRoutes.editProfle),
            ).animate().slideX(
                begin: -0.4,
                end: 0,
                delay: 300.ms,
                duration: 600.ms,
                curve: Curves.easeOutCubic),

            verticalSpacer(height: 6),

            // ── Delivery & Safety expandable card ──
            setupAsync.when(
              data: (setup) => _buildDeliveryCard(setup),
              loading: () => _loadingTile(),
              error: (_, __) => _buildDeliveryCard(null),
            ),

            // ── Water Setup expandable card ──
            setupAsync.when(
              data: (setup) => _buildWaterCard(setup),
              loading: () => _loadingTile(),
              error: (_, __) => _buildWaterCard(null),
            ),

            verticalSpacer(height: 40),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELIVERY & SAFETY CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeliveryCard(SetupProfileData? setup) {
    final ds = setup?.deliverySafety;
    // Check if delivery data actually exists rather than relying only on hasCompletedSetup
    final configured = ds != null && ds.address.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _deliveryOpen = !_deliveryOpen),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.shield_outlined,
                          size: 20.sp, color:  AppColors.primary),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          customText(
                            text: "Delivery & Safety",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            configured
                                ? ds.address
                                : "Not configured yet",
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: Colors.grey[400]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _deliveryOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_deliveryOpen) ...[
              Divider(height: 1, color: Colors.grey[100]),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: _editingDelivery
                    ? _deliveryEditMode()
                    : configured
                        ? _deliverySummary(ds)
                        : _emptySetupState(
                            icon: Icons.shield_outlined,
                            text: "No delivery info configured yet",
                            buttonText: "Set Up Now",
                            buttonColor:  AppColors.btnColor,
                            onTap: () => _startEditDelivery(setup),
                          ),
              ),
            ],
          ],
        ),
      ),
    ).animate().slideX(
        begin: -0.4,
        end: 0,
        delay: 400.ms,
        duration: 600.ms,
        curve: Curves.easeOutCubic);
  }

  Widget _deliveryEditMode() {
    return Column(
      children: [
        DeliverySafetyForm(
          data: _deliveryForm!,
          onChange: (v) => setState(() => _deliveryForm = v),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _savingSetup ? null : _saveDelivery,
                icon: _savingSetup
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.save, size: 16.sp),
                label: Text(
                  _savingSetup ? "Saving..." : "Save Changes",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:  AppColors.btnColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            OutlinedButton(
              onPressed: () => setState(() => _editingDelivery = false),
              style: OutlinedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text("Cancel",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _deliverySummary(DeliverySafety ds) {
    return Column(
      children: [
        _infoRow("Address", ds.address),
        _infoRow("Label", ds.addressLabel),
        _infoRow("Drop-off spot", ds.dropOffSpot),
        if (ds.dropOffDetails.isNotEmpty)
          _infoRow("Drop-off details", ds.dropOffDetails),
        _infoRow("Backyard access", _backyardLabels[ds.backyardAccess]),
        if (ds.backyardAccess == 'yes')
          _infoRow(
              "Backyard permission", ds.backyardPermission ? "Yes" : "No"),
        _infoRow("Dogs in yard", ds.dogSafety.hasDogs ? "Yes" : "No"),
        if (ds.dogSafety.hasDogs) ...[
          _infoRow(
            "Dogs contained",
            ds.dogSafety.dogsContained == 'yes'
                ? "Yes (guaranteed)"
                : ds.dogSafety.dogsContained == 'no'
                    ? "No"
                    : "Not sure",
          ),
          if (ds.dogSafety.dogNotes.isNotEmpty)
            _infoRow("Dog notes", ds.dogSafety.dogNotes),
        ],
        if (ds.backyardAccess == 'yes') ...[
          _infoRow(
              "Gate access", _gateAccessLabels[ds.gateEntry.accessMethod]),
          _infoRow("Gate location",
              _gateLocationLabels[ds.gateEntry.gateLocation]),
          if (ds.gateEntry.gateCode.isNotEmpty)
            _infoRow("Gate code", ds.gateEntry.gateCode),
        ],
        _infoRow("Contact preference", _contactLabels[ds.contactPreference]),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () =>
              _startEditDelivery(ref.read(setupProfileProvider).value),
          child: Row(
            children: [
              Icon(Icons.edit, size: 15.sp, color: AppColors.btnColor),
              SizedBox(width: 6.w),
              Text("Edit Delivery & Safety",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.btnColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WATER SETUP CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWaterCard(SetupProfileData? setup) {
    final ws = setup?.waterSetup;
    // Check if water data actually exists rather than relying only on hasCompletedSetup
    final hasWater = ws != null &&
        ws.waterType.isNotEmpty &&
        ws.waterType != 'notRightNow';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _waterOpen = !_waterOpen),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color:  AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.water_drop_outlined,
                          size: 20.sp, color: AppColors.primary),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          customText(
                            text: "Water Setup",
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            hasWater
                                ? (_waterTypeLabels[ws.waterType] ??
                                    'Not configured yet')
                                : "Not configured yet",
                            style: GoogleFonts.inter(
                                fontSize: 14.sp, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _waterOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 24.sp,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            if (_waterOpen) ...[
              Divider(height: 1, color: Colors.grey[100]),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: _editingWater
                    ? _waterEditMode()
                    : hasWater
                        ? _waterSummary(ws)
                        : _emptySetupState(
                            icon: Icons.water_drop_outlined,
                            text: "No water setup configured yet",
                            buttonText: "Set Up Now",
                            buttonColor: AppColors.btnColor,
                            onTap: () => _startEditWater(setup),
                          ),
              ),
            ],
          ],
        ),
      ),
    ).animate().slideX(
        begin: -0.4,
        end: 0,
        delay: 500.ms,
        duration: 600.ms,
        curve: Curves.easeOutCubic);
  }

  Widget _waterEditMode() {
    return Column(
      children: [
        WaterSetupForm(
          data: _waterForm!,
          onChange: (v) => setState(() => _waterForm = v),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _savingSetup ? null : _saveWater,
                icon: _savingSetup
                    ? SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.save, size: 16.sp),
                label: Text(
                  _savingSetup ? "Saving..." : "Save Changes",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.btnColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            OutlinedButton(
              onPressed: () => setState(() => _editingWater = false),
              style: OutlinedButton.styleFrom(
                padding:
                    EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Text("Cancel",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600])),
            ),
          ],
        ),
      ],
    );
  }

  Widget _waterSummary(WaterSetup ws) {
    return Column(
      children: [
        _infoRow("Water type", _waterTypeLabels[ws.waterType]),
        if (ws.waterType == 'pool' || ws.waterType == 'both') ...[
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("POOL",
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
          if (ws.pool.estimatedVolume > 0)
            _infoRow(
                "Volume", "${_formatNum(ws.pool.estimatedVolume)} gal"),
          if (ws.pool.shape.isNotEmpty)
            _infoRow("Shape", _shapeLabels[ws.pool.shape]),
          if (ws.pool.length > 0)
            _infoRow("Dimensions",
                "${ws.pool.length}${ws.pool.shape != 'round' && ws.pool.width > 0 ? ' × ${ws.pool.width}' : ''} × ${ws.pool.avgDepth} ft"),
          _infoRow("Sanitizer",
              ws.pool.sanitizerSystem == 'addOther' && ws.pool.customSanitizer.isNotEmpty
                  ? ws.pool.customSanitizer
                  : _sanitizerLabels[ws.pool.sanitizerSystem]),
          if (ws.pool.moreDetails.isNotEmpty)
            _infoRow("Details", ws.pool.moreDetails),
        ],
        if (ws.waterType == 'hotTub' || ws.waterType == 'both') ...[
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text("HOT TUB",
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary)),
          ),
          if (ws.hotTub.coverLock.isNotEmpty)
            _infoRow("Cover lock", _coverLockLabels[ws.hotTub.coverLock]),
          if (ws.hotTub.coverLock == 'yesLocked' && ws.hotTub.coverKeyLocation.isNotEmpty)
            _infoRow("Key location", ws.hotTub.coverKeyLocation),
          _infoRow(
            "Volume",
            ws.hotTub.customVolume.isNotEmpty
                ? ws.hotTub.customVolume
                : ws.hotTub.volume.isNotEmpty &&
                        ws.hotTub.volume != 'addOther'
                    ? "${ws.hotTub.volume} gal"
                    : null,
          ),
          _infoRow("Sanitizer",
              ws.hotTub.sanitizerSystem == 'addOther' && ws.hotTub.customSanitizer.isNotEmpty
                  ? ws.hotTub.customSanitizer
                  : _sanitizerLabels[ws.hotTub.sanitizerSystem]),
          _infoRow("Usage", _usageLabels[ws.hotTub.usage]),
          if (ws.hotTub.filterModel.isNotEmpty)
            _infoRow("Filter model", ws.hotTub.filterModel),
        ],
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: () =>
              _startEditWater(ref.read(setupProfileProvider).value),
          child: Row(
            children: [
              Icon(Icons.edit, size: 15.sp, color: AppColors.btnColor),
              SizedBox(width: 6.w),
              Text("Edit Water Setup",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.btnColor)),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _profileTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24.sp, color: iconColor ?? AppColors.primary),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    customText(
                      text: title,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor ?? Colors.black87,
                    ),
                    if (subtitle != null)
                      Text(subtitle,
                          style: GoogleFonts.inter(
                              fontSize: 14.sp, color: Colors.grey[400])),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16.sp, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: Colors.grey[500])),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900]),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _emptySetupState({
    required IconData icon,
    required String text,
    required String buttonText,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Icon(icon, size: 36.sp, color: Colors.grey[200]),
            SizedBox(height: 8.h),
            Text(text,
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: Colors.grey[400])),
            SizedBox(height: 12.h),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(buttonText,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingTile() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
      child: Container(
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
