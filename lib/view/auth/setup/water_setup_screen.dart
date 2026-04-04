import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_toast.dart';

const _waterTypes = [
  {'value': 'pool', 'label': 'Pool', 'desc': 'A swimming pool', 'icon': '🏊'},
  {'value': 'hotTub', 'label': 'Hot tub', 'desc': 'A spa / hot tub', 'icon': '♨️'},
  {'value': 'both', 'label': 'Both', 'desc': 'Pool + hot tub', 'icon': '💧'},
  {'value': 'notRightNow', 'label': 'Not right now', 'desc': 'Skip water details', 'icon': '—'},
];

const _poolShapes = ['Rectangle', 'Round', 'Oval'];
const _poolSanitizers = {'Chlorine': 'chlorine', 'Saltwater': 'saltwater', 'Bromine': 'bromine', 'Add Other': 'addOther', 'Not Sure': 'notSure'};
const _hotTubVolumesGal = {'300 gal': '300', '400 gal': '400', '500 gal': '500', 'Add Other': 'addOther', 'Not Sure': 'notSure'};
const _hotTubVolumesL = {'1136 L': '300', '1514 L': '400', '1893 L': '500', 'Add Other': 'addOther', 'Not Sure': 'notSure'};
const _hotTubSanitizers = {'Chlorine': 'chlorine', 'Bromine': 'bromine', 'Add Other': 'addOther', 'Not Sure': 'notSure'};
const _hotTubUsage = {'Daily': 'daily', 'Weekly': 'weekly', 'Occasional': 'occasional'};

class WaterSetupSection extends StatefulWidget {
  final WaterSetup data;
  final ValueChanged<WaterSetup> onChange;

  const WaterSetupSection({super.key, required this.data, required this.onChange});

  @override
  State<WaterSetupSection> createState() => WaterSetupSectionState();
}

class WaterSetupSectionState extends State<WaterSetupSection> {
  static const Color _primaryLight = Color(0xFFEAF2FE);
  static const Color _primaryBorder = Color(0xFFCFE0FB);
  static const Color _primaryDark = Color(0xFF2E6FC4);

  late TextEditingController _lengthCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _depthCtrl;
  late TextEditingController _knownVolCtrl;
  late TextEditingController _moreDetailsCtrl;
  late TextEditingController _customVolCtrl;
  late TextEditingController _filterCtrl;
  late TextEditingController _poolCustomVolumeTextCtrl;
  late TextEditingController _poolCustomSanitizerCtrl;
  late TextEditingController _hotTubCustomSanitizerCtrl;
  late TextEditingController _hotTubKeyLocationCtrl;
  late String _volumeUnit;

