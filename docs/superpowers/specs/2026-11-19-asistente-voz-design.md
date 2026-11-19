# Voice Task Assistant (POC) - Design

Date: 2026-11-19
Owner: Gustavo Lazo
Status: draft, waiting for Gustavo's approval

## 1. Context

School assignment for the course User Experience (UACH), posted in Google Classroom as
"POCs - Asistente de voz para tareas cotidianas". Due Thursday 2026-11-26 at 23:59, Chihuahua time
(Classroom shows 2026-11-27 05:59 UTC).

The assignment, translated:

> A voice assistant app for everyday tasks is required. Build a POC that shows we can build the app
> with Flutter, Firebase Auth and Firestore. The prototype must show a mobile app built in Flutter
> where the user gives voice commands to add tasks to a list. The data must be stored in a Google
> Firestore database. The UI must show the list of tasks created by voice commands.

There is no rubric and no stated delivery format. Gustavo does not know yet how it will be handed in.

## 2. Intent

Prove, with a working demo, that a voice task assistant can be built on Flutter + Firebase Auth +
Firestore: a person signs in, says a task out loud, the task lands in Firestore, and the app lists it.

Because the course is User Experience, how the interaction feels matters more than how many features
there are: the person must always know whether the app is listening, what it understood, and what it
did with it.

## 3. Goals

1. One Flutter codebase that runs as an Android app (in an emulator) and as a web app (in Chrome).
2. Sign-up, sign-in and sign-out with Firebase Auth (email and password). The session is remembered.
3. Hold-to-talk voice input in Mexican Spanish, with the transcript shown live.
4. What the person says becomes a task stored in Firestore, visible only to that person.
5. A chat-style Assistant tab and a "Mis tareas" tab that updates in real time.
6. The assistant answers in text and out loud, and can be muted.
7. Simple Spanish date phrases are understood and stored as the task's due date.
8. Everything runs from Docker. Nothing is installed on the host besides Docker itself.
9. A README with the steps to run it, plus screenshots.

## 4. Non-goals

- An iOS build. Gustavo only has an iPhone, and iOS builds need macOS; this is out.
- Voice commands other than adding a task (completing or deleting by voice).
- Times of day, reminders or notifications.
- Editing a task's text or date after it is created.
- Saving the chat history. The chat lives only while the app is open.
- Google sign-in, password reset, email verification.
- Other languages. The UI and the recognition are Spanish only.
- Publishing: no app store, no hosting deploy, no CI.

## 5. Anti-goals

These would make it a failure even if it technically works:

- A task saved from a misheard, empty or cancelled phrase without the person noticing.
- A demo that depends on one fragile path. The web version must stay working the whole time, as the
  fallback if the emulator microphone fails on demo day.
- Anything installed on the host (Flutter, Java, Android SDK, Node).
- One user seeing another user's tasks.
- Copying another app's branding or visual identity. Interaction patterns are borrowed; looks are not.

## 6. Constraints

- Host: Ubuntu 26.04, Docker 29, Docker Compose v5, 8 cores, 30 GB RAM, 232 GB free.
  `/dev/kvm` is readable and writable by the user. The desktop session is Wayland with XWayland
  (`DISPLAY=:0`, socket in `/tmp/.X11-unix`). Audio is PipeWire with a PulseAudio socket at
  `/run/user/1000/pulse/native`. The user is in the `docker` and `plugdev` groups.
- No Flutter, Dart, Java, Android SDK or Firebase CLI on the host, and it must stay that way.
- No Android phone is available. The Android target is an emulator.
- Firebase: free Spark plan only. Gustavo creates the Firebase project with his own Google account and
  does every interactive login himself. The builder never types credentials.
- Git is local only for now. No remote. Nothing is pushed or deployed without asking Gustavo first.
  A GitHub repo may come later.
- The first image build downloads several GB (Flutter SDK, Android SDK, system image). Gustavo gives
  the go-ahead before that download starts.
