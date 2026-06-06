import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy hh:mm a');

  static String formatCurrency(double amount) {
    return _inrFormatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }
}
