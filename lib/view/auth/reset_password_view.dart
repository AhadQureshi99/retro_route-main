import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:retro_route/components/custom_button.dart';
import 'package:retro_route/components/custom_spacer.dart';
import 'package:retro_route/components/custom_text.dart';
import 'package:retro_route/components/custom_textfield.dart';
import 'package:retro_route/utils/app_colors.dart';
import 'package:retro_route/utils/app_routes.dart';
import 'package:retro_route/utils/app_toast.dart';
import 'package:retro_route/view_model/auth_view_model/forgotpassword_view_model.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forgotState = ref.watch(forgotPasswordProvider);
    final isLoading = forgotState.isLoading;

    ref.listen(forgotPasswordProvider, (prev, next) {
      next.whenOrNull(
        data: (res) {
          if (res != null && res.success) {
            CustomToast.success(msg: 'Password reset successful!');
            goRouter.go(AppRoutes.login);
            ref.read(forgotPasswordProvider.notifier).resetState();
          }
        },
        error: (err, _) {
          CustomToast.error(msg: err.toString());
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                verticalSpacer(height: 40),
                customText(
                  text: "Reset Password",
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                verticalSpacer(height: 12),
                customText(
                  text: "Create a strong new password",
                  fontSize: 16,
                  color: Colors.grey[700]!, fontWeight: FontWeight.w600,
                ),
                verticalSpacer(height: 50),

                CustomTextField(
                  controller: _newPassController,
                  hintText: "New Password",
                  obscureText: _obscureNew,
                  isPasswordField: true,
                  
                 onSuffixTap: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.length < 6) return "Min 6 characters";
                    return null;
                  }, width: 1.sw,
                ),

                verticalSpacer(height: 20),

                CustomTextField(
                  controller: _confirmPassController,
                  hintText: "Confirm Password",
                  obscureText: _obscureConfirm,
                  isPasswordField: true,
                  onSuffixTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _newPassController.text) return "Passwords don't match";
                    return null;
                  }, width: 1.sw,
                ),

                verticalSpacer(height: 40),
  customButton(
                context: context,
                text: "Reset Password",
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontColor: Colors.white,
                bgColor: AppColors.primary ?? Colors.deepPurple,
                borderRadius: 16,
                height: 56.h,
                width: double.infinity,
               isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            ref.read(forgotPasswordProvider.notifier).resetPassword(
                                  widget.email,
                                  _newPassController.text,
                                  _confirmPassController.text,
                                );
                          }
                        }, 
                borderColor: AppColors.black,
                isCircular: false,
              ),
               
              ],
            ),
          ),
        ),
      ),
    );
  }
}