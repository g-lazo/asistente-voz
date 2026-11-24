# Visual redesign and phone frame on web

Date: 2026-11-24. Status: approved by Gustavo on 2026-11-24.

## Intent

The app works, but it looks like an unstyled Material sample ("se ve demasiado genérico"). Gustavo
wants it to look designed, and he wants the web version to appear inside a phone so the demo can be
run from Chrome when the emulator's audio does not cooperate. This is a school proof of concept for
a User Experience course, due 2026-11-26: what the grader sees matters most.

## What Gustavo decided

- The look is option A, "Noche", from the mockups shown on 2026-11-24
  (`.superpowers/brainstorm/4002539-1795562818/content/visual-style.html`): dark background with
  violet and blue glows, translucent panels, the microphone as the hero.
- No liquid glass. He first pointed at `rdev/liquid-glass-react`; it is a React component and cannot
  run inside a Flutter app, and he dropped it.
- The web page shows the app inside a phone.
- The Firebase wiring came first; it is done.

## Goals

1. Every screen (sign-in, assistant, tasks) uses the "Noche" look, on Android and on web.
2. On web, in a window wider than a phone, the app is drawn inside a phone-shaped frame.
3. Texts, behaviour, keys and tooltips stay as they are; the existing tests keep passing with at
   most small edits where a test looks at visual structure.

## Non-goals

- A light theme or a theme switch.
- Blur, refraction or any shader effect.
- An animated waveform (left out of the project by Gustavo earlier).
- New features or new copy, apart from the three small labels listed below.

## Anti-goals

- A look that only works on web: the Android emulator renders in software, so nothing here may
  depend on blur or heavy effects.
- A frame that breaks input: the microphone hold, the slide to cancel, the tab swipe and the delete
  dialog must work inside the frame exactly as outside it.

## Approaches

1. **Hand-built in Flutter, no new packages (chosen, my call).** One theme file with the colours, a
   background widget, and restyled existing widgets; the frame is a widget placed with
   `MaterialApp.builder`. Works the same on both targets, testable, no dependency risk two days
   before the deadline.
2. **A Flutter "liquid glass" package.** Closer to the reference he liked, but the best-known one
   does not run on web and the others are unverified with this Flutter version. Dropped with the
   liquid glass idea.
3. **Frame in the HTML page around the Flutter view.** The bezel would be plain HTML and CSS, but
   scaling it to short windows breaks pointer positions, and widget tests could not cover it.

## Design

### Palette and surfaces

- Background `#0E0F1C`, painted once behind every screen, with two soft radial glows: violet
  `#6C4DFF` from the top-left and cyan `#22D3EE` from the bottom-right, both mostly transparent.
- Text `#F2F3FB`; secondary text the same colour at about 70% opacity.
- Accent gradient violet `#6C4DFF` to blue `#3B82F6` (user bubble, microphone, primary button).
- Panels (assistant bubble, task card, sign-in card, round icon buttons, tab track): white at 7-10%
  opacity with a 1 px border of white at about 10%. No blur.
- Danger `#FF5A6E` (overdue chip, microphone armed to cancel, error text).
- Material 3 dark `ThemeData` built from these, so dialogs, snack bars, text fields and the progress
  indicator match without per-widget styling.

### Home screen

- Header instead of the Material app bar: the title "Asistente de tareas", under it today's date as
  "Martes 24 de noviembre" (new label, from `longDateLabel`, first letter upper-case), and two round
  icon buttons on the right: mute and sign out, with the same icons and the same tooltips
  ("Silenciar voz" / "Activar voz", "Cerrar sesión").
- Tabs as a pill-shaped segmented control: "Asistente" and "Mis tareas (N)". Still a `TabBar` with a
  `TabBarView` underneath, so swiping between tabs and the existing slide-to-cancel guard keep
  working.

### Assistant tab

- Bubbles: assistant on the left as a panel, user on the right with the accent gradient; 18 px
  corners with a 4 px tail corner, as today.
- Microphone: a gradient circle with a soft glow ring. Listening: larger, stronger glow. Armed to
  cancel: danger colour with the close icon, as today. Sizes and the 128 px hit area stay.
- Partial transcript and hint stay where they are, restyled.

### Tasks tab

- Each task is a card (panel) with a round checkbox, the title, a date chip and the delete icon
  (tooltip "Eliminar").
- Date chip (new label logic, small): "Hoy", "Mañana", "Ayer", otherwise the short date with its
  first letter upper-case ("Vie 27 nov"). Overdue and not done: the chip is in the danger colour.
- Two section labels, "Pendientes" and "Hechas" (new labels), shown only when that section has
  tasks. The order inside each section is today's `sortTasks` order.
- Done tasks: title struck through and dimmed, checkbox filled with the accent.
- The empty state and the load-error text keep their wording.

### Sign-in screen

- Same background. A small microphone emblem (accent gradient circle) above the title; the fields
  and the button inside one panel; the button uses the accent gradient; the toggle link below.
- Keys `email`, `password`, `submit`, `toggleMode` and every text stay.

### Phone frame on web

- Only on web, and only when the window is at least 600 logical pixels wide. Narrower windows (a
  real phone's browser) and Android show the app full-screen, as today.
- The frame is a phone of 390 x 844 logical pixels: a dark bezel with rounded corners (about 48 px),
  an island at the top, a soft shadow, centred on a backdrop slightly darker than the app.
- The app inside sees a 390 x 844 screen with a top inset for the island, so it lays out exactly as
  on a phone.
- If the window is shorter than the phone, the whole phone is scaled down to fit; it is never
  scaled up.
- Placed with `MaterialApp.builder`, so dialogs and snack bars stay inside the phone.

## What must not change

- Keys: `micButton`, `hint`, `partialText`, `email`, `password`, `submit`, `toggleMode`.
- Tooltips: "Silenciar voz", "Activar voz", "Cerrar sesión", "Eliminar".
- Widget types the tests look for: `Checkbox`, `TabBarView`, `TextButton` in the delete dialog,
  `CircularProgressIndicator`.
- Every user-facing sentence that exists today.

## Left to the builder

- Exact opacities, paddings, radii and font sizes, as long as the result reads like mockup A.
- File layout for the theme and the frame (suggested: `lib/theme/noche.dart`,
  `lib/web_frame/phone_frame.dart`).
- How the glow ring of the microphone animates between states (an implicit size and opacity change
  is enough).

## How it is checked

- The existing suite stays green; new widget tests for the date chip labels, the section labels and
  the frame (shown at 1200 x 800 on web, absent at 400 x 800 and off web; the app inside reports a
  390 x 844 screen).
- The controller looks at both targets: screenshots of sign-in, assistant and tasks in Chrome inside
  the frame, and on the emulator.
- Gustavo looks at it and says whether it matches what he picked.
