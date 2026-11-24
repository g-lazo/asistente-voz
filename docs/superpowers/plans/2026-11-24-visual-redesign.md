# Visual Redesign and Web Phone Frame Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every screen the "Noche" look Gustavo picked and draw the web version inside a phone frame, without changing texts or behaviour.

**Architecture:** One theme file holds the palette, the dark Material 3 theme, the background and the panel decoration; the existing screen widgets are restyled in place and keep their keys, tooltips and widget types. The web frame is one widget placed with `MaterialApp.builder`, so routes and dialogs render inside it.

**Tech Stack:** Flutter 3.50 (Material from `package:material_ui/material_ui.dart`), Dart 3.14, `flutter_test`. No new packages.

**Spec:** `docs/superpowers/specs/2026-11-24-visual-redesign-design.md`

## Global Constraints

- No new packages. No blur, no shader, no `BackdropFilter`: the Android emulator renders in software.
- Not to be added: an animated waveform, a confirmation card with Undo, suggestion chips, a light theme or a theme switch.
- Palette: background `0xFF0E0F1C`, backdrop behind the phone `0xFF07080F`, text `0xFFF2F3FB`, violet `0xFF6C4DFF`, blue `0xFF3B82F6`, cyan `0xFF22D3EE`, danger `0xFFFF5A6E`. Accent gradient: violet to blue, top-left to bottom-right. Panel: white at about 8% with a 1 px border of white at about 10%.
- Keys that stay: `micButton`, `hint`, `partialText`, `email`, `password`, `submit`, `toggleMode`.
- Tooltips that stay: "Silenciar voz", "Activar voz", "Cerrar sesión", "Eliminar".
- Widget types the tests look for and that stay: `Checkbox`, `TabBarView`, `TextButton` in the delete dialog, `FilledButton` with key `submit`, `CircularProgressIndicator`.
- Every user-facing sentence that exists today stays word for word. New labels are only: the header date, "Pendientes", "Hechas", "Hoy", "Mañana", "Ayer" and the capitalised short date.
- No existing assertion is removed or weakened, except the date-text lookups named in Task 2.
- UI text in Spanish (Mexico); code, comments, test names and commit messages in English. No emojis.
- Every `flutter` command runs as `docker compose exec -T dev <command>`. Commits: subject only, no body, no footer; local git only.
- Never stage `lib/spike_main.dart`, `lib/preview_main.dart`, `docs/spike-speech.md`, `docs/screenshots/`.

## Review Focus

1. A window shorter than the phone (a 1366 x 600 laptop): the phone shrinks to fit and a tap still lands on the widget under the pointer. Test in Task 3.
2. A small Android screen, 320 x 568 at text scale 1.3: the new header, with a long date such as "Miércoles 30 de septiembre" and two icon buttons, and the pill tabs do not overflow. Test in Task 1.
3. A 200-character task title in a card at 320 px: the title is cut with an ellipsis, the chip and the delete button stay visible, nothing overflows. Test in Task 2.
4. Dates carrying a time of day and month or year boundaries in the chip label: "Hoy", "Mañana" and "Ayer" compare dates only. Test in Task 2.
5. A task whose title equals a chip label ("Hoy", due today): both are shown and the row still works. Test in Task 2.

---

### Task 1: Noche theme, home header with pill tabs, assistant and sign-in restyle

**Files:**
- Create: `lib/theme/noche.dart`, `test/theme/noche_test.dart`
- Modify: `lib/tasks/date_label.dart`, `test/tasks/date_label_test.dart`
- Modify: `lib/main.dart`, `lib/home/home_screen.dart`, `test/home/home_screen_test.dart`
- Modify: `lib/assistant/assistant_tab.dart`, `lib/auth/sign_in_screen.dart`, `test/auth/sign_in_screen_test.dart`

**Interfaces:**
- Produces (`lib/theme/noche.dart`):

