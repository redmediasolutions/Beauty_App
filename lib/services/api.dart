import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:glowfit/models/categorymodel.dart';
import 'package:glowfit/models/product_detail.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/models/singleorder.dart';
import 'package:glowfit/services/config.dart';
import 'package:http/http.dart' as http;

class APIService {
  static final client = http.Client();

  static Map<String, String> getHeaders() {
    final basicAuth =
        'Basic ${base64Encode(utf8.encode("${Config.consumerKey}:${Config.consumerSecret}"))}';

    return {'Content-Type': 'application/json', 'Authorization': basicAuth};
  }

  static Map<String, String> getPublicHeaders() {
    return {'Content-Type': 'application/json'};
  }
//======================= FETCH PRODUCTS BY CATEGORY FUNCTION =======================
static Future<List<Productsmodel>> fetchProductsByCategory({
  required String categoryId,
  int page = 1,
  int perPage = 10,
}) async {
  final queryParams = {
    'category': categoryId,
    'page': page.toString(),
    'per_page': perPage.toString(),
    'status': 'publish',
  };

  final queryString = Uri(queryParameters: queryParams).query;
  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}${Config.productsURL}?$queryString";

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      /// ✅ FILTER: ONLY CATEGORY 41
      final filtered = list.where((e) {
        final categories = e['categories'] as List?;
        if (categories == null) return false;

        return categories.any((c) => c['id'] == 41);
      }).toList();

      return filtered.map((e) => Productsmodel.fromJson(e)).toList();
    }
  } catch (_) {}

  return [];
}

//======================= FETCH PRODUCTS FUNCTION =======================
  static Future<List<Productsmodel>> fetchProducts({
  int page = 1,
  int perPage = 100,
  int? categoryId,
  String? search,
}) async {
  final queryParams = {
    'page': page.toString(),
    'per_page': perPage.toString(),
    'orderby': 'date',
    'order': 'desc',
    if (search != null && search.isNotEmpty) 'search': search,
    if (categoryId != null) 'category': categoryId.toString(),
  };

  final queryString = Uri(queryParameters: queryParams).query;

  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}${Config.productsURL}?$queryString";

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      return list.map((e) => Productsmodel.fromJson(e)).toList();
    }
  } catch (_) {}

  return [];
}

//======================= FETCH SINGLE PRODUCT DETAIL FUNCTION =======================
static Future<ProductDetail?> fetchSingleProductDetail(
  String productId,
) async {
  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}${Config.productsURL}/$productId";

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      /// ✅ FILTER: ONLY CATEGORY 41
      final categories = json['categories'] as List?;
      final isAllowed = categories != null &&
          categories.any((c) => c['id'] == 49);

      if (!isAllowed) return null; // ❌ BLOCK PRODUCT

      return ProductDetail.fromJson(json);
    }
  } catch (_) {}

  return null;
}

///======================= FETCH PRODUCTS BY IDS FUNCTION =======================
static Future<List<Productsmodel>> fetchProductsByIds(
  List<int> productIds,
) async {
  if (productIds.isEmpty) return [];

  final queryParams = {
    'include': productIds.join(','),
    'per_page': productIds.length.toString(),
  };

  final queryString = Uri(queryParameters: queryParams).query;

  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}${Config.productsURL}?$queryString";

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      /// ✅ FILTER: ONLY CATEGORY 41
      final filtered = list.where((e) {
        final categories = e['categories'] as List?;
        if (categories == null) return false;

        return categories.any((c) => c['id'] == 41);
      }).toList();

      return filtered.map((e) => Productsmodel.fromJson(e)).toList();
    }
  } catch (_) {}

  return [];
}

//======================= SEARCH FUNCTION =======================
Future<List<Productsmodel>> searchProducts(String query) async {
  // ✅ Prevent unnecessary API calls
  if (query.trim().isEmpty) {
    return [];
  }

  final uri = Uri.https(
    "gs.redmediasolutions.in",
    "/wp-json/gladskin/v1/search",
    {"search": query},
  );

  try {
    debugPrint("🔍 Searching: $query");

    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 10)); // ✅ timeout added

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // ✅ Validate structure
      if (decoded is Map && decoded["status"] == 200) {
        final List data = decoded["data"] ?? [];

        return data
            .map((item) => Productsmodel.fromJson(item))
            .toList();
      } else {
        debugPrint("⚠️ Invalid API structure");
      }
    } else {
      debugPrint("❌ API Error: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("❌ Search Exception: $e");
  }

  return []; // ✅ safe fallback
}

