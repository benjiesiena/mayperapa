import "package:intl/intl.dart";

/// Formats amounts using the user's chosen currency. Centralized so every
/// screen and AI tool response renders money identically.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Default currency code across the app. Updated by settingsProvider when user changes preference.
  static String defaultCurrency = "PHP";

  static String format(double amount, {String? currencyCode, String? locale}) {
    final code = currencyCode ?? defaultCurrency;
    final loc = locale ?? localeFor(code);
    final symbol = symbolFor(code);
    final formatter = NumberFormat.currency(locale: loc, symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  /// Compact form for charts / small UI, e.g. "20.4K" instead of "20,420.00".
  static String formatCompact(double amount, {String? currencyCode}) {
    final code = currencyCode ?? defaultCurrency;
    final symbol = symbolFor(code);
    final formatter = NumberFormat.compactCurrency(symbol: symbol, decimalDigits: 1);
    return formatter.format(amount);
  }

  static String symbolFor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case "PHP":
        return "\u20b1";
      case "USD":
        return "\$";
      case "EUR":
        return "\u20ac";
      case "JPY":
        return "\u00a5";
      case "GBP":
        return "\u00a3";
      default:
        return currencyCode;
    }
  }

  static String localeFor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case "PHP":
        return "en_PH";
      case "USD":
        return "en_US";
      case "EUR":
        return "de_DE";
      case "JPY":
        return "ja_JP";
      case "GBP":
        return "en_GB";
      default:
        return "en_US";
    }
  }
}
