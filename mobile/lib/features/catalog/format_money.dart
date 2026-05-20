/// Formate un prix avec espace comme séparateur de milliers : 5000 → "5 000".
String formatMoney(num amount, String currency) {
  final whole = amount.toInt();
  final str = whole.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '$buffer $currency';
}