  @override
  void initState() {
    super.initState();
    final p = widget.data.pool;
    final h = widget.data.hotTub;
    _volumeUnit = p.volumeUnit.isEmpty ? 'gallons' : p.volumeUnit;
    _lengthCtrl = TextEditingController(text: p.length > 0 ? p.length.toString() : '');
    _widthCtrl = TextEditingController(text: p.width > 0 ? p.width.toString() : '');
    _depthCtrl = TextEditingController(text: p.avgDepth > 0 ? p.avgDepth.toString() : '');
    _knownVolCtrl = TextEditingController(text: p.estimatedVolume > 0 ? p.estimatedVolume.toString() : '');
    _moreDetailsCtrl = TextEditingController(text: p.moreDetails);
    _customVolCtrl = TextEditingController(text: h.customVolume);
    _filterCtrl = TextEditingController(text: h.filterModel);
    _poolCustomVolumeTextCtrl = TextEditingController(text: p.customVolumeText);
    _poolCustomSanitizerCtrl = TextEditingController(text: p.customSanitizer);
    _hotTubCustomSanitizerCtrl = TextEditingController(text: h.customSanitizer);
    _hotTubKeyLocationCtrl = TextEditingController(text: h.coverKeyLocation);
  }

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _depthCtrl.dispose();
    _knownVolCtrl.dispose();
    _moreDetailsCtrl.dispose();
    _customVolCtrl.dispose();
    _filterCtrl.dispose();
    _poolCustomVolumeTextCtrl.dispose();
    _poolCustomSanitizerCtrl.dispose();
    _hotTubCustomSanitizerCtrl.dispose();
    _hotTubKeyLocationCtrl.dispose();
    super.dispose();
  }

  void _update(WaterSetup Function(WaterSetup) updater) {
    widget.onChange(updater(widget.data));
  }

  void _updatePool(PoolSetup Function(PoolSetup) updater) {
    _update((s) => s.copyWith(pool: updater(s.pool)));
  }

  void _updateHotTub(HotTubSetup Function(HotTubSetup) updater) {
    _update((s) => s.copyWith(hotTub: updater(s.hotTub)));
  }

  int _galToL(int gal) => (gal * 3.785).round();
  int _lToGal(int l) => (l / 3.785).round();

  int _displayVolume(int galValue) {
    if (galValue <= 0) return 0;
    return _volumeUnit == 'liters' ? _galToL(galValue) : galValue;
  }

  String get _unitLabel => _volumeUnit == 'liters' ? 'L' : 'gal';

  int _calcEstimatedVolume() {
    final p = widget.data.pool;
    if (p.shape.isEmpty || p.length <= 0 || p.avgDepth <= 0) return 0;
    double vol = 0;
    if (p.shape == 'rectangle' && p.width > 0) {
      vol = p.length * p.width * p.avgDepth * 7.48;
    } else if (p.shape == 'round') {
      vol = pi * pow(p.length / 2, 2) * p.avgDepth * 7.48;
    } else if (p.shape == 'oval' && p.width > 0) {
      vol = pi * (p.length / 2) * (p.width / 2) * p.avgDepth * 7.48;
    }
    return (vol / 1000).round() * 1000;
  }

  bool validateSelection() {
    final d = widget.data;
    final showPool = d.waterType == 'pool' || d.waterType == 'both';
    final showHotTub = d.waterType == 'hotTub' || d.waterType == 'both';

    if (d.waterType.isEmpty) {
      CustomToast.error(msg: 'Please select what water system you have.');
      return false;
    }

    if (d.waterType == 'notRightNow') {
      return true;
    }

    if (showPool) {
      final p = d.pool;
      if (p.volumeMethod.isEmpty) {
        CustomToast.error(msg: 'Please select a pool volume method.');
        return false;
      }

      if (p.volumeMethod == 'knowIt' && p.estimatedVolume <= 0) {
        CustomToast.error(msg: 'Please enter your known pool volume.');
        return false;
      }

      if (p.volumeMethod == 'helpEstimate') {
        if (p.shape.isEmpty) {
          CustomToast.error(msg: 'Please select your pool shape.');
          return false;
        }
        if (p.length <= 0) {
          CustomToast.error(msg: 'Please enter pool length.');
          return false;
        }
        if ((p.shape == 'rectangle' || p.shape == 'oval') && p.width <= 0) {
          CustomToast.error(msg: 'Please enter pool width.');
          return false;
        }
        if (p.avgDepth <= 0) {
          CustomToast.error(msg: 'Please enter average depth.');
          return false;
        }
      }

      if (p.volumeMethod == 'addOther' && p.customVolumeText.trim().isEmpty) {
        CustomToast.error(msg: 'Please enter your pool volume.');
        return false;
      }

      if (p.sanitizerSystem.isEmpty) {
        CustomToast.error(msg: 'Please select a pool sanitizer system.');
        return false;
      }
      if (p.sanitizerSystem == 'addOther' && p.customSanitizer.trim().isEmpty) {
        CustomToast.error(msg: 'Please enter your pool sanitizer system.');
        return false;
      }
    }

    if (showHotTub) {
      final h = d.hotTub;
      if (h.coverLock.isEmpty) {
        CustomToast.error(msg: 'Please select hot tub cover lock status.');
        return false;
      }
      if (h.coverLock == 'yesLocked' && h.coverKeyLocation.trim().isEmpty) {
        CustomToast.error(msg: 'Please tell us how to unlock hot tub cover.');
        return false;
      }
      if (h.volume.isEmpty) {
        CustomToast.error(msg: 'Please select hot tub volume.');
        return false;
      }
      if (h.volume == 'addOther' && h.customVolume.trim().isEmpty) {
        CustomToast.error(msg: 'Please enter your hot tub volume.');
        return false;
      }
      if (h.sanitizerSystem.isEmpty) {
        CustomToast.error(msg: 'Please select a hot tub sanitizer system.');
        return false;
      }
      if (h.sanitizerSystem == 'addOther' && h.customSanitizer.trim().isEmpty) {
        CustomToast.error(msg: 'Please enter your hot tub sanitizer system.');
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final showPool = d.waterType == 'pool' || d.waterType == 'both';
    final showHotTub = d.waterType == 'hotTub' || d.waterType == 'both';

    return Column(
      children: [
        // ── Header ───────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary]),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 5.h,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(4.r)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 1.0,
                        child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4.r))),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: () => _update((s) => s.copyWith(waterType: 'notRightNow')),
                    child: Text("Skip", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white70)),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text("Your water setup", style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w700, color: Colors.white)),
              SizedBox(height: 4.h),
              Text("This helps us dose correctly and build better recommendations. You can update it anytime.", style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFDCEAFE))),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // ── What do you have ─────────────────────────
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("What do you have at this address?"),
              Text("Pick one — you can add more later.", style: _caption),
              SizedBox(height: 10.h),
              _waterTypeGrid(d),
            ],
          ),
        ),

        // ── Pool details ─────────────────────────────
        if (showPool) ...[
          SizedBox(height: 14.h),
          _card(
            bgColor: const Color(0xFFF0F6FF),
            borderColor: Colors.blue.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Pool details"),
                Text("Used for accurate dosing and clear recommendations.", style: _caption),
                SizedBox(height: 10.h),
                Text("Pool volume", style: _label),
                SizedBox(height: 8.h),

                // Unit toggle
                Row(
                  children: [
                    Text("Unit:", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                    SizedBox(width: 8.w),
                    _pillButton("Gallons", selected: _volumeUnit == 'gallons', onTap: () {
                      setState(() => _volumeUnit = 'gallons');
                      _updatePool((p) => p.copyWith(volumeUnit: 'gallons'));
                      if (widget.data.pool.estimatedVolume > 0) {
                        _knownVolCtrl.text = widget.data.pool.estimatedVolume.toString();
                      }
                    }),
                    SizedBox(width: 6.w),
                    _pillButton("Liters", selected: _volumeUnit == 'liters', onTap: () {
                      setState(() => _volumeUnit = 'liters');
                      _updatePool((p) => p.copyWith(volumeUnit: 'liters'));
                      if (widget.data.pool.estimatedVolume > 0) {
                        _knownVolCtrl.text = _galToL(widget.data.pool.estimatedVolume).toString();
                      }
                    }),
                  ],
                ),
                SizedBox(height: 10.h),

                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _pillButton("I know it", selected: d.pool.volumeMethod == 'knowIt', onTap: () => _updatePool((p) => p.copyWith(volumeMethod: 'knowIt'))),
                    _pillButton("Help me estimate", selected: d.pool.volumeMethod == 'helpEstimate', onTap: () => _updatePool((p) => p.copyWith(volumeMethod: 'helpEstimate'))),
                    _pillButton("Add Other", selected: d.pool.volumeMethod == 'addOther', onTap: () => _updatePool((p) => p.copyWith(volumeMethod: 'addOther'))),
                    _pillButton("Not Sure", selected: d.pool.volumeMethod == 'notSure', onTap: () => _updatePool((p) => p.copyWith(volumeMethod: 'notSure'))),
                  ],
                ),

                if (d.pool.volumeMethod == 'notSure') ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text("No worries, we will calculate for you!",
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],

                // Quick volume estimator
                if (d.pool.volumeMethod == 'helpEstimate') ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.blue.shade200)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calculate_rounded, size: 16.sp, color: Colors.grey.shade700),
                            SizedBox(width: 6.w),
                            Text("Quick volume estimator", style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade800)),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text("Shape", style: _label),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          children: _poolShapes.map((shape) {
                            final val = shape.toLowerCase();
                            return _pillButton(shape, selected: d.pool.shape == val, onTap: () => _updatePool((p) => p.copyWith(shape: val)));
                          }).toList(),
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            Expanded(child: _numberField("Length (ft)", _lengthCtrl, (v) => _updatePool((p) => p.copyWith(length: double.tryParse(v) ?? 0)))),
                            if (d.pool.shape != 'round') ...[
                              SizedBox(width: 8.w),
                              Expanded(child: _numberField("Width (ft)", _widthCtrl, (v) => _updatePool((p) => p.copyWith(width: double.tryParse(v) ?? 0)))),
                            ],
                            SizedBox(width: 8.w),
                            Expanded(child: _numberField("Avg depth (ft)", _depthCtrl, (v) => _updatePool((p) => p.copyWith(avgDepth: double.tryParse(v) ?? 0)))),
                          ],
                        ),
                        Builder(builder: (_) {
                          final est = _calcEstimatedVolume();
                          if (est > 0) {
                            // Also store it
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (widget.data.pool.estimatedVolume != est) {
                                _updatePool((p) => p.copyWith(estimatedVolume: est));
                              }
                            });
                            return Padding(
                              padding: EdgeInsets.only(top: 10.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(color: _primaryLight, borderRadius: BorderRadius.circular(8.r)),
                                child: Text("Est. volume: ${_displayVolume(est).toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')} $_unitLabel",
                                  style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ],

                // Known volume input
                if (d.pool.volumeMethod == 'knowIt') ...[
                  SizedBox(height: 12.h),
                  Text("Enter your pool volume (${_volumeUnit == 'liters' ? 'liters' : 'gallons'})", style: _caption),
                  SizedBox(height: 6.h),
                  _numberField(_volumeUnit == 'liters' ? "e.g., 68000" : "e.g., 18000", _knownVolCtrl, (v) {
                    final val = int.tryParse(v) ?? 0;
                    final galVal = _volumeUnit == 'liters' ? _lToGal(val) : val;
                    _updatePool((p) => p.copyWith(estimatedVolume: galVal));
                  }),
                ],

                // Add Other free-text field
                if (d.pool.volumeMethod == 'addOther') ...[
                  SizedBox(height: 12.h),
                  Text("Enter your pool volume", style: _caption),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _poolCustomVolumeTextCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    onChanged: (v) => _updatePool((p) => p.copyWith(customVolumeText: v)),
                    decoration: InputDecoration(
                      hintText: "e.g., approximately 15000 gallons",
                      hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],

                SizedBox(height: 14.h),
                Text("Sanitizer system", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: _poolSanitizers.entries.map((e) {
                    return _pillButton(e.key, selected: d.pool.sanitizerSystem == e.value, onTap: () => _updatePool((p) => p.copyWith(sanitizerSystem: e.value)));
                  }).toList(),
                ),

                if (d.pool.sanitizerSystem == 'addOther') ...[
                  SizedBox(height: 10.h),
                  TextField(
                    controller: _poolCustomSanitizerCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    onChanged: (v) => _updatePool((p) => p.copyWith(customSanitizer: v)),
                    decoration: InputDecoration(
                      hintText: "Enter your sanitizer system",
                      hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],

                if (d.pool.sanitizerSystem == 'notSure') ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text("No worries, we will calculate for you!",
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],

                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE).withOpacity(0.5), borderRadius: BorderRadius.circular(8.r)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("More details (optional)", style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                      SizedBox(height: 6.h),
                      TextField(
                        controller: _moreDetailsCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 12.sp),
                        onChanged: (v) => _updatePool((p) => p.copyWith(moreDetails: v)),
                        decoration: InputDecoration(
                          hintText: "Surface, filter type, in-ground/above-ground...",
                          hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                          contentPadding: EdgeInsets.all(10.w),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // ── Hot tub cover & lock ─────────────────────
        if (showHotTub) ...[
          SizedBox(height: 14.h),
          _card(
            bgColor: const Color(0xFFFFFBEB),
            borderColor: const Color(0xFFFCD34D),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Hot tub cover"),
                Text("We need to know about your cover so we can access the water for testing.", style: _caption),
                SizedBox(height: 10.h),
                Text("Does your hot tub have a cover with a lock?", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: [
                    _pillButton("No lock", selected: d.hotTub.coverLock == 'noLock', onTap: () => _updateHotTub((h) => h.copyWith(coverLock: 'noLock'))),
                    _pillButton("Yes — it will be unlocked", selected: d.hotTub.coverLock == 'yesUnlocked', onTap: () => _updateHotTub((h) => h.copyWith(coverLock: 'yesUnlocked'))),
                    _pillButton("Yes — it stays locked", selected: d.hotTub.coverLock == 'yesLocked', onTap: () => _updateHotTub((h) => h.copyWith(coverLock: 'yesLocked'))),
                  ],
                ),
                if (d.hotTub.coverLock == 'yesLocked') ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFFCD34D)),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Where is the key / how do we unlock it?", style: _label),
                        SizedBox(height: 6.h),
                        TextField(
                          controller: _hotTubKeyLocationCtrl,
                          style: GoogleFonts.inter(fontSize: 12.sp),
                          onChanged: (v) => _updateHotTub((h) => h.copyWith(coverKeyLocation: v)),
                          decoration: InputDecoration(
                            hintText: "e.g., key is under the step",
                            hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                            contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        // ── Hot tub details ──────────────────────────
        if (showHotTub) ...[
          SizedBox(height: 14.h),
          _card(
            bgColor: _primaryLight,
            borderColor: _primaryBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle("Hot tub details"),
                Text("Used for spa dosing and better water guidance.", style: _caption),
                SizedBox(height: 10.h),
                Text("Hot tub volume", style: _label),
                SizedBox(height: 8.h),

                // Unit toggle (Gallons / Liters) — same as pool
                Row(
                  children: [
                    Text("Unit:", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                    SizedBox(width: 8.w),
                    _pillButton("Gallons", selected: _volumeUnit == 'gallons', onTap: () {
                      setState(() => _volumeUnit = 'gallons');
                    }),
                    SizedBox(width: 6.w),
                    _pillButton("Liters", selected: _volumeUnit == 'liters', onTap: () {
                      setState(() => _volumeUnit = 'liters');
                    }),
                  ],
                ),
                SizedBox(height: 10.h),

                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: (_volumeUnit == 'liters' ? _hotTubVolumesL : _hotTubVolumesGal).entries.map((e) {
                    return _pillButton(e.key, selected: d.hotTub.volume == e.value, onTap: () => _updateHotTub((h) => h.copyWith(volume: e.value)));
                  }).toList(),
                ),

                // Show "Not Sure" message
                if (d.hotTub.volume == 'notSure') ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text("No worries, we will calculate for you!",
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],

                // Show dedicated input when "Add Other" is selected
                if (d.hotTub.volume == 'addOther') ...[
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _customVolCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    onChanged: (v) => _updateHotTub((h) => h.copyWith(customVolume: v)),
                    decoration: InputDecoration(
                      hintText: "Enter your hot tub volume (e.g., ${_volumeUnit == 'liters' ? '1590 liters' : '420 gallons'})",
                      hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],

                // Show optional exact volume when a preset is selected
                if (d.hotTub.volume != 'addOther') ...[
                  SizedBox(height: 8.h),
                  Text("Or enter your exact volume (optional)", style: _caption),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _customVolCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    onChanged: (v) => _updateHotTub((h) => h.copyWith(customVolume: v)),
                    decoration: InputDecoration(
                      hintText: "e.g., ${_volumeUnit == 'liters' ? '1590 liters' : '420 gallons'}",
                      hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                      prefixIcon: Padding(padding: EdgeInsets.only(left: 10.w, right: 4.w), child: Text("✏️", style: TextStyle(fontSize: 14.sp))),
                      prefixIconConstraints: BoxConstraints(minWidth: 30.w),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],

                SizedBox(height: 14.h),
                Text("Sanitizer system", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: _hotTubSanitizers.entries.map((e) {
                    return _pillButton(e.key, selected: d.hotTub.sanitizerSystem == e.value, onTap: () => _updateHotTub((h) => h.copyWith(sanitizerSystem: e.value)));
                  }).toList(),
                ),

                if (d.hotTub.sanitizerSystem == 'addOther') ...[
                  SizedBox(height: 10.h),
                  TextField(
                    controller: _hotTubCustomSanitizerCtrl,
                    style: GoogleFonts.inter(fontSize: 12.sp),
                    onChanged: (v) => _updateHotTub((h) => h.copyWith(customSanitizer: v)),
                    decoration: InputDecoration(
                      hintText: "Enter your sanitizer system",
                      hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ],

                if (d.hotTub.sanitizerSystem == 'notSure') ...[
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text("No worries, we will calculate for you!",
                      style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ),
                ],

                SizedBox(height: 14.h),
                Text("Usage (optional)", style: _label),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 6.w,
                  runSpacing: 6.h,
                  children: _hotTubUsage.entries.map((e) {
                    return _pillButton(e.key, selected: d.hotTub.usage == e.value, onTap: () => _updateHotTub((h) => h.copyWith(usage: e.value)));
                  }).toList(),
                ),

                SizedBox(height: 14.h),
                Text("Filter model (optional)", style: _label),
                SizedBox(height: 6.h),
                TextField(
                  controller: _filterCtrl,
                  style: GoogleFonts.inter(fontSize: 12.sp),
                  onChanged: (v) => _updateHotTub((h) => h.copyWith(filterModel: v)),
                  decoration: InputDecoration(
                    hintText: "Add later (photo / model #)",
                    hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400),
                    prefixIcon: Padding(padding: EdgeInsets.only(left: 10.w, right: 4.w), child: Text("💾", style: TextStyle(fontSize: 14.sp))),
                    prefixIconConstraints: BoxConstraints(minWidth: 30.w),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],

        SizedBox(height: 12.h),
        Text("You can update water details anytime in Profile.", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade400), textAlign: TextAlign.center),
      ],
    );
  }

  // ── Reusable widgets ──────────────────────────────────────────────────

  Widget _waterTypeGrid(WaterSetup d) {
    Widget card(Map<String, String> type) {
      final selected = d.waterType == type['value'];
      return Expanded(
        child: GestureDetector(
          onTap: () => _update((s) => s.copyWith(waterType: type['value']!)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1),
            ),
            child: Row(
              children: [
                Text(type['icon']!, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type['label']!, style: GoogleFonts.inter(fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
                      SizedBox(height: 2.h),
                      Text(type['desc']!, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              card(_waterTypes[0]),
              SizedBox(width: 10.w),
              card(_waterTypes[1]),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        IntrinsicHeight(
          child: Row(
            children: [
              card(_waterTypes[2]),
              SizedBox(width: 10.w),
              card(_waterTypes[3]),
            ],
          ),
        ),
      ],
    );
  }

  TextStyle get _caption => GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey.shade500);
  TextStyle get _label => GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade700);

  Widget _card({required Widget child, Color? bgColor, Color? borderColor}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor ?? Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(text, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.grey.shade900)),
    );
  }

  Widget _pillButton(String label, {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCCFBF1) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: selected ? _primaryDark : Colors.grey.shade600)),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController ctrl, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey.shade500)),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 13.sp),
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