- Language: UI text in Spanish (Mexico). Code, comments, commits and docs in English.
- No emojis anywhere: code, UI text, commits, docs.
- Commits: no signature, no attribution footer, default git identity.

## 7. What Gustavo decided

These came from Gustavo, in his words or by picking among options he was shown:

- **Where:** the repo lives at `~/Documents/escuela/user-experience/asistente-voz`.
- **Isolation:** work inside Docker, the way he uses uv environments for Python. uv itself is only used
  if a Python helper script turns out to be needed.
- **Targets:** the Android emulator inside Docker is the main one. The web version in Chrome is the
  fallback. Both are built.
- **Main screen:** option B of `docs/mockups/main-screen-options.html`, the conversation layout: an
  Assistant tab with chat bubbles and the microphone at the bottom, and a second tab with the task list.
- **Patterns to include** (from `docs/mockups/pattern-options.html`): hold to talk (4), spoken replies
  (5) and date understanding (6).
- **Patterns he left out:** the confirmation card with Undo (1), the suggestion chips (2) and the
  animated waveform (3). Do not add them.

He also approved, as proposed to him, everything in section 8 that is not marked "builder's call".

## 8. Behaviour

### 8.1 Sign-in screen

- Fields: email and password. One screen that switches between "Iniciar sesión" and "Crear cuenta".
- Errors are shown in Spanish next to the form: invalid email, wrong email or password, email already
  in use, weak password, no connection.
- After signing in, the app goes to the home screen. The session survives closing the app.
- Sign-out is in the app bar.

### 8.2 Home screen

- App bar: title, a mute toggle for the assistant's voice, and sign-out.
- Two tabs: "Asistente" and "Mis tareas (N)", where N is the number of pending tasks.

### 8.3 Assistant tab

- It opens with one assistant bubble that explains what to do, for example: "Hola. Mantén presionado
  el micrófono y dime qué quieres anotar." This replaces the suggestion chips Gustavo left out, so a
  first-time user is not lost. The exact wording is the builder's call.
- The microphone button sits at the bottom centre, with a hint under it.
  - Idle hint: "Mantén presionado para hablar".
  - While held: "Suelta para enviar · desliza a la izquierda para cancelar".
- **Hold:** listening starts in Spanish (es-MX). The partial transcript appears above the button and
  updates as words arrive.
- **Release:** the final transcript becomes a user bubble, then the command is processed (8.4) and the
  assistant answers (8.5).
- **Slide left while holding, then release:** cancelled. Nothing is sent and nothing is saved. The hint
  shows "Cancelado" briefly.
- In the emulator and on the web the same gesture is done with the mouse.
- Speech recognizers tend to stop on their own after a silence. The text heard so far must not be lost
  if that happens before the person releases the button. How to handle it is the builder's call.
- If the assistant is speaking when the person presses the microphone, it stops speaking first, so it
  does not transcribe its own voice.
- Microphone permission denied: an assistant bubble explains that the microphone is needed and how to
  allow it. No crash, no dead button.
- Recognition not available on the device: an assistant bubble says so.

### 8.4 Turning a phrase into a task

This is a pure function: transcript and today's date in, either a task (title and optional due date) or
"nothing" out. It has no dependency on Flutter, Firebase or the clock, so it can be unit tested.

1. Trim, collapse spaces, drop trailing punctuation. Matching ignores case and accents, because the
   recognizer does not always return accents ("recuerdame", "miercoles", "sabado", "manana").
2. If the phrase starts with a trigger word, remove it. Trigger words: "agrega", "agregar", "añade",
   "añadir", "anota", "anotar", "recuérdame". A connector right after the trigger is removed too
   ("que", "la tarea", "la tarea de", "una tarea"). The exact connector list is the builder's call.
