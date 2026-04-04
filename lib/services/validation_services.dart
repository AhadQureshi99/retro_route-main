

import 'package:flutter/material.dart';

class ValidationService {
  // Private constructor for singleton (optional but recommended)
  ValidationService._();
  static final ValidationService instance = ValidationService._();

  // Username Validation
  String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.contains(' ')) {
      return 'No spaces allowed in username';
    }
    if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(value)) {
      return 'Only letters, numbers, dot & underscore allowed';
    }
    return null;
  }

  // Email Validation
  String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Password Validation
  String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 8 characters';
    }
    // if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
    //   return 'Password must contain at least 1 uppercase letter';
    // }
    // if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
    //   return 'Password must contain at least 1 number';
    // }
    return null;
  }

  // Confirm Password (needs access to original password)
  String? confirmPassword(String? value, TextEditingController passwordController) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Phone number (bonus)
  String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10,15}$').hasMatch(value.replaceAll(' ', ''))) {
      return 'Enter a valid phone number';
    }
    return null;
  }
}