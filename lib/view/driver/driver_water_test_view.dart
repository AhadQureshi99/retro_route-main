import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:retro_route/model/driver_delivery_model.dart';
import 'package:retro_route/model/water_test_result_model.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/driver_constants.dart';
import 'package:retro_route/view/driver/widgets/driver_widgets.dart';
import 'package:retro_route/view_model/driver_view_model/driver_view_model.dart';

class DriverWaterTestScreen extends ConsumerStatefulWidget {
  final DriverDelivery delivery;
  const DriverWaterTestScreen({super.key, required this.delivery});

  @override
  ConsumerState<DriverWaterTestScreen> createState() =>
      _DriverWaterTestScreenState();
}

class _DriverWaterTestScreenState extends ConsumerState<DriverWaterTestScreen> {
  int _step = 0; // 0=Type&Volume, 1=Sanitizer, 2=WaterTest, 3=VisualCheck

  // ── Step 0: Type & Volume ──
  late String _waterType; // 'hot_tub' or 'pool'
  String? _volumeId;
  double? _volumeLiters;
  final TextEditingController _customVolCtrl = TextEditingController();
  String? _lastDrain;
  bool _isFirstVisit = true;

  // ── Step 1: Sanitizer ──
  late String _sanitizerType;

  // ── Step 2: Water Test Values ──
  final Map<String, TextEditingController> _ctrls = {
    'freeChlorine': TextEditingController(),
    'totalChlorine': TextEditingController(),
    'bromine': TextEditingController(),
    'pH': TextEditingController(),
    'alkalinity': TextEditingController(),
    'hardness': TextEditingController(),
    'cyanuricAcid': TextEditingController(),
    'copper': TextEditingController(),
    'iron': TextEditingController(),
    'phosphate': TextEditingController(),
    'salt': TextEditingController(),
    'borate': TextEditingController(),
    'biguanide': TextEditingController(),
    'biguanideShock': TextEditingController(),
  };

  // ── Step 3: Visual ──
  bool _foam = false,
      _cloudy = false,
      _filterDirty = false,
      _scale = false,
      _flush = false,
      _algae = false;

  // Hot Tub volumes from blueprint
  static const List<Map<String, dynamic>> _htVolumes = [
    {'id': 'ht_sm', 'label': 'Small (2-3 person)', 'desc': 'Compact, plug & play', 'liters': 700},
    {'id': 'ht_md', 'label': 'Medium (4-5 person)', 'desc': 'Most common family spa', 'liters': 1200},
    {'id': 'ht_lg', 'label': 'Large (6-8 person)', 'desc': 'Party/family size', 'liters': 1800},
    {'id': 'ht_xl', 'label': 'XL (8+ / Swim Spa)', 'desc': 'Oversized or swim spa', 'liters': 2500},
  ];

  // Pool volumes from blueprint
  static const List<Map<String, dynamic>> _poolVolumes = [
    {'id': 'pl_sm', 'label': 'Small Above-Ground', 'desc': '12-15 ft round, 4 ft deep', 'liters': 15000},
    {'id': 'pl_md', 'label': 'Medium', 'desc': '15×30 ft, avg 5 ft deep', 'liters': 40000},
    {'id': 'pl_lg', 'label': 'Large In-Ground', 'desc': '20×40 ft, avg 5.5 ft deep', 'liters': 60000},
    {'id': 'pl_xl', 'label': 'XL / Commercial', 'desc': '25×50 ft+ or commercial', 'liters': 80000},
  ];