3. Find a date phrase and remove it from the text. Supported:
   - "hoy", "mañana", "pasado mañana"
   - "el lunes" ... "el domingo": the next such day strictly after today. Said on a Friday,
     "el viernes" means the Friday of next week.
   - "el 25 de noviembre": that day this year, or next year if it has already passed. The day number
     arrives as digits; accepting it spelled out ("veinticinco") is a nice-to-have.
   - An optional "para" or "este" in front of the date phrase is removed with it ("para mañana",
     "este viernes").
   - Times of day are not supported. "a las cinco" simply stays in the title.
4. What remains is the title: trimmed, with its first letter capitalized. Maximum 200 characters.
5. With no trigger word, the whole phrase (minus the date) is the title. This is deliberate: the demo
   must not fail because someone forgot to say "agrega".
6. If the title is empty, there is no task.

Examples, with today being Thursday 2026-11-19:

| Heard | Title | Due date |
|---|---|---|
| agrega comprar leche | Comprar leche | none |
| comprar leche | Comprar leche | none |
| recuérdame pagar el internet el viernes | Pagar el internet | 2026-11-20 |
| anota entregar el reporte para mañana | Entregar el reporte | 2026-11-20 |
| agrega llamar a mamá pasado mañana | Llamar a mamá | 2026-11-21 |
| añade cita con el dentista el 25 de noviembre | Cita con el dentista | 2026-11-25 |
| agrega ir al gimnasio el jueves | Ir al gimnasio | 2026-11-26 |
| anota renovar la licencia el 5 de enero | Renovar la licencia | 2027-01-05 |
| agrega | no task | - |
| (silence) | no task | - |

### 8.5 The assistant's answers

Every answer is an assistant bubble and, unless muted, is also read out loud with a Spanish voice
(es-MX if the device has one, otherwise any Spanish voice).

- Saved, no date: `Listo, agregué "Comprar leche". Llevas 4 pendientes.`
- Saved, with date: `Listo, agregué "Pagar el internet" para el viernes 20 de noviembre. Llevas 5 pendientes.`
- Nothing understood: `No te entendí, inténtalo otra vez.` Nothing is saved.
- Could not save: `No pude guardar la tarea. Revisa tu conexión e inténtalo otra vez.`

The "Listo" answer is only given once the write to Firestore has been accepted. The mute setting is
remembered on the device between sessions.

### 8.6 "Mis tareas" tab

- A live list of the signed-in user's tasks from Firestore. A task added from the Assistant tab shows
  up without refreshing.
- Order: pending tasks first, by due date (earliest first), tasks with no date after the dated ones.
  Completed tasks go at the bottom, struck through.
- Each row: a checkbox that marks it done or not done, the title, and the due date as a short label
  such as "vie 20 nov" when it has one.
- Builder's call: an overdue pending task shows its date in a warning colour.
- Each row has a delete button. Builder's call: it asks "¿Eliminar esta tarea?" before deleting.
- Empty state: a short message that sends the person to the Assistant tab.

## 9. Data

Builder's call on the exact shape; this is the starting point.

```
users/{uid}/tasks/{taskId}
  title      string     1 to 200 characters
  done       bool
  dueDate    string     "YYYY-MM-DD", or null (a calendar day, not an instant, to avoid time zone drift)
  heard      string     the transcript as recognized, kept for debugging
  createdAt  timestamp  server time
```

Security rules: a signed-in user can read and write only documents under their own `users/{uid}`.
Everything else is denied. Creating a task validates that `title` is a non-empty string within the
length limit. The rules file lives in the repo.

## 10. Environment

How the Docker setup is laid out is the builder's call. What it must provide:

- One development image with a pinned Flutter stable SDK, the JDK and Android SDK pieces Flutter needs,
  the Android emulator with an x86_64 system image that ships Google's speech services (a Google APIs
  or Google Play image; the plain AOSP image has no speech recognizer), and the Firebase CLI plus the
  FlutterFire CLI.
