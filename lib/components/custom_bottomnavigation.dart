// // components/custom_bottom_navigation.dart

// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:retro_route/utils/app_colors.dart';
// import 'package:retro_route/view/cart/cart_view.dart';
// import 'package:retro_route/view/dashboard/dashboard_view.dart';
// import 'package:retro_route/view/favourite/favourite_view.dart';
// import 'package:retro_route/view/profile/profile_view.dart';
// import 'package:retro_route/view/search/search_view.dart';

// class CustomBottomNavigation extends StatefulWidget {
//   const CustomBottomNavigation({super.key});

//   @override
//   State<CustomBottomNavigation> createState() => _CustomBottomNavigationState();
// }

// class _CustomBottomNavigationState extends State<CustomBottomNavigation> {
//   int selectedIndex = 0;
//   final List<Widget> _screens = [
//     const HomeDashboardScreen(),
//     const SearchScreen(),
//     const FavouriteScreen(),
//     const CartScreen(),
//     const ProfileScreen(),
//     // const SearchScreen(),       // You can create a dedicated search screen
//     // const FavouriteScreen(),
//     // const CartScreen(),
//     // const ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       extendBody: true,
//       bottomNavigationBar: CurvedNavigationBar(

//         index: selectedIndex,
//         backgroundColor: Colors.transparent,
//         color: AppColors.primary ?? Colors.deepPurple,
//         animationDuration: const Duration(milliseconds: 600),
//         animationCurve: Curves.easeInOut,
//         height: 50,

//         onTap: (index) {
//           setState(() {
//             selectedIndex = index;
//           });
//         },
//         items: [
//           const Icon(Icons.home, size: 30,color: Colors.white,),
//           const Icon(Icons.search, size: 30,color: Colors.white),
//           const Icon(Icons.favorite_outline, size: 30,color: Colors.white),
//           Icon(Icons.shopping_cart_outlined, size: 30,color: Colors.white),
//           const Icon(Icons.person, size: 30,color: Colors.white),
//         ],
//       ),
//       body: _screens[selectedIndex],
//     );
//   }
// }