  @override
  void initState() {
    super.initState();
    final ws = widget.delivery.userId?.waterSetup;
    final wt = ws?.waterType ?? '';
    _waterType = wt.toLowerCase().contains('pool') ? 'pool' : 'hot_tub';

    final san = _waterType == 'pool'
        ? (ws?.pool.sanitizerSystem ?? 'chlorine')
        : (ws?.hotTub.sanitizerSystem ?? 'chlorine');
    final s = san.toLowerCase();
    if (s.contains('bromine')) {
      _sanitizerType = 'bromine';
    } else if (s.contains('salt')) {
      _sanitizerType = 'salt';
    } else {
      _sanitizerType = 'chlorine';
    }

    // Pre-fill volume from profile
    if (_waterType == 'pool') {
      final vol = ws?.pool.estimatedVolume ?? 0;
      if (vol > 0) {
        _volumeLiters = vol.toDouble();
        for (final v in _poolVolumes) {
          if ((v['liters'] as int) == vol) { _volumeId = v['id'] as String; break; }
        }
        _volumeId ??= 'custom';
        if (_volumeId == 'custom') _customVolCtrl.text = vol.toString();
      }
    } else {
      final vol = double.tryParse(ws?.hotTub.volume ?? '') ?? 0;
      if (vol > 0) {
        _volumeLiters = vol;
        for (final v in _htVolumes) {
          if ((v['liters'] as int).toDouble() == vol) { _volumeId = v['id'] as String; break; }
        }
        _volumeId ??= 'custom';
        if (_volumeId == 'custom') _customVolCtrl.text = vol.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _customVolCtrl.dispose();
    for (final c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  String get _poolType => _waterType == 'pool' ? 'pool' : 'hottub';

  WtStatus _getStatus(String key) {
    final val = double.tryParse(_ctrls[key]?.text ?? '');
    return getWtStatus(key, val, poolType: _poolType, sanitizer: _sanitizerType);
  }

  int get _outOfRangeCount {
    int count = 0;
    for (final key in _ctrls.keys) {
      final st = _getStatus(key);
      if (st == WtStatus.low || st == WtStatus.high) count++;
    }
    return count;
  }

  String _rangeText(String key) {
    final ranges = _poolType == 'hottub' ? WaterTestRanges.hotTub : WaterTestRanges.pool;
    final r = ranges[key];
    if (r == null) return '';
    final mn = r['min']!;
    final mx = r['max']!;
    final unit = key == 'phosphate' ? 'ppb' : (key == 'pH' ? '' : 'ppm');
    if (mn == 0 && mx < 1) return '(0–${mx.toStringAsFixed(1)} $unit)'.trim();
    if (key == 'pH') return '(${mn.toStringAsFixed(1)}–${mx.toStringAsFixed(1)})';
    return '(${mn.toInt()}–${mx.toInt()} $unit)'.trim();
  }

  void _generateCrate() {
    final results = <String, double?>{};
    for (final entry in _ctrls.entries) {
      results[entry.key] = double.tryParse(entry.value.text);
    }
    final wt = WaterTestResult(
      orderId: widget.delivery.id ?? '',
      customerId: widget.delivery.userId?.id ?? '',
      poolType: _poolType,
      sanitizerType: _sanitizerType,
      volume: _volumeLiters,
      testedAt: DateTime.now(),
      freeChlorine: results['freeChlorine'],
      totalChlorine: results['totalChlorine'],
      bromine: results['bromine'],
      pH: results['pH'],
      alkalinity: results['alkalinity'],
      hardness: results['hardness'],
      cyanuricAcid: results['cyanuricAcid'],
      copper: results['copper'],
      iron: results['iron'],
      phosphate: results['phosphate'],
      salt: results['salt'],
      borate: results['borate'],
      biguanide: results['biguanide'],
      biguanideShock: results['biguanideShock'],
      hasFoam: _foam,
      isCloudy: _cloudy,
      filterDirty: _filterDirty,
      hasScale: _scale,
      needsFlush: _flush,
      hasAlgae: _algae,
      lastDrain: _lastDrain,
      isFirstVisit: _isFirstVisit,
    );
    ref.read(driverDeliveriesProvider.notifier).setWaterTestResult(wt);
    context.push(AppRoutes.driverCrate, extra: widget.delivery);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final stepTitles = ['New Water Test', 'Sanitizer Type', 'Water Test', 'Visual Check'];
    final stepSubtitles = [
      'What are we testing?',
      _waterType == 'hot_tub' ? '♨️ Hot Tub · ${_volumeLiters?.toInt() ?? '?'}L' : '🏊 Pool · ${_volumeLiters?.toInt() ?? '?'}L',
      '${widget.delivery.safeCustomerName} · ${_poolType == 'hottub' ? 'Hot tub' : 'Pool'}',
      'What does the water look like?',
    ];
    final headerColors = [
      [const Color(0xFF1A2A3A), const Color(0xFF2C6E7A)],
      [const Color(0xFF1A2A3A), const Color(0xFF2C6E7A)],
      [const Color(0xFFE65100), const Color(0xFFBF360C)],
      [const Color(0xFFE65100), const Color(0xFFBF360C)],
    ];

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Column(children: [
        // ── Header
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: headerColors[_step],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Row(children: [
                  GestureDetector(
                    onTap: () {
                      if (_step > 0) { setState(() => _step--); } else { context.pop(); }
                    },
                    child: Container(
                      width: 36.w, height: 36.w,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(Icons.arrow_back, color: Colors.white, size: 18.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('🔬 ${stepTitles[_step]}',
                          style: GoogleFonts.inter(fontSize: 22.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                      Text(stepSubtitles[_step],
                          style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.white60, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20.r)),
                    child: Text('${_step + 1}/4', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ]),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(color: i <= _step ? Colors.white : Colors.white24, borderRadius: BorderRadius.circular(2.r)),
                  ),
                ))),
              ),
              SizedBox(height: 12.h),
              Container(height: 24.h, decoration: BoxDecoration(color: AppColors.bgColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)))),
            ]),
          ),
        ),

        // ── Body
        Expanded(
          child: _step == 0
              ? _buildStep0TypeVolume()
              : _step == 1
                  ? _buildStep1Sanitizer()
                  : _step == 2
                      ? _buildStep2WaterTest()
                      : _buildStep3VisualCheck(),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 0: Type & Volume + Last Drain
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep0TypeVolume() {
    final volumes = _waterType == 'hot_tub' ? _htVolumes : _poolVolumes;
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('What are we testing?'),
        SizedBox(height: 8.h),
        Row(children: [
          Expanded(child: _typeCard('hot_tub', '♨️', 'Hot Tub / Spa', 'Bromine or Chlorine')),
          SizedBox(width: 10.w),
          Expanded(child: _typeCard('pool', '🏊', 'Pool', 'Chlorine or Salt')),
        ]),
        SizedBox(height: 20.h),
        _sectionLabel('How big is it?'),
        SizedBox(height: 4.h),
        _infoBox('Volume determines product SIZE — bigger ${_waterType == "hot_tub" ? "spa" : "pool"} = bigger containers'),
        SizedBox(height: 8.h),
        ...volumes.map((v) => _volumeCard(v)),
        _customVolumeCard(),
        SizedBox(height: 20.h),
        _sectionLabel('Last drain?'),
        SizedBox(height: 8.h),
        Wrap(spacing: 8.w, runSpacing: 8.h, children: [
          _drainChip('under_3mo', '< 3 months'),
          _drainChip('3to6mo', '3-6 months'),
          _drainChip('6to12mo', '6-12 months'),
          _drainChip('over_1yr', '> 1 year', isWarning: true),
          if (_waterType == 'pool')
            _drainChip('never', 'Never / Not sure', isWarning: true, fullWidth: true),
        ]),
        SizedBox(height: 24.h),
        _nextButton('Next → Sanitizer Type',
            enabled: _volumeId != null && _lastDrain != null,
            onTap: () => setState(() => _step = 1)),
        SizedBox(height: 40.h),
      ]),
    );
  }

  Widget _typeCard(String value, String emoji, String label, String desc) {
    final selected = _waterType == value;
    final accent = value == 'hot_tub' ? const Color(0xFF9C2B3A) : const Color(0xFF2C6E7A);
    return GestureDetector(
      onTap: () => setState(() {
        _waterType = value;
        _volumeId = null; _volumeLiters = null; _customVolCtrl.clear();
        _sanitizerType = value == 'hot_tub' ? 'bromine' : 'chlorine';
      }),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.06) : AppColors.cardBgColor,
          border: Border.all(color: selected ? accent : Colors.grey.shade300, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: 28.sp)),
          SizedBox(height: 4.h),
          Text(label, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700, color: selected ? accent : Colors.grey[800])),
          Text(desc, style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _volumeCard(Map<String, dynamic> v) {
    final id = v['id'] as String;
    final selected = _volumeId == id;
    final liters = v['liters'] as int;
    final gallons = (liters / 3.785).round();
    return GestureDetector(
      onTap: () => setState(() { _volumeId = id; _volumeLiters = liters.toDouble(); }),
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4F6) : AppColors.cardBgColor,
          border: Border.all(color: selected ? const Color(0xFF2C6E7A) : Colors.grey.shade300, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v['label'] as String, style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700)),
            Text(v['desc'] as String, style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${_fmtLiters(liters)}L', style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xFF2C6E7A))),
            Text('$gallons gal', style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _customVolumeCard() {
    final selected = _volumeId == 'custom';
    return GestureDetector(
      onTap: () => setState(() => _volumeId = 'custom'),
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8E7) : AppColors.cardBgColor,
          border: Border.all(color: selected ? const Color(0xFFC8A84E) : Colors.grey.shade300, width: selected ? 2 : 1.5),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Custom — exact volume', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700)),
            Text('Enter liters manually', style: GoogleFonts.inter(fontSize: 9.sp, color: Colors.grey)),
          ])),
          if (selected)
            SizedBox(
              width: 100.w, height: 36.h,
              child: TextField(
                controller: _customVolCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Liters', hintStyle: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                  isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                onChanged: (val) => setState(() => _volumeLiters = double.tryParse(val)),
              ),
            )
          else
            Text('✏️', style: TextStyle(fontSize: 20.sp)),
        ]),
      ),
    );
  }

  Widget _drainChip(String value, String label, {bool isWarning = false, bool fullWidth = false}) {
    final selected = _lastDrain == value;
    return GestureDetector(
      onTap: () => setState(() => _lastDrain = value),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? (isWarning ? const Color(0xFFFAEAED) : const Color(0xFFE8F4F6)) : AppColors.cardBgColor,
          border: Border.all(
            color: selected ? (isWarning ? const Color(0xFF9C2B3A) : const Color(0xFF2C6E7A)) : (isWarning ? const Color(0xFF9C2B3A).withOpacity(0.4) : Colors.grey.shade300),
            width: selected ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: isWarning ? const Color(0xFF9C2B3A) : (selected ? const Color(0xFF2C6E7A) : Colors.grey[700]))),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 1: Sanitizer
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep1Sanitizer() {
    final options = _waterType == 'hot_tub'
        ? [
            {'value': 'bromine', 'label': 'Bromine', 'desc': 'Most popular for hot tubs — low odour, stable in warm water'},
            {'value': 'chlorine', 'label': 'Chlorine', 'desc': 'Budget-friendly — available as tablets or granules'},
          ]
        : [
            {'value': 'chlorine', 'label': 'Chlorine', 'desc': 'Standard pool sanitizer — tablets in skimmer or floater'},
            {'value': 'salt', 'label': 'Salt System', 'desc': 'Salt chlorine generator — still needs monitoring'},
          ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('Sanitizer Type'),
        SizedBox(height: 4.h),
        Text('Determines which products AutoCrate can recommend', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 14.h),
        ...options.map((opt) {
          final val = opt['value'] as String;
          final selected = _sanitizerType == val;
          return GestureDetector(
            onTap: () => setState(() => _sanitizerType = val),
            child: Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFE8F4F6) : AppColors.cardBgColor,
                border: Border.all(color: selected ? const Color(0xFF2C6E7A) : Colors.grey.shade300, width: selected ? 2 : 1.5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${selected ? "✓ " : ""}${opt['label']}',
                    style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w700, color: selected ? const Color(0xFF2C6E7A) : Colors.grey[800])),
                SizedBox(height: 4.h),
                Text(opt['desc'] as String, style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey)),
              ]),
            ),
          );
        }),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: () => setState(() => _step = 0),
          child: Text('← Back', style: GoogleFonts.inter(fontSize: 12.sp, color: const Color(0xFF2C6E7A), fontWeight: FontWeight.w600)),
        ),
        SizedBox(height: 20.h),
        _nextButton('Next → Water Test Values', onTap: () => setState(() => _step = 2)),
        SizedBox(height: 40.h),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 2: Water Test Values (2-col grid per blueprint)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep2WaterTest() {
    // All possible params
    final allParams = <Map<String, String>>[
      {'key': 'pH', 'label': 'pH'},
      {'key': 'alkalinity', 'label': 'Alkalinity'},
      {'key': 'hardness', 'label': 'Calcium'},
      {'key': 'bromine', 'label': 'Bromine'},
      {'key': 'freeChlorine', 'label': 'Free Chlorine'},
      {'key': 'totalChlorine', 'label': 'Total Chlorine'},
      {'key': 'copper', 'label': 'Copper'},
      {'key': 'iron', 'label': 'Iron'},
      {'key': 'cyanuricAcid', 'label': 'CYA'},
      {'key': 'phosphate', 'label': 'Phosphate'},
      {'key': 'salt', 'label': 'Salt'},
    ];

    // Blueprint conditional fields logic:
    // Bromine sanitizer → show Bromine, hide Free Chlorine
    // Non-Bromine      → show Free Chlorine, hide Bromine
    // Pool (any)       → show CYA
    // Pool + Salt      → show Salt
    // Hot Tub          → hide CYA, hide Salt
    final visibleParams = allParams.where((p) {
      final key = p['key']!;
      if (key == 'bromine' && _sanitizerType != 'bromine') return false;
      if (key == 'freeChlorine' && _sanitizerType == 'bromine') return false;
      if (key == 'cyanuricAcid' && _waterType == 'hot_tub') return false;
      if (key == 'salt' && _sanitizerType != 'salt') return false;
      return true;
    }).toList();
    final orc = _outOfRangeCount;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(color: const Color(0xFFE8F4F6), borderRadius: BorderRadius.circular(8.r)),
          child: Row(children: [
            Icon(Icons.info_outline, size: 14.sp, color: const Color(0xFF2C6E7A)),
            SizedBox(width: 6.w),
            Expanded(child: Text(
              'Ideal ranges shown for ${_poolType == "hottub" ? "hot tub" : "pool"}. Red border = out of range.',
              style: GoogleFonts.inter(fontSize: 10.sp, color: const Color(0xFF2C6E7A), fontWeight: FontWeight.w600),
            )),
          ]),
        ),
        SizedBox(height: 10.h),

        // 2-column grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 8.w, mainAxisSpacing: 8.h, childAspectRatio: 1.8,
          ),
          itemCount: visibleParams.length,
          itemBuilder: (ctx, idx) {
            final p = visibleParams[idx];
            final key = p['key']!;
            final label = p['label']!;
            final status = _getStatus(key);
            final isPending = status == WtStatus.pending; // no value yet
            final isOut = status == WtStatus.low || status == WtStatus.high;
            final range = _rangeText(key);
            Color bc = Colors.grey.shade300;
            if (isOut) bc = const Color(0xFF9C2B3A).withOpacity(0.5);

            return Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                border: Border.all(color: bc, width: isOut ? 2 : 1.5),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('$label $range',
                      style: GoogleFonts.inter(fontSize: 9.sp, fontWeight: FontWeight.w700,
                          color: isOut ? const Color(0xFF9C2B3A) : const Color(0xFF1A2A3A)),
                      maxLines: 2, overflow: TextOverflow.ellipsis)),
                  if (!isPending) WtPill(status),
                ]),
                SizedBox(height: 4.h),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgColor,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: TextField(
                      controller: _ctrls[key],
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.jetBrainsMono(fontSize: 16.sp, fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A2A3A)),
                      decoration: InputDecoration(
                        hintText: '- -',
                        hintStyle: GoogleFonts.jetBrainsMono(fontSize: 14.sp, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),

        SizedBox(height: 10.h),
        if (orc > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(color: const Color(0xFFFAEAED), borderRadius: BorderRadius.circular(8.r)),
            child: Row(children: [
              Text('⚠️', style: TextStyle(fontSize: 12.sp)),
              SizedBox(width: 6.w),
              Text('$orc out of range',
                  style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xFF9C2B3A))),
            ]),
          ),

        SizedBox(height: 16.h),
        Row(children: [
          Expanded(child: _backBlock(() => setState(() => _step = 1))),
          SizedBox(width: 8.w),
          Expanded(flex: 2, child: _nextButton('Next → Visual Check', onTap: () => setState(() => _step = 3), height: 46.h)),
        ]),
        SizedBox(height: 40.h),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // STEP 3: Visual Observations
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStep3VisualCheck() {
    final isPool = _waterType == 'pool';
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('What does the water look like?'),
        SizedBox(height: 4.h),
        Text('Select all that apply', style: GoogleFonts.inter(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 12.h),
        _visualToggle('🫧', 'Foam on Surface', 'Triggers: Defoamer + Zorbie', _foam, (v) => setState(() => _foam = v)),
        _visualToggle('☁️', 'Cloudy Water', isPool ? 'Triggers: Quick Clear' : 'Triggers: Spa Shock', _cloudy, (v) => setState(() => _cloudy = v)),
        if (isPool) _visualToggle('🟢', 'Green Tint (Algae)', 'Pool only — Kill Algae + Shock 65%', _algae, (v) => setState(() => _algae = v)),
        _visualToggle('🔧', 'Filter Dirty', 'Triggers: Cartridge Cleaner', _filterDirty, (v) => setState(() => _filterDirty = v)),
        _visualToggle('🚿', 'Needs Flush / Drain', 'Triggers: Flush + Pre-Filter', _flush, (v) => setState(() => _flush = v)),
        _visualToggle('⚖️', 'Scale Buildup', isPool ? 'Triggers: Stain Preventer' : 'Triggers: Stain&Scale + Cover Cleaner', _scale, (v) => setState(() => _scale = v)),
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity, height: 52.h,
          child: ElevatedButton(
            onPressed: _generateCrate,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3A7D44), foregroundColor: Colors.white,
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            ),
            child: Text('Generate AutoCrate →', style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800)),
          ),
        ),
        SizedBox(height: 40.h),
      ]),
    );
  }

  Widget _visualToggle(String emoji, String label, String desc, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: value ? const Color(0xFFFAEAED) : AppColors.cardBgColor,
          border: Border.all(color: value ? const Color(0xFF9C2B3A) : Colors.grey.shade300, width: value ? 2 : 1.5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$emoji $label', style: GoogleFonts.inter(fontSize: 12.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 2.h),
          Text(desc, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text) => Text(text, style: GoogleFonts.inter(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFF5E1A25)));

  Widget _infoBox(String text) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E7), borderRadius: BorderRadius.circular(8.r)),
    child: Text(text, style: GoogleFonts.inter(fontSize: 10.sp, color: Colors.grey[600])),
  );

  Widget _nextButton(String text, {VoidCallback? onTap, bool enabled = true, double? height}) {
    return SizedBox(
      width: double.infinity, height: height ?? 52.h,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2C6E7A),
          disabledBackgroundColor: const Color(0xFF2C6E7A).withOpacity(0.4),
          foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        child: Text(text, style: GoogleFonts.inter(fontSize: 14.sp, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _backBlock(VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 46.h,
      decoration: BoxDecoration(color: AppColors.cardBgColor, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10.r)),
      child: Center(child: Text('← Back', style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey[600]))),
    ),
  );

  String _fmtLiters(int l) {
    if (l >= 1000) {
      final s = l.toString();
      final buf = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
        buf.write(s[i]);
      }
      return buf.toString();
    }
    return '$l';
  }
}
