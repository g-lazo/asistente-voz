const _shortDays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _longDays = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];
const _shortMonths = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic', //
];
const _longMonths = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "vie 20 nov". DateTime.weekday is 1 (Monday) to 7 (Sunday).
String shortDateLabel(DateTime d) =>
    '${_shortDays[d.weekday - 1]} ${d.day} ${_shortMonths[d.month - 1]}';

/// "viernes 20 de noviembre".
String longDateLabel(DateTime d) =>
    '${_longDays[d.weekday - 1]} ${d.day} de ${_longMonths[d.month - 1]}';

/// "Viernes 20 de noviembre": the long label for the home header.
String headerDateLabel(DateTime d) {
  final label = longDateLabel(d);
  return '${label[0].toUpperCase()}${label.substring(1)}';
}