```dart
abstract final class Noche {
  static const Color background, backdrop, text, violet, blue, cyan, danger; // Global Constraints
  static const LinearGradient accent;          // violet to blue
  static Color get textMuted;                  // text at about 70%
  static BoxDecoration panel({double radius = 16});
}
ThemeData nocheTheme();                        // dark Material 3 built from Noche
class NocheBackground extends StatelessWidget { // background colour plus the two glows, then child
  const NocheBackground({super.key, required this.child});
  final Widget child;
}
```

- Produces (`lib/tasks/date_label.dart`): `String headerDateLabel(DateTime d)`, the long label with its first letter upper-case.

- [ ] **Step 1: Write the failing tests**

```dart
// test/theme/noche_test.dart
test('theme is dark Material 3 built from the palette', () {
  final t = nocheTheme();
  expect(t.brightness, Brightness.dark);
  expect(t.useMaterial3, isTrue);
  expect(t.scaffoldBackgroundColor, Noche.background);
  expect(t.colorScheme.primary, Noche.violet);
  expect(t.colorScheme.error, Noche.danger);
});
testWidgets('NocheBackground shows its child', ...);   // find.text('x') findsOneWidget

// test/tasks/date_label_test.dart
expect(headerDateLabel(DateTime(2026, 11, 24)), 'Martes 24 de noviembre');
expect(headerDateLabel(DateTime(2026, 11, 25)), 'Miércoles 25 de noviembre');
expect(headerDateLabel(DateTime(2026, 11, 28)), 'Sábado 28 de noviembre');
expect(headerDateLabel(DateTime(2027, 1, 4)), 'Lunes 4 de enero');

// test/home/home_screen_test.dart (added; existing tests stay)
testWidgets('header shows the title and today\'s date, without an app bar', ...);
//   find.text('Asistente de tareas') findsOneWidget
//   find.text(headerDateLabel(DateTime.now())) findsOneWidget
//   find.byType(AppBar) findsNothing
testWidgets('fits 320 x 568 at text scale 1.3', ...);
//   surface 320 x 568, MediaQuery textScaler 1.3, pumpAndSettle, tester.takeException() isNull

// test/auth/sign_in_screen_test.dart (added)
testWidgets('fits 320 x 568 in sign-up mode with an error shown', ...);  // takeException() isNull
```

- [ ] **Step 2: Run them to see them fail**

Run: `docker compose exec -T dev flutter test test/theme test/tasks/date_label_test.dart test/home test/auth`
Expected: FAIL (`noche.dart` and `headerDateLabel` do not exist; an `AppBar` is found).

- [ ] **Step 3: Implement `lib/theme/noche.dart` and `headerDateLabel`.** The theme styles text fields, the snack bar, the dialog, the progress indicator and the tab bar so no screen needs per-widget colours for them.
- [ ] **Step 4: `lib/main.dart`:** `theme: nocheTheme()`. Nothing else changes there.
- [ ] **Step 5: Restyle `HomeScreen`.** `Scaffold` without an app bar; body is `NocheBackground` > `SafeArea` > column of: the header row (title, `headerDateLabel(now)` under it, both cut with an ellipsis; the mute and sign-out `IconButton`s as round panels, same icons, same tooltips, same callbacks), the pill `TabBar` on a panel track (indicator a rounded box, no divider), and the `TabBarView` with today's children unchanged.
- [ ] **Step 6: Restyle `AssistantTab`.** User bubble: `Noche.accent`; assistant bubble: `Noche.panel`, both keeping the 18 px corners and the 4 px tail. Microphone: gradient circle with a glow (box shadows) and a ring; listening is larger with a stronger glow; armed to cancel uses the theme's error colour and the close icon. Sizes, the 128 px hit area, the `Listener`, the `GestureDetector` and the keys do not change.
- [ ] **Step 7: Restyle `SignInScreen`.** `NocheBackground`; a round accent emblem with the microphone icon above the title; the two fields, the error text and the `FilledButton` (key `submit`) inside one panel; the toggle link below. Texts, keys and validation do not change.
- [ ] **Step 8: Run** `docker compose exec -T dev flutter test` (all pass; 154 before this task) and `docker compose exec -T dev flutter analyze lib test` (no issues outside the untracked `lib/spike_main.dart`).
- [ ] **Step 9: Commit**

