import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/setup_profile_model.dart';
import 'package:retro_route/utils/app_colors.dart';

class WaterSetupForm extends StatefulWidget {
  final WaterSetup data;
  final ValueChanged<WaterSetup> onChange;

  const WaterSetupForm({
    super.key,
    required this.data,
    required this.onChange,
  });

  @override
  State<WaterSetupForm> createState() => _WaterSetupFormState();
}

class _WaterSetupFormState extends State<WaterSetupForm> {
  late TextEditingController _poolVolumeCtrl;
  late TextEditingController _poolCustomVolumeTextCtrl;
  late TextEditingController _poolLengthCtrl;
  late TextEditingController _poolWidthCtrl;
  late TextEditingController _poolDepthCtrl;
  late TextEditingController _poolDetailsCtrl;
  late TextEditingController _poolCustomSanitizerCtrl;
  late TextEditingController _hotTubCustomVolCtrl;
  late TextEditingController _hotTubCustomSanitizerCtrl;
  late TextEditingController _hotTubFilterCtrl;
  late TextEditingController _hotTubKeyLocationCtrl;
  late String _volumeUnit;

  WaterSetup get w => widget.data;

  @override
  void initState() {
    super.initState();
    _volumeUnit = w.pool.volumeUnit.isEmpty ? 'gallons' : w.pool.volumeUnit;
    _poolVolumeCtrl = TextEditingController(
        text: w.pool.estimatedVolume > 0 ? _displayVolume(w.pool.estimatedVolume).toString() : '');
    _poolCustomVolumeTextCtrl = TextEditingController(text: w.pool.customVolumeText);
    _poolLengthCtrl = TextEditingController(
        text: w.pool.length > 0 ? w.pool.length.toString() : '');
    _poolWidthCtrl = TextEditingController(
        text: w.pool.width > 0 ? w.pool.width.toString() : '');
    _poolDepthCtrl = TextEditingController(
        text: w.pool.avgDepth > 0 ? w.pool.avgDepth.toString() : '');
    _poolDetailsCtrl = TextEditingController(text: w.pool.moreDetails);
    _poolCustomSanitizerCtrl = TextEditingController(text: w.pool.customSanitizer);
    _hotTubCustomVolCtrl = TextEditingController(text: w.hotTub.customVolume);
    _hotTubCustomSanitizerCtrl = TextEditingController(text: w.hotTub.customSanitizer);
    _hotTubFilterCtrl = TextEditingController(text: w.hotTub.filterModel);
    _hotTubKeyLocationCtrl = TextEditingController(text: w.hotTub.coverKeyLocation);
  }

  @override
  void dispose() {
    _poolVolumeCtrl.dispose();
    _poolCustomVolumeTextCtrl.dispose();
    _poolLengthCtrl.dispose();
    _poolWidthCtrl.dispose();
    _poolDepthCtrl.dispose();
    _poolDetailsCtrl.dispose();
    _poolCustomSanitizerCtrl.dispose();
    _hotTubCustomVolCtrl.dispose();
    _hotTubCustomSanitizerCtrl.dispose();
    _hotTubFilterCtrl.dispose();
    _hotTubKeyLocationCtrl.dispose();
    super.dispose();
  }

  int _galToL(int gal) => (gal * 3.785).round();
  int _lToGal(int l) => (l / 3.785).round();

  int _displayVolume(int galValue) {
    if (galValue <= 0) return 0;
    return _volumeUnit == 'liters' ? _galToL(galValue) : galValue;
  }

  String get _unitLabel => _volumeUnit == 'liters' ? 'L' : 'gal';

  void _update(WaterSetup updated) => widget.onChange(updated);

