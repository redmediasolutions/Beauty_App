

import 'dart:async';

class Config {
  // Your WooCommerce REST API Keys
  static const String consumerKey = "ck_1f90c93d45a4593f00f89ba5c942001e13898e09";
  static const String consumerSecret = "cs_1c4ddd44c08c3399ecbca3e6e16f1234274ae392";

  // Base API URL
  static const String baseUrl = "https://store.gladskin.in";
  print(baseUrl) {
    // TODO: implement print
    throw UnimplementedError();
  }

  // WooCommerce API Endpoint
  static const String apiPath = "/wp-json/wc/v3/";
  static const String url = "https://store.gladskin.in";
  

  // Endpoints
  static const String categoriesURL = "products/categories";
  static const String productsURL = "products";
  static const String searchURL = "products";
  static const String ordersURL = "orders";
  
}