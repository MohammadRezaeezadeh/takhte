import 'package:haftnard/meta/cosmetics.dart';
import 'package:haftnard/meta/meta_state.dart';

/// Purchase seam. v1 only spends earned soft currency; a real store (Google
/// Play Billing) can implement this interface later without touching the UI.
abstract interface class PurchaseProvider {
  Future<bool> purchase(
    MetaNotifier meta,
    CosmeticItem item, {
    int? priceOverride,
  });
}

class SoftCurrencyPurchaseProvider implements PurchaseProvider {
  const SoftCurrencyPurchaseProvider();
  @override
  Future<bool> purchase(
    MetaNotifier meta,
    CosmeticItem item, {
    int? priceOverride,
  }) async => meta.buy(item, priceOverride: priceOverride);
}

abstract final class PurchaseProviders {
  static PurchaseProvider current = const SoftCurrencyPurchaseProvider();
}