static Future<SingleOrder?> fetchSingleOrder(
  int orderId,
) async {
  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}orders/$orderId";

  debugPrint('🌐 [API] GET $requestUrl');

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> json =
          jsonDecode(response.body) as Map<String, dynamic>;

      return SingleOrder.fromJson(json);
    } else {
      debugPrint(
          '❌ [API] Failed to fetch order $orderId → ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('🚨 [API] fetchSingleOrder error: $e');
  }

  return null;
}

static Future<bool> cancelOrder(int orderId) async {
  final url =
      "${Config.baseUrl}${Config.apiPath}${Config.ordersURL}/$orderId";

  debugPrint('🚫 [API] Cancelling order → $orderId');

  final body = {
    "status": "cancelled",
  };

  try {
    final response = await client.put(
      Uri.parse(url),
      headers: getHeaders(),
      body: jsonEncode(body),
    );

    debugPrint('📡 [API] Cancel response: ${response.statusCode}');
    debugPrint('📦 [API] Body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('✅ [API] Order cancelled successfully');
      return true;
    } else {
      debugPrint('❌ [API] Cancel failed');
    }
  } catch (e) {
    debugPrint('🚨 [API] cancelOrder error: $e');
  }

  return false;
}

static Future<List<SingleOrder>> fetchOrdersByIds(
  List<int> orderIds,
) async {
  if (orderIds.isEmpty) return [];

  final ids = orderIds.join(',');

  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}orders?include=$ids&per_page=${orderIds.length}";

  debugPrint('🌐 [API] Fetching Woo orders with include=$ids');
  debugPrint('🔗 [API] URL: $requestUrl');

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    debugPrint('📡 [API] Status code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      debugPrint('✅ [API] Orders returned from Woo: ${list.length}');

      return list.map((e) => SingleOrder.fromJson(e)).toList();
    } else {
      debugPrint(
        '❌ [API] Failed to fetch orders. '
        'Status: ${response.statusCode} '
        'Body: ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('🚨 [API] fetchOrdersByIds error: $e');
  }

  return [];
}

static bool _isAllowedProduct(Map<String, dynamic> json) {
  final categories = json['categories'] as List?;
  if (categories == null) return false;

  return categories.any((c) => c['id'] == 41);
}


//======================= FETCH CATEGORIES BY IDS =======================
static Future<List<CategoryModel>> fetchCategoriesByIds(
  List<int> ids,
) async {
  if (ids.isEmpty) return [];

  final queryParams = {
    'include': ids.join(','),
    'per_page': ids.length.toString(),
    'hide_empty': 'true',
  };

  final queryString = Uri(queryParameters: queryParams).query;

  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}products/categories?$queryString";

  debugPrint('🌐 [API] Fetch Categories → $requestUrl');

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      return list.map((e) => CategoryModel.fromJson(e)).toList();
    } else {
      debugPrint(
        '❌ [API] Category fetch failed: ${response.statusCode}',
      );
    }
  } catch (e) {
    debugPrint('🚨 [API] fetchCategoriesByIds error: $e');
  }

  return [];
}


//======================= FETCH SUBCATEGORIES =======================
static Future<List<CategoryModel>> fetchSubCategories(
  int parentId,
) async {
  final queryParams = {
    'parent': parentId.toString(),
    'per_page': '50',
    'hide_empty': 'true',
  };

  final queryString = Uri(queryParameters: queryParams).query;

  final requestUrl =
      "${Config.baseUrl}${Config.apiPath}products/categories?$queryString";

  debugPrint('🌐 [API] Fetch Subcategories → $requestUrl');

  try {
    final response = await client.get(
      Uri.parse(requestUrl),
      headers: getHeaders(),
    );

    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);

      return list.map((e) => CategoryModel.fromJson(e)).toList();
    }
  } catch (e) {
    debugPrint('🚨 [API] fetchSubCategories error: $e');
  }

  return [];
}
}