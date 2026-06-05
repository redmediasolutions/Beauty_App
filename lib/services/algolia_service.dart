import 'package:algoliasearch/algoliasearch.dart';

class AlgoliaService {

  static const String appId =
      'U50GIUJMNN';

  static const String apiKey =
      'cfc0d2e5c91c0de8a315463fe219b236';

  static const String productsIndex =
      'products';

  static final SearchClient client =
      SearchClient(
    appId: appId,
    apiKey: apiKey,
  );

  static Future<List<Map<String, dynamic>>>
    searchProducts(
  String query,
) async {

  if (query.trim().isEmpty) {
    return [];
  }

  try {

    final response =
        await client.search(
      searchMethodParams:
          SearchMethodParams(
        requests: [

          SearchForHits(
            indexName:
                productsIndex,

            query: query,

            hitsPerPage: 20,
          ),
        ],
      ),
    );

    // =====================================
    // EXTRACT RESULTS SAFELY
    // =====================================

    final results =
        response.toJson()['results']
            as List;

    if (results.isEmpty) {
      return [];
    }

    final firstResult =
        results.first
            as Map<String, dynamic>;

    final hits =
        firstResult['hits']
            as List;

    return hits
        .map(
          (e) => Map<String, dynamic>.from(e),
        )
        .toList();

  } catch (e) {

    print(
      'Algolia search error: $e',
    );

    return [];
  }
}
}