- The repo bind-mounted, with files created inside the container owned by the host user, not root.
- Caches (pub, Gradle, the emulator's virtual device, the Firebase CLI login) in named volumes, so a
  rebuild or a new container does not download or log in again.
- The emulator running with KVM, its window shown on the host desktop, and the host microphone and
  speakers passed through.
- The web version served from the container on a fixed localhost port and opened in the host's Chrome.
  Chrome only allows the microphone on localhost or HTTPS, and the Web Speech API is Chrome-only.
- Short, memorable commands for the daily actions (shell, start emulator, run on Android, run on web,
  run tests, build an APK), for example through a Makefile.

## 11. Firebase setup

Split of who does what:

- **Gustavo, in the Firebase console:** create the project, enable the Email/Password sign-in method,
  create the Firestore database.
- **Gustavo, in the terminal:** run the Firebase CLI login command the builder gives him. It is
  interactive and uses his Google account.
- **Builder:** register the Android and web apps and generate the Flutter configuration with the
  FlutterFire CLI, write the security rules, and prepare the rules deploy. Deploying the rules changes
  the live project, so the builder asks Gustavo before running it.

The generated Firebase client configuration is committed. Those values identify the project; they are
not secrets, and access is controlled by the security rules. No service account key or other secret is
ever added to the repo.

## 12. Risks

1. **Speech recognition inside the emulator.** It needs Google's speech services in the system image
   and the host microphone reaching the emulator through Docker. This is the least certain part. It is
   checked first, with a throwaway test, before any feature is built on it. If it cannot be made
   reliable, the web version carries the voice demo and the emulator shows the rest.
2. **Hold to talk against the recognizer's own silence timeout.** See 8.3.
3. **Spoken replies in the emulator.** They need a text-to-speech engine with a Spanish voice in the
   system image. If it is missing, replies stay as text there and the web version covers speech.
4. **Web speech depends on Chrome and an internet connection.**
5. **The deadline.** Seven days. If time runs short, cut in this order: spelled-out day numbers, the
   overdue colour, the APK build. Never cut the web fallback.

## 13. Suggested order

The plan decides the real order. A sensible one:

1. Environment: the image builds, the emulator opens its window, a trivial app runs on Android and on
   web, and a throwaway speech test confirms risk 1 one way or the other.
2. Firebase wiring and the sign-in screen.
3. Tasks in Firestore and the "Mis tareas" tab.
4. The phrase-to-task function, test first, using the table in 8.4.
5. The Assistant tab: hold to talk, bubbles, answers, spoken replies, mute.
6. README, screenshots, final check on both targets.

## 14. Testing

- Unit tests for the phrase-to-task function covering every row of the table in 8.4, with today's date
  passed in.
- Widget tests where they are cheap (sign-in form validation, list ordering).
- A written manual checklist for the voice paths, run on the emulator and on Chrome.

## 15. Done means

On the emulator and on Chrome, this script works from a clean start:

1. Create an account and land on the Assistant tab.
2. Hold the microphone, say "agrega comprar leche", release. The phrase shows as a bubble, the
   assistant answers in text and out loud, and "Comprar leche" is in "Mis tareas" and in the Firebase
   console.
3. Say "recuérdame pagar el internet el viernes". The task has the right date.
4. Hold, start talking, slide left, release. Nothing is saved.
5. Mark a task as done. Delete a task.
6. Mute the assistant. The next answer is text only.
7. Sign out and sign in again. The tasks are still there.
8. Sign in with a second account. Its list is empty.

And the README explains how to get from a fresh clone to that demo using only Docker.

## 16. Left to the builder

State management, folder structure, package choices and versions (for example `speech_to_text`,
`flutter_tts`, `firebase_auth`, `cloud_firestore`), the Android application id, visual styling (colours,
typography, motion), the exact Docker and Makefile layout, and anything marked "builder's call" above.

The README is written in English, following Gustavo's convention for docs. If the professor needs it in
Spanish, that is a one-line decision for Gustavo.