  PoolSetup _withRecalculatedVolume(PoolSetup p) {
    if (p.shape.isEmpty || p.length <= 0 || p.avgDepth <= 0) return p;
    double vol = 0;
    if (p.shape == 'rectangle' && p.width > 0) {
      vol = p.length * p.width * p.avgDepth * 7.48;
    } else if (p.shape == 'round') {
      vol = pi * pow(p.length / 2, 2) * p.avgDepth * 7.48;
    } else if (p.shape == 'oval' && p.width > 0) {
      vol = pi * (p.length / 2) * (p.width / 2) * p.avgDepth * 7.48;
    }
    final rounded = (vol / 1000).round() * 1000;
    return p.copyWith(estimatedVolume: rounded);
  }

  void _updatePoolAndRecalculate(PoolSetup pool) {
    _update(w.copyWith(pool: _withRecalculatedVolume(pool)));
  }

  bool get showPool => w.waterType == 'pool' || w.waterType == 'both';
  bool get showHotTub => w.waterType == 'hotTub' || w.waterType == 'both';

  static const _poolSanitizerMap = {
    'Chlorine': 'chlorine',
    'Saltwater': 'saltwater',
    'Bromine': 'bromine',
    'Add Other': 'addOther',
  };

  static const _hotTubSanitizerMap = {
    'Chlorine': 'chlorine',
    'Bromine': 'bromine',
    'Add Other': 'addOther',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        _buildHeader(),
        SizedBox(height: 20.h),

        // ── Water type ──
        _section(
          color: Colors.white,
          borderColor: Colors.grey[300]!,
          children: [
            _label("What do you have at this address?"),
            _sublabel("Pick one — you can add more later."),
            SizedBox(height: 12.h),
            _waterTypeGrid(),
          ],
        ),
        SizedBox(height: 16.h),

        // ── Pool details ──
        if (showPool) ...[
          _section(
            color: Color(0xFFF0F6FF),
            borderColor: Colors.blue[200]!,
            children: [
              _label("Pool details"),
              _sublabel("Used for accurate dosing and clear recommendations."),
              SizedBox(height: 12.h),
              _smallLabel("Pool volume"),
              SizedBox(height: 8.h),

              // ── Unit toggle ──
              Row(
                children: [
                  Text("Unit:", style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500])),
                  SizedBox(width: 8.w),
                  _chip('Gallons', _volumeUnit == 'gallons', () {
                    setState(() => _volumeUnit = 'gallons');
                    _update(w.copyWith(pool: w.pool.copyWith(volumeUnit: 'gallons')));
                    if (w.pool.estimatedVolume > 0) {
                      _poolVolumeCtrl.text = w.pool.estimatedVolume.toString();
                    }
                  }, Colors.blue),
                  SizedBox(width: 6.w),
                  _chip('Liters', _volumeUnit == 'liters', () {
                    setState(() => _volumeUnit = 'liters');
                    _update(w.copyWith(pool: w.pool.copyWith(volumeUnit: 'liters')));
                    if (w.pool.estimatedVolume > 0) {
                      _poolVolumeCtrl.text = _galToL(w.pool.estimatedVolume).toString();
                    }
                  }, Colors.blue),
                ],
              ),
              SizedBox(height: 10.h),

              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _chip('I know it', w.pool.volumeMethod == 'knowIt',
                      () => _update(w.copyWith(pool: w.pool.copyWith(volumeMethod: 'knowIt'))), AppColors.primary),
                  _chip('Help me estimate', w.pool.volumeMethod == 'helpEstimate',
                      () => _update(w.copyWith(pool: w.pool.copyWith(volumeMethod: 'helpEstimate'))), AppColors.primary),
                  _chip('Add Other', w.pool.volumeMethod == 'addOther',
                      () => _update(w.copyWith(pool: w.pool.copyWith(volumeMethod: 'addOther'))), AppColors.primary),
                ],
              ),