```bash
git add lib/theme/noche.dart test/theme/noche_test.dart lib/tasks/date_label.dart \
  test/tasks/date_label_test.dart lib/main.dart lib/home/home_screen.dart \
  test/home/home_screen_test.dart lib/assistant/assistant_tab.dart \
  lib/auth/sign_in_screen.dart test/auth/sign_in_screen_test.dart
git commit -m "feat: give the app the Noche look with a custom header and pill tabs"
```

### Task 2: Task cards with sections and date chips

**Files:**
- Modify: `lib/tasks/date_label.dart`, `test/tasks/date_label_test.dart`
- Modify: `lib/tasks/tasks_tab.dart`, `test/tasks/tasks_tab_test.dart`

**Interfaces:**
- Consumes: `Noche.panel`, `Noche.textMuted` (Task 1); `shortDateLabel`.
- Produces: `String chipDateLabel(DateTime due, DateTime today)`: "Hoy", "Mañana", "Ayer", otherwise the short label with its first letter upper-case. Only the date parts are compared.

- [ ] **Step 1: Write the failing tests**

```dart
// test/tasks/date_label_test.dart
final today = DateTime(2026, 11, 24, 15, 30);
expect(chipDateLabel(DateTime(2026, 11, 24), today), 'Hoy');
expect(chipDateLabel(DateTime(2026, 11, 25), today), 'Mañana');
expect(chipDateLabel(DateTime(2026, 11, 23), today), 'Ayer');
expect(chipDateLabel(DateTime(2026, 11, 27), today), 'Vie 27 nov');
expect(chipDateLabel(DateTime(2026, 11, 22), today), 'Dom 22 nov');
expect(chipDateLabel(DateTime(2026, 11, 28), today), 'Sáb 28 nov');
expect(chipDateLabel(DateTime(2026, 11, 25, 23, 59), DateTime(2026, 11, 24)), 'Mañana');
expect(chipDateLabel(DateTime(2026, 12, 1), DateTime(2026, 11, 30, 23, 59)), 'Mañana');
expect(chipDateLabel(DateTime(2027, 1, 1), DateTime(2026, 12, 31)), 'Mañana');
expect(chipDateLabel(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 'Ayer');

// test/tasks/tasks_tab_test.dart (added)
testWidgets('pending and done tasks sit under their section labels', ...);
//   mixed list: 'Pendientes' and 'Hechas' found once each, every pending title above 'Hechas'
testWidgets('a section label is hidden when its section is empty', ...);
//   all pending: 'Hechas' findsNothing; all done: 'Pendientes' findsNothing
testWidgets('the chip shows the relative label and no chip without a date', ...);
//   due tomorrow: 'Mañana' found; a task with no due date adds no chip text
testWidgets('a task titled like a chip label shows both', ...);
//   title 'Hoy', due today: find.text('Hoy') findsNWidgets(2); the checkbox still toggles it
testWidgets('a 200-character title fits a 320 px card', ...);
//   surface 320 x 568: takeException() isNull, the chip text and find.byTooltip('Eliminar') are found
```

- [ ] **Step 2: Update the date-text lookups of three existing tests** in `test/tasks/tasks_tab_test.dart` ("row shows title and date label", "overdue pending date is red, a done one is not", "today with a time of day is not overdue"): each looks a date up by its old lower-case text; replace that text with what `chipDateLabel` gives for the same due date and the test's own `today`, and where a title would now collide with a chip label, rename the title. Their colour assertions (overdue pending equals the theme's error colour, the others do not) stay exactly as they are. List every changed line in the report.
- [ ] **Step 3: Run them to see them fail**

Run: `docker compose exec -T dev flutter test test/tasks`
Expected: FAIL (`chipDateLabel` does not exist; no section labels).

