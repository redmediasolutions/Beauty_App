import 'package:flutter/material.dart';
import 'package:glowfit/pages/cart/processingcartpage.dart';
import 'package:glowfit/pages/orderspage/orderdetails.dart';
import 'package:glowfit/pages/orderspage/orderfailed.dart';
import 'package:glowfit/pages/orderspage/processingpage.dart';
import 'package:glowfit/pages/ordersucessscreen.dart';
import 'package:glowfit/pages/profile/orderlist.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:glowfit/Auth/mobilelogin.dart';
import 'package:glowfit/pages/Home/home.dart';
import 'package:glowfit/pages/splashscreen/splashscreen.dart';
import 'package:glowfit/pages/cart/cart_Page.dart';
import 'package:glowfit/pages/address/address.dart';
import 'package:glowfit/pages/profile/profile.dart';
import 'package:glowfit/pages/Search/searchPage.dart';
import 'package:glowfit/pages/AllProducts/all_products.dart';
import 'package:glowfit/pages/profile/account/editprofile.dart';
import 'package:glowfit/pages/profile/account/loyalitypoints.dart';
import 'package:glowfit/pages/single_product/SingleProduct.dart';
import 'package:glowfit/shell.dart';
import 'authcheck.dart';

class AppRouter {
  static final AuthStateNotifier authStateNotifier = AuthStateNotifier();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',

    /// 🔥 This makes router reactive to auth
    refreshListenable: authStateNotifier,

    /// 🔥 AUTH REDIRECT (FIXED)
    redirect: (context, state) {
      final bool isInitialized = authStateNotifier.isInitialized;
      final User? user = authStateNotifier.user;

      final String location = state.matchedLocation;

      final bool isLogin = location == '/login';
      final bool isSplash = location == '/splash';

      /// 1. Wait for Firebase to restore session
      if (!isInitialized) {
        return isSplash ? null : '/splash';
      }

      /// 2. If not logged in → only allow login
      if (user == null) {
        return isLogin ? null : '/login';
      }

      /// 3. If logged in → prevent going back to login/splash
      if (isLogin || isSplash) {
        return '/';
      }

      /// 4. Allow everything else
      return null;
    },

    routes: [
      /// 🌿 SPLASH
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      /// 🔐 LOGIN
      GoRoute(
        path: '/login',
        builder: (context, state) => const MobileLogin(),
      ),

      /// 🧾 PRODUCT (outside shell)
      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          if (id == null || id.isEmpty) {
            return const Scaffold(
              body: Center(child: Text("Invalid product ID")),
            );
          }
          return ProductsView(productId: id);
        },
      ),
      GoRoute(
  path: '/ordersuccess',
  name: 'ordersuccess',
  builder: (context, state) {
    final orderId = state.extra as String?;
    return SuccessSplashScreen(orderId: orderId);
  },
),

GoRoute(
  path: '/orderfailed',
  name: 'orderFailed',
  builder: (context, state) {
    final msg = state.extra as String?;
    return OrderFailedScreen(message: msg);
  },
),
GoRoute(

  path: '/processingpayment',

  builder: (context, state) =>

      const ProcessingPaymentPage(),

),

GoRoute(
  path: '/order/:id', // ✅ MUST match this format
  name: 'orderDetail',
  builder: (context, state) {
    final id = state.pathParameters['id'];

    return OrderDetailWidget(
      orderId: int.tryParse(id ?? ''),
    );
  },
),

GoRoute(
  path: '/orders',
  name: 'orders',
  builder: (context, state) => const OrdersPage(),
),

GoRoute(
  path: '/processing-order',
  builder: (context, state) =>
      const ProcessingOrderScreen(),
),
      /// 🛒 CART
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartPage(),
      ),

      /// 📍 ADDRESS
      GoRoute(
        path: '/address',
        builder: (context, state) => const AddressPage(),
      ),

      /// ✏️ EDIT PROFILE
      GoRoute(
        path: '/editprofile',
        builder: (context, state) => const Editprofile(),
      ),

      /// 🎁 POINTS
      GoRoute(
        path: '/points',
        builder: (context, state) => const LoyaltyPointsPage(),
      ),

      /// 📱 MAIN APP (BOTTOM NAV)
      ShellRoute(
        builder: (context, state, child) {
          return ShellPage(
            cartCount: 0,
            child: child,
          );
        },
        routes: [
          /// 🏠 HOME
          GoRoute(
            path: '/',
            builder: (context, state) {
              final int categoryId =
                  (state.extra is int) ? state.extra as int : 0;

              return Homepage(categoryId: categoryId.toString());
            },
          ),

          /// 🛍 ALL PRODUCTS
          GoRoute(
            path: '/AllProducts',
            builder: (context, state) => const AllProducts(),
          ),

          /// 🔍 SEARCH
          GoRoute(
            path: '/search',
            builder: (context, state) => const Searchpage(),
          ),

          GoRoute(
            path: '/profile',
            builder: (context, state) => const Profile(),
          ),
        ],
      ),
    ],
  );
}