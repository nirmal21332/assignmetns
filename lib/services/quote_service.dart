import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class QuoteService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  static const String _baseUrl = 'https://dummyjson.com/quotes';

  /// Fallback quote in case of network errors.
  static const Quote fallbackQuote = Quote(
    quote: 'Stay consistent and keep learning.',
    author: 'Nirmal Sharma',
  );

  Future<Quote> getRandomQuote() async {
    debugPrint('[QuoteService] Fetching quotes from $_baseUrl');
    try {
      final response = await _dio.get(_baseUrl);

      if (response.statusCode == 200) {
        final List<dynamic> quotesList = response.data['quotes'];
        if (quotesList.isEmpty) {
          throw Exception('Received empty quotes list');
        }

        // Select a random quote from the list
        final randomIndex = Random().nextInt(quotesList.length);
        final selectedQuote = Quote.fromJson(quotesList[randomIndex]);

        debugPrint(
          '[QuoteService] Successfully fetched quote: "${selectedQuote.quote}"',
        );
        return selectedQuote;
      } else {
        throw Exception('Failed to load quotes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[QuoteService] DioException: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Using fallback.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Using fallback.');
      } else {
        throw Exception('Failed to load quote. Using fallback.');
      }
    } catch (e) {
      debugPrint('[QuoteService] Unexpected error: $e');
      return fallbackQuote;
    }
  }
}

class Quote {
  final String quote;
  final String author;

  const Quote({required this.quote, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      quote: json['quote'] ?? 'Keep moving forward.',
      author: json['author'] ?? 'Unknown',
    );
  }
}