- [ ] **Step 4: Implement `chipDateLabel`.**
- [ ] **Step 5: Restyle `TasksTab`.** The empty state is unchanged. Otherwise a scrolling list of: "Pendientes" (if any pending), the pending cards, "Hechas" (if any done), the done cards, in the order the list arrives. A card is a `Noche.panel` row: the `Checkbox` with a circular shape, the title (up to two lines, ellipsis; struck through and dimmed when done), the chip when there is a due date, and the delete `IconButton` (tooltip "Eliminar"). The chip's text uses `Theme.of(context).colorScheme.error` when the task is overdue and not done. The delete dialog is unchanged.
- [ ] **Step 6: Run** `docker compose exec -T dev flutter test` (all pass) and `docker compose exec -T dev flutter analyze lib test`.
- [ ] **Step 7: Commit**

```bash
git add lib/tasks/date_label.dart test/tasks/date_label_test.dart lib/tasks/tasks_tab.dart \
  test/tasks/tasks_tab_test.dart
git commit -m "feat: show tasks as cards with sections and relative date chips"
```

### Task 3: Phone frame on web

**Files:**
- Create: `lib/web_frame/phone_frame.dart`, `test/web_frame/phone_frame_test.dart`
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `Noche.backdrop` (Task 1).
- Produces:

```dart
/// Draws [child] inside a phone when [enabled] and the window is at least
/// [minWindowWidth] wide; otherwise returns [child] untouched.
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.enabled, required this.child});
  static const Size screenSize = Size(390, 844);
  static const double minWindowWidth = 600;
  static const double islandInset = 44;   // top padding the child sees
  final bool enabled;
  final Widget child;
}
```

The bezel carries `Key('phoneBezel')`. Inside the frame the child gets a `MediaQuery` whose size is `screenSize`, whose top padding and view padding are `islandInset`, and whose view insets are zero.

- [ ] **Step 1: Write the failing tests** `test/web_frame/phone_frame_test.dart`, each pumping `MaterialApp(builder: (c, child) => PhoneFrame(enabled: ..., child: child!), home: probe)` where the probe shows `MediaQuery.sizeOf` and `MediaQuery.paddingOf(context).top` and holds a button:
  - 1200 x 900 window, enabled: the probe sees 390 x 844 and a top padding of 44; `phoneBezel` is found
  - 1600 x 1200 window, enabled: the bezel is not scaled up (the probe's rendered size is 390 x 844)
  - 1366 x 600 window, enabled: the bezel's rendered height is at most 600, the probe still sees 390 x 844, and tapping the button calls its callback once
  - 599 x 900 window, enabled: no `phoneBezel`; the probe sees 599 x 900
  - 1200 x 900 window, not enabled: no `phoneBezel`; the probe sees 1200 x 900
  - a dialog opened from the probe at 1200 x 900 lies inside the bezel's rectangle
- [ ] **Step 2: Run them to see them fail**: `docker compose exec -T dev flutter test test/web_frame`
- [ ] **Step 3: Implement `PhoneFrame`.** Backdrop `Noche.backdrop` filling the window; the phone centred with a margin, scaled down only (`FittedBox` with `BoxFit.scaleDown` or equivalent); bezel dark with about 48 px outer corners and a soft shadow; the island a dark pill at the top centre drawn above the child; the child clipped to the screen's rounded corners.
- [ ] **Step 4: `lib/main.dart`:** `builder: (context, child) => PhoneFrame(enabled: kIsWeb, child: child!)`.
- [ ] **Step 5: Run** `docker compose exec -T dev flutter test` (all pass), `docker compose exec -T dev flutter analyze lib test`, and `docker compose exec -T dev flutter build web` (expected: `Built build/web`).
- [ ] **Step 6: Commit**

```bash
git add lib/web_frame/phone_frame.dart test/web_frame/phone_frame_test.dart lib/main.dart
git commit -m "feat: draw the web version inside a phone frame"
```

## After the tasks (controller, with Gustavo)

- Serve the app on port 8080 and look at sign-in, assistant and tasks in Chrome inside the frame; rebuild the debug APK and look at the same screens on the emulator when it is running.
- Gustavo says whether it matches the mockup he picked.
