import 'package:flutter/material.dart';
import 'package:retro_route/utils/app_colors.dart';


class CustomCheckBox extends StatefulWidget {
   final bool value;
  final ValueChanged<bool?>? onChanged;

  const CustomCheckBox({
    super.key,
    required this.value,
    this.onChanged,
  });
  @override
  State<CustomCheckBox> createState() => _CustomCheckBoxState();
}

class _CustomCheckBoxState extends State<CustomCheckBox> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.8,
      child: Checkbox(
        value: _value,
        onChanged: (newValue) {
          setState(() {
            _value = newValue ?? false;
          });
          widget.onChanged?.call(newValue);
        },
        checkColor: AppColors.black,
        visualDensity: VisualDensity.compact,
        
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white; // color when checked
          }
          return Colors.transparent; // color when unchecked
        }),
        side: WidgetStateBorderSide.resolveWith((states) {
          return BorderSide(
            color: states.contains(WidgetState.selected)
                ? AppColors.black
                : AppColors.black,
            width: 1,
          );
        }),
      ),
    );
  }
}
