/// Turns what the speech recognizer heard (Spanish) into a task. Pure Dart:
/// no widgets, no Firebase and no clock, so [today] is always passed in.
class ParsedTask {
  const ParsedTask({required this.title, required this.heard, this.dueDate});

  /// 1 to 200 characters, first letter upper-case.
  final String title;

  /// `DateTime(y, m, d)`, no time of day.
  final DateTime? dueDate;

  /// The transcript, trimmed.
  final String heard;
}

const _maxTitleLength = 200;

// Polite starts and courtesy endings, removed before anything else.
const _openers = [
  ['por', 'favor'],
  ['porfa'],
  ['oye'],
  ['hola'],
];

const _courtesy = [
  ['por', 'favor'],
  ['porfa'],
];

// The lead-in is "request, frame, me, trigger" in that order, each optional
// except the trigger. Longest first within each list.
const _requests = [
  ['me', 'gustaria', 'que'],
  ['quiero', 'que'],
  ['quisiera', 'que'],
  ['necesito', 'que'],
  ['me', 'puedes'],
  ['me', 'podrias'],
  ['puedes'],
  ['podrias'],
];

// Also removed on their own when a phrase starts with one ("tengo que ir").
const _frames = [
  ['tengo', 'que'],
  ['hay', 'que'],
  ['me', 'gustaria'],
  ['debo'],
  ['necesito'],
  ['quiero'],
  ['quisiera'],
];

const _triggers = {
  'agrega',
  'agregar',
  'agregues',
  'agregue',
  'agregame',
  'anade',
  'anadir',
  'anadas',
  'anada',
  'anademe',
  'anota',
  'anotar',
  'anotes',
  'anote',
  'anotame',
  'recuerdame',
  'recuerdas',
  'recuerdes',
  'recuerde',
  'recordar',
  'recordarme',
};

// Longest first, so "la tarea de" wins over "la tarea".
const _connectors = [
  ['la', 'tarea', 'de'],
  ['una', 'tarea', 'de'],
  ['la', 'tarea', 'para'],
  ['una', 'tarea', 'para'],
  ['a', 'mi', 'lista'],
  ['a', 'la', 'lista'],
  ['la', 'tarea'],
  ['una', 'tarea'],
  ['que'],
];

// DateTime.monday is 1 ... DateTime.sunday is 7.
const _weekdays = {
  'lunes': DateTime.monday,
  'martes': DateTime.tuesday,
  'miercoles': DateTime.wednesday,
  'jueves': DateTime.thursday,
  'viernes': DateTime.friday,
  'sabado': DateTime.saturday,
  'domingo': DateTime.sunday,
};

const _months = {
  'enero': 1,
  'febrero': 2,
  'marzo': 3,
  'abril': 4,
  'mayo': 5,
  'junio': 6,
  'julio': 7,
  'agosto': 8,
  'septiembre': 9,
  'octubre': 10,
  'noviembre': 11,
  'diciembre': 12,
};

const _morningArticles = {'la', 'esta'};

const _trailingFillers = {'para', 'de', 'el', 'este'};

// Longest date phrase: "para el 25 de noviembre".
const _maxDatePhraseWords = 5;

const _foldMap = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n',
};

final _edgeNonAlnum = RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$');
final _dayNumber = RegExp(r'^\d{1,2}$');
final _titleEdgePunct = RegExp(r'^[.,;:!?¿¡"\s]+|[.,;:!?¿¡"\s]+$');

/// Lower-case, accents removed, surrounding punctuation dropped.
String _fold(String word) {
  final lower = word.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    out.write(_foldMap[ch] ?? ch);
  }
  return out.toString().replaceAll(_edgeNonAlnum, '');
}

/// The date a folded phrase names, or null when it is not a date.
DateTime? _parseDatePhrase(List<String> phrase, DateTime today) {
  var w = phrase;
  if (w.isNotEmpty && w.first == 'para') w = w.sublist(1);
  if (w.isEmpty) return null;

  DateTime daysAhead(int n) => DateTime(today.year, today.month, today.day + n);

  if (w.length == 1 && w[0] == 'hoy') return daysAhead(0);
  if (w.length == 1 && w[0] == 'manana') return daysAhead(1);
  if (w.length == 2 && w[0] == 'pasado' && w[1] == 'manana') {
    return daysAhead(2);
  }

  if (w.length == 2 && (w[0] == 'el' || w[0] == 'este')) {
    final target = _weekdays[w[1]];
    if (target == null) return null;
    final ahead = (target - today.weekday + 7) % 7;
    return daysAhead(ahead == 0 ? 7 : ahead);
  }

  if (w.isNotEmpty && (w[0] == 'el' || w[0] == 'este')) w = w.sublist(1);
  if (w.length == 3 && w[1] == 'de' && _dayNumber.hasMatch(w[0])) {
    final day = int.parse(w[0]);
    final month = _months[w[2]];
    if (month == null) return null;
    final date = _realDate(today.year, month, day);
    if (date == null) return null;
    if (!date.isBefore(DateTime(today.year, today.month, today.day))) {
      return date;
    }
    return _realDate(today.year + 1, month, day);
  }
  return null;
}

