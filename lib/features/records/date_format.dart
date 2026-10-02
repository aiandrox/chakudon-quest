import 'package:intl/intl.dart';

final _dateTime = DateFormat('yyyy/M/d HH:mm');
final _date = DateFormat('yyyy/M/d');

String formatDateTime(DateTime value) => _dateTime.format(value);

String formatDate(DateTime value) => _date.format(value);