              // ── Quick estimator ──
              if (w.pool.volumeMethod == 'helpEstimate') ...[
                SizedBox(height: 14.h),
                Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.blue[200]!),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calculate_outlined, size: 16.sp, color: Colors.grey[700]),
                          SizedBox(width: 6.w),
                          Text("Quick volume estimator",
                              style: GoogleFonts.inter(
                                  fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.grey[800])),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      _smallLabel("Shape"),
                      SizedBox(height: 6.h),
                      Wrap(
                        spacing: 8.w,
                        children: ['Rectangle', 'Round', 'Oval'].map((s) {
                          final val = s.toLowerCase();
                          return _chip(s, w.pool.shape == val, () {
                            _updatePoolAndRecalculate(
                              w.pool.copyWith(shape: val),
                            );
                          }, AppColors.blue);
                        }).toList(),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          Expanded(
                            child: _numberField(_poolLengthCtrl, "Length (ft)", (v) {
                              _updatePoolAndRecalculate(
                                w.pool.copyWith(length: double.tryParse(v) ?? 0),
                              );
                            }),
                          ),
                          if (w.pool.shape != 'round') ...[
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _numberField(_poolWidthCtrl, "Width (ft)", (v) {
                                _updatePoolAndRecalculate(
                                  w.pool.copyWith(width: double.tryParse(v) ?? 0),
                                );
                              }),
                            ),
                          ],
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _numberField(_poolDepthCtrl, "Avg depth (ft)", (v) {
                              _updatePoolAndRecalculate(
                                w.pool.copyWith(avgDepth: double.tryParse(v) ?? 0),
                              );
                            }),
                          ),
                        ],
                      ),
                      if (w.pool.estimatedVolume > 0) ...[
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FE),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            "Est. volume: ${_formatNum(_displayVolume(w.pool.estimatedVolume))} $_unitLabel",
                            style: GoogleFonts.inter(
                                fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppColors.blue),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Know it field ──
              if (w.pool.volumeMethod == 'knowIt') ...[
                SizedBox(height: 12.h),
                _smallLabel("Enter your pool volume (${_volumeUnit == 'liters' ? 'liters' : 'gallons'})"),
                SizedBox(height: 6.h),
                _numberField(_poolVolumeCtrl, _volumeUnit == 'liters' ? "e.g., 68000" : "e.g., 18000", (v) {
                  final val = int.tryParse(v) ?? 0;
                  final galVal = _volumeUnit == 'liters' ? _lToGal(val) : val;
                  _update(w.copyWith(pool: w.pool.copyWith(estimatedVolume: galVal)));
                }),
              ],

              // ── Add Other free-text field ──
              if (w.pool.volumeMethod == 'addOther') ...[
                SizedBox(height: 12.h),
                _smallLabel("Enter your pool volume"),
                SizedBox(height: 6.h),
                _textField(
                  controller: _poolCustomVolumeTextCtrl,
                  hint: "e.g., approximately 15000 gallons",
                  onChanged: (v) => _update(w.copyWith(pool: w.pool.copyWith(customVolumeText: v))),
                ),
              ],

              SizedBox(height: 14.h),
              _smallLabel("Sanitizer system"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _poolSanitizerMap.entries.map((e) {
                  return _chip(e.key, w.pool.sanitizerSystem == e.value,
                      () => _update(w.copyWith(pool: w.pool.copyWith(sanitizerSystem: e.value))), AppColors.blue);
                }).toList(),
              ),

              if (w.pool.sanitizerSystem == 'addOther') ...[
                SizedBox(height: 10.h),
                _textField(
                  controller: _poolCustomSanitizerCtrl,
                  hint: "Enter your sanitizer system",
                  onChanged: (v) => _update(w.copyWith(pool: w.pool.copyWith(customSanitizer: v))),
                ),
              ],

              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[100]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("More details (optional)",
                        style: GoogleFonts.inter(
                            fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.grey[700])),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: _poolDetailsCtrl,
                      onChanged: (v) => _update(w.copyWith(pool: w.pool.copyWith(moreDetails: v))),
                      maxLines: 3,
                      style: GoogleFonts.inter(fontSize: 12.sp),
                      decoration: InputDecoration(
                        hintText: "Surface, filter type, in-ground/above-ground...",
                        hintStyle: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.all(12.w),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],

        // ── Hot tub cover & lock ──
        if (showHotTub) ...[
          _section(
            color: const Color(0xFFFFFBEB), // amber-50
            borderColor: const Color(0xFFFCD34D), // amber-200
            children: [
              _label("Hot tub cover"),
              _sublabel("We need to know about your cover so we can access the water for testing."),
              SizedBox(height: 12.h),
              _smallLabel("Does your hot tub have a cover with a lock?"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _chip('No lock', w.hotTub.coverLock == 'noLock',
                    () => _update(w.copyWith(hotTub: w.hotTub.copyWith(coverLock: 'noLock'))), AppColors.blue),
                  _chip('Yes — it will be unlocked', w.hotTub.coverLock == 'yesUnlocked',
                    () => _update(w.copyWith(hotTub: w.hotTub.copyWith(coverLock: 'yesUnlocked'))), AppColors.blue),
                  _chip('Yes — it stays locked', w.hotTub.coverLock == 'yesLocked',
                    () => _update(w.copyWith(hotTub: w.hotTub.copyWith(coverLock: 'yesLocked'))), AppColors.blue),
                ],
              ),
              if (w.hotTub.coverLock == 'yesLocked') ...[
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
                      _smallLabel("Where is the key / how do we unlock it?"),
                      SizedBox(height: 6.h),
                      _textField(
                        controller: _hotTubKeyLocationCtrl,
                        hint: "e.g., key is under the step",
                        onChanged: (v) => _update(w.copyWith(hotTub: w.hotTub.copyWith(coverKeyLocation: v))),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 16.h),
        ],

        // ── Hot tub details ──
        if (showHotTub) ...[
          _section(
            color: const Color(0xFFEAF2FE),
            borderColor: const Color(0xFFCFE0FB),
            children: [
              _label("Hot tub details"),
              _sublabel("Used for spa dosing and better water guidance."),
              SizedBox(height: 12.h),
              _smallLabel("Hot tub volume"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: (_volumeUnit == 'liters'
                    ? ['1136 L', '1514 L', '1893 L', 'Add Other']
                    : ['300 gal', '400 gal', '500 gal', 'Add Other']).map((v) {
                  final val = v == 'Add Other' ? 'addOther' : v.replaceAll(RegExp(r' (gal|L)'), '');
                  return _chip(v, w.hotTub.volume == val,
                      () => _update(w.copyWith(hotTub: w.hotTub.copyWith(volume: val))), AppColors.blue);
                }).toList(),
              ),

              // Show dedicated input when "Add Other" is selected
              if (w.hotTub.volume == 'addOther') ...[
                SizedBox(height: 10.h),
                _textField(
                  controller: _hotTubCustomVolCtrl,
                  hint: "Enter your hot tub volume (e.g., ${_volumeUnit == 'liters' ? '1590 liters' : '420 gallons'})",
                  onChanged: (v) => _update(w.copyWith(hotTub: w.hotTub.copyWith(customVolume: v))),
                ),
              ],

              // Show optional exact volume when a preset is selected
              if (w.hotTub.volume != 'addOther') ...[
                SizedBox(height: 10.h),
                _sublabel("Or enter your exact volume (optional)"),
                SizedBox(height: 6.h),
                _textField(
                  controller: _hotTubCustomVolCtrl,
                  hint: "e.g., ${_volumeUnit == 'liters' ? '1590 liters' : '420 gallons'}",
                  prefixIcon: Icons.edit,
                  prefixColor: AppColors.blue,
                  onChanged: (v) => _update(w.copyWith(hotTub: w.hotTub.copyWith(customVolume: v))),
                ),
              ],

              SizedBox(height: 14.h),
              _smallLabel("Sanitizer system"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _hotTubSanitizerMap.entries.map((e) {
                  return _chip(e.key, w.hotTub.sanitizerSystem == e.value,
                      () => _update(w.copyWith(hotTub: w.hotTub.copyWith(sanitizerSystem: e.value))), AppColors.blue);
                }).toList(),
              ),

              if (w.hotTub.sanitizerSystem == 'addOther') ...[
                SizedBox(height: 10.h),
                _textField(
                  controller: _hotTubCustomSanitizerCtrl,
                  hint: "Enter your sanitizer system",
                  onChanged: (v) => _update(w.copyWith(hotTub: w.hotTub.copyWith(customSanitizer: v))),
                ),
              ],

              SizedBox(height: 14.h),
              _smallLabel("Usage (optional)"),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: ['Daily', 'Weekly', 'Occasional'].map((u) {
                  final val = u.toLowerCase();
                  return _chip(u, w.hotTub.usage == val,
                      () => _update(w.copyWith(hotTub: w.hotTub.copyWith(usage: val))), AppColors.blue);
                }).toList(),
              ),

              SizedBox(height: 14.h),
              _smallLabel("Filter model (optional)"),
              SizedBox(height: 6.h),
              _textField(
                controller: _hotTubFilterCtrl,
                hint: "Add later (photo / model #)",
                prefixIcon: Icons.save_outlined,
                prefixColor: Colors.grey,
                onChanged: (v) => _update(w.copyWith(hotTub: w.hotTub.copyWith(filterModel: v))),
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],

        // ── Note ──
        Center(
          child: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text("You can update water details anytime in Profile.",
                style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[400])),
          ),
        ),
      ],
    );
  }

  // ── Shared Widgets ─────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: 1.0,
                    minHeight: 6,
                    backgroundColor: Colors.white30,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
              ),
              // SizedBox(width: 12.w),
              // GestureDetector(
              //   onTap: () => _update(w.copyWith(waterType: 'notRightNow')),
              //   child: Text("Skip",
              //       style: GoogleFonts.inter(
              //           fontSize: 13.sp,
              //           fontWeight: FontWeight.w600,
              //           color: Colors.white70)),
              // ),
            ],
          ),
          SizedBox(height: 14.h),
          Text("Your water setup",
              style: GoogleFonts.inter(
                  fontSize: 22.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 4.h),
          Text("This helps us dose correctly and build better recommendations. You can update it anytime.",
              style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFFDCEAFE))),
        ],
      ),
    );
  }

  Widget _waterTypeGrid() {
    Widget card(String value, String icon, String label, String desc) {
      final selected = w.waterType == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => _update(w.copyWith(waterType: value)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
              border: Border.all(
                color: selected ? AppColors.primary : Colors.grey[300]!,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Row(
              children: [
                Text(icon, style: TextStyle(fontSize: 20.sp)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.inter(
                              fontSize: 13.sp, fontWeight: FontWeight.w700, color: Colors.grey[900])),
                      SizedBox(height: 2.h),
                      Text(desc,
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500])),
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
              card('pool', '🏊', 'Pool', 'A swimming pool'),
              SizedBox(width: 10.w),
              card('hotTub', '♨️', 'Hot tub', 'A spa / hot tub'),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        IntrinsicHeight(
          child: Row(
            children: [
              card('both', '💧', 'Both', 'Pool + Hot tub'),
              SizedBox(width: 10.w),
              card('notRightNow', '—', 'Not right now', 'Skip water details'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section({
    required Color color,
    required Color borderColor,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.grey[900]));

  Widget _sublabel(String t) => Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Text(t, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500])));

  Widget _smallLabel(String t) => Text(t,
      style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.grey[700]));

  Widget _chip(String label, bool selected, VoidCallback onTap, Color activeColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? Color(0xFFCCFBF1) : Colors.white,
          border: Border.all(color: selected ? activeColor : Colors.grey[300]!, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12.sp, fontWeight: FontWeight.w600, color: selected ? activeColor : Colors.grey[900])),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    Color? prefixColor,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 13.sp),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[400]),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16.sp, color: prefixColor) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey[500])),
        SizedBox(height: 4.h),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 13.sp),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
          ),
        ),
      ],
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}