/// Null when the day does not exist in that month (31 de febrero).
DateTime? _realDate(int year, int month, int day) {
  final date = DateTime(year, month, day);
  return date.month == month && date.day == day ? date : null;
}

/// Returns null when the phrase holds no task. Only the date part of [today]
/// is used.
ParsedTask? parseCommand(String transcript, DateTime today) {
  final heard = transcript.trim();
  var words = heard.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  var folded = words.map(_fold).toList();

  // Every removal cuts both lists the same way: the title comes from [words].
  void dropFront(int n) {
    words = words.sublist(n);
    folded = folded.sublist(n);
  }

  // Length of the phrase of [options] that [folded] starts with, or 0.
  int frontMatch(List<List<String>> options) {
    for (final option in options) {
      if (_startsWith(folded, option)) return option.length;
    }
    return 0;
  }

  while (true) {
    final n = _trailingCourtesy(folded);
    if (n == 0) break;
    words = words.sublist(0, words.length - n);
    folded = folded.sublist(0, folded.length - n);
  }
  for (var n = frontMatch(_openers); n > 0; n = frontMatch(_openers)) {
    dropFront(n);
  }

  // Lead-in, all or nothing: [request] [frame] [me] trigger [connector].
  var at = _matchAt(folded, 0, _requests);
  at += _matchAt(folded, at, _frames);
  if (at < folded.length && folded[at] == 'me') at++;
  if (at < folded.length && _triggers.contains(folded[at])) {
    dropFront(at + 1);
    dropFront(frontMatch(_connectors));
  }

  dropFront(frontMatch(_frames));

  DateTime? due;
  final maxLen =
      folded.length < _maxDatePhraseWords ? folded.length : _maxDatePhraseWords;
  // Very end first, then very start; longest phrase first so the optional
  // "para" and "el" are consumed with the date.
  for (var len = maxLen; len >= 1 && due == null; len--) {
    final phrase = folded.sublist(folded.length - len);
    // "de la manana" / "esta manana" is the morning, not tomorrow.
    if (phrase.length == 1 &&
        phrase[0] == 'manana' &&
        folded.length > 1 &&
        _morningArticles.contains(folded[folded.length - 2])) {
      continue;
    }
    final date = _parseDatePhrase(phrase, today);
    if (date != null) {
      due = date;
      words = words.sublist(0, words.length - len);
      folded = folded.sublist(0, folded.length - len);
    }
  }
  var fromStart = false;
  for (var len = maxLen; len >= 1 && due == null; len--) {
    final date = _parseDatePhrase(folded.sublist(0, len), today);
    if (date != null) {
      due = date;
      fromStart = true;
      words = words.sublist(len);
      folded = folded.sublist(len);
    }
  }

  // "mañana tengo que ir al banco": the frame was hidden behind the date.
  if (due != null && fromStart) dropFront(frontMatch(_frames));

  if (due != null) {
    while (folded.isNotEmpty && _trailingFillers.contains(folded.last)) {
      words.removeLast();
      folded.removeLast();
    }
  }

  var title = words.join(' ').replaceAll(_titleEdgePunct, '');
  if (title.isEmpty) return null;
  title = title[0].toUpperCase() + title.substring(1);
  if (title.length > _maxTitleLength) {
    title = title.substring(0, _maxTitleLength);
    // Never leave half of a surrogate pair, nor a space where the cut landed.
    final last = title.codeUnitAt(title.length - 1);
    if (last & 0xFC00 == 0xD800) title = title.substring(0, title.length - 1);
    title = title.trimRight();
  }
  return ParsedTask(title: title, heard: heard, dueDate: due);
}

bool _startsWith(List<String> words, List<String> prefix) {
  if (words.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (words[i] != prefix[i]) return false;
  }
  return true;
}

/// Length of the courtesy phrase [words] ends with, or 0.
int _trailingCourtesy(List<String> words) {
  for (final phrase in _courtesy) {
    final offset = words.length - phrase.length;
    if (offset >= 0 && _startsWith(words.sublist(offset), phrase)) {
      return phrase.length;
    }
  }
  return 0;
}

/// How many words of the first matching phrase of [options] sit at [from].
int _matchAt(List<String> words, int from, List<List<String>> options) {
  final rest = words.sublist(from);
  for (final option in options) {
    if (_startsWith(rest, option)) return option.length;
  }
  return 0;
}
