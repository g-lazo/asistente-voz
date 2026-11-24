import '../tasks/date_label.dart';
import 'command_parser.dart';

const greeting =
    'Hola. Mantén presionado el micrófono y dime qué quieres anotar. '
    'Por ejemplo: "agrega comprar leche mañana".';
const replyNotUnderstood = 'No te entendí, inténtalo otra vez.';
const replySaveFailed =
    'No pude guardar la tarea. Revisa tu conexión e inténtalo otra vez.';
const replyMicDenied =
    'Necesito permiso para usar el micrófono. Actívalo en los ajustes y vuelve a intentarlo.';
const replySpeechUnavailable =
    'El reconocimiento de voz no está disponible en este dispositivo.';

String replySaved(ParsedTask task, int pending) {
  final due = task.dueDate;
  final forDate = due == null ? '' : ' para el ${longDateLabel(due)}';
  final count = pending == 1 ? '1 pendiente' : '$pending pendientes';
  return 'Listo, agregué "${task.title}"$forDate. Llevas $count.';
}

/// The reply as the voice should read it: without the quotation marks.
String spokenText(String reply) => reply.replaceAll('"', '');
