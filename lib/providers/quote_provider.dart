import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:assignments/services/quote_service.dart';

final quoteServiceProvider = Provider<QuoteService>((ref) => QuoteService());

class QuoteNotifier extends StateNotifier<AsyncValue<Quote>> {
  final QuoteService _quoteService;

  QuoteNotifier(this._quoteService) : super(const AsyncValue.loading()) {
    fetchQuote();
  }

  Future<void> fetchQuote() async {
    state = const AsyncValue.loading();
    try {
      final quote = await _quoteService.getRandomQuote();
      state = AsyncValue.data(quote);
    } catch (e) {
      debugPrint('[QuoteNotifier] Error fetching quote, using fallback: $e');
      // On error, we provide the fallback quote but still keep the error context
      // available if needed. However, to satisfy "No blank UI", we emit data with fallback.
      state = const AsyncValue.data(QuoteService.fallbackQuote);
    }
  }

  Future<void> refresh() async {
    await fetchQuote();
  }
}

final quoteNotifierProvider =
    StateNotifierProvider<QuoteNotifier, AsyncValue<Quote>>((ref) {
      final quoteService = ref.watch(quoteServiceProvider);
      return QuoteNotifier(quoteService);
    });
