# Asistente de voz para tareas cotidianas

A proof of concept for a User Experience course. It shows that a voice assistant for everyday tasks
can be built with Flutter, Firebase Auth and Firestore: a person signs in, holds a microphone button,
says a task out loud, and the task is saved to Firestore and listed in the app. The assistant answers
in text and out loud, and understands simple Spanish dates ("el viernes", "pasado mañana").

The app runs as an Android app (in an emulator) and as a web app (in Chrome) from one Flutter
codebase. The user interface is in Spanish (Mexico).

## Requirements

- Docker with Docker Compose, on a Linux desktop with an X server (the emulator window opens on the
  host desktop), `/dev/kvm` available to your user, and PulseAudio or PipeWire for the microphone and
  speakers.
- Chrome on the host, for the web version.
- A Firebase project on the free Spark plan and a Google account to log in to it.
- `make`.

Nothing else is installed on the host: Flutter, the Android SDK, Java and the Firebase CLI all live
in the Docker image. Every command below goes through `make` or `docker compose exec dev ...`.

## First-time setup

1. Build the development image. This downloads several GB (Flutter SDK, Android SDK, emulator
   system image), so it takes a while the first time.

   ```
   make build
   ```

2. Start the container. `make up` needs `XAUTHORITY` and `DISPLAY` set, which a normal desktop
   session already does.

   ```
   make up
   ```

3. In the Firebase console, create a project (the free Spark plan is enough), then:
   - Authentication: enable the Email/Password sign-in method.
   - Firestore Database: create the database.

4. Log in to Firebase from the container. This is interactive and uses your own Google account;
   follow the link it prints and paste the code back.

   ```
   make firebase-login
   ```

5. Register the Android and web apps in your project and generate the Flutter configuration with
   the FlutterFire CLI, replacing `<your-project-id>` with the id of the project you created:

   ```
   docker compose exec dev flutterfire configure --project=<your-project-id> --platforms=android,web --android-package-name=mx.glazo.asistente_voz --yes
   ```

   The generated values identify the project; they are not secrets, and access is controlled by the
   security rules.

6. Deploy the Firestore security rules (`firestore.rules`): a signed-in user can read and write only
   the documents under their own `users/{uid}`. First select the project for the Firebase CLI, which
   records it for the deploy. The deploy changes the live project.

   ```
   docker compose exec dev firebase use <your-project-id>
   make rules-deploy
   ```

## Running on the Android emulator

```
make emulator   # creates the "poc" virtual device if needed, opens its window, waits for boot
make android    # builds and runs the app on the emulator
```

The emulator uses the host microphone and speakers. `make emulator-stop` shuts it down.

## Running on Chrome

```
make web
```

Then open `http://localhost:8080` in Chrome and allow the microphone when asked. Chrome only allows
the microphone on localhost or HTTPS, and the speech recognition is Chrome's own, so this does not
work in other browsers.

## Talking to it

Create an account on the sign-in screen ("Crear cuenta"), then on the "Asistente" tab hold the
microphone button, speak, and release. Slide to the left before releasing to cancel: nothing is
saved. In the emulator and in Chrome the same gesture is done with the mouse. The tasks appear in the
"Mis tareas" tab as they are saved. The mute button in the app bar turns the spoken answers off.

You can say the task naturally. A polite or lead-in start ("por favor", "quiero que añadas que",
"puedes agregar", "necesito", "tengo que") and the verbs agregar, añadir, anotar and recordar in their
common forms are removed, and what is left is the task. Saying only the task works too. A date phrase is removed from the task text and
stored as its due date. Examples, with today being Thursday 19 November 2026:

| You say | Task | Due date |
|---------|------|----------|
| agrega comprar leche | Comprar leche | none |
| comprar leche | Comprar leche | none |
| recuérdame pagar el internet el viernes | Pagar el internet | 2026-11-20 |
| anota entregar el reporte para mañana | Entregar el reporte | 2026-11-20 |
| agrega llamar a mamá pasado mañana | Llamar a mamá | 2026-11-21 |
| añade cita con el dentista el 25 de noviembre | Cita con el dentista | 2026-11-25 |
| agrega ir al gimnasio el jueves | Ir al gimnasio | 2026-11-26 |
| anota renovar la licencia el 5 de enero | Renovar la licencia | 2027-01-05 |
| quiero que añadas que tengo que hacer la tarea | Hacer la tarea | none |
| agrega comprar leche mañana por favor | Comprar leche | 2026-11-20 |
| recuérdame que tengo que pagar el internet el viernes | Pagar el internet | 2026-11-20 |

Supported dates are "hoy", "mañana", "pasado mañana", a weekday ("el lunes" to "el domingo": the next
such day after today) and a day and month ("el 25 de noviembre": this year, or next year if it has
passed). The app answers, for example, `Listo, agregué "Comprar leche". Llevas 1 pendiente.` If it
cannot make a task from what it heard it says "No te entendí, inténtalo otra vez." and saves nothing.

A manual script to check the voice paths on both targets is in
[docs/manual-checklist.md](docs/manual-checklist.md).

## Tests

```
make test       # unit and widget tests (flutter test)
make analyze    # static analysis (flutter analyze)
make apk        # builds a debug APK
```

The phrase-to-task function is covered by unit tests with today's date passed in. The voice paths
need a human and are in the manual checklist.

## Other commands

- `make shell` opens a shell in the container, `make down` stops it, `make doctor` runs
  `flutter doctor -v`, `make get` runs `flutter pub get`.
- `make screenshot NAME=<name>` saves a screenshot of the emulator to `docs/screenshots/<name>.png`.

## Known limits

- No iOS build: it needs macOS, which this project does not have.
- On the web, voice works only in Chrome.
- Dates have no time of day. "a las cinco" stays in the task text, and there are no reminders or
  notifications.
- The only voice command is adding a task. Completing, deleting and editing a task are done by hand
  in "Mis tareas".
- The chat history is not saved; it lasts while the app is open.
- Sign-in is email and password only: no Google sign-in, password reset or email verification.
- Spanish only.
- On the emulator, the recognizer offers Spanish as `es_ES` (not `es_MX`) and the spoken answers use
  an `es-ES` or `es-US` voice, because the system image has no Mexican Spanish voice.
- No publishing: no app store, no hosting deploy, no CI.
