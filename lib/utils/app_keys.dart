
import 'package:flutter/material.dart';

final GlobalKey<PopupMenuButtonState<String>> popupMenuKey =
    GlobalKey<PopupMenuButtonState<String>>();

final GlobalKey<PopupMenuButtonState<String>> popupMenuKey2 =
    GlobalKey<PopupMenuButtonState<String>>();

 final GlobalKey<ScaffoldState> scaffoldInternalScreenKey = GlobalKey<ScaffoldState>();
 final GlobalKey<ScaffoldState> scaffoldInternalSecondScreenKey = GlobalKey<ScaffoldState>();
 // ADD THIS: Form key for validation
  final GlobalKey<FormState> formRegisterKey = GlobalKey<FormState>();
  final GlobalKey<FormState> formloginKey = GlobalKey<FormState>();