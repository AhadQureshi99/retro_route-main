import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Holds the delivery date the user explicitly chose in the Milk Run dialog.
/// When non-null, checkout uses this instead of auto-computing from the zone.
final selectedDeliveryDateProvider = StateProvider<DateTime?>((ref) => null);
