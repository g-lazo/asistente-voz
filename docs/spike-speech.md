# Speech spike findings

Status: closed. Both packages (`speech_to_text`, `flutter_tts`) are kept and the app uses them.

## Environment

Emulator `poc` (Android 14, google_apis_playstore, x86_64), started with `-allow-host-audio`.
Packages: `speech_to_text 7.5.0`, `flutter_tts 4.2.5`.

## Step 2: services on the emulator (no voice)

The brief's `cmd package query-intent-services` does not exist on this Android (`Unknown command`).
Equivalent used: `pm query-services -a <action>`.

- `android.speech.RecognitionService`: 2 services found; the first is
  `com.google.android.as/...AiAiSpeechRecognitionService` (Device Personalization, on-device).
- `android.intent.action.TTS_SERVICE`: 1 service,
  `com.google.android.tts/...GoogleTtsService`.
- `settings get secure voice_recognition_service`:
  `com.google.android.tts/com.google.android.apps.speech.tts.googletts.service.GoogleTTSRecognitionService`.
- `settings get secure tts_default_synth`: `null`.
- Risk 1 of the spec (no recognition service) has NOT materialized.

## Spike screen without a voice (emulator)

- Launches without crashing. RECORD_AUDIO granted with `adb install -g` / `pm grant`.
- `SpeechToText.initialize()` = true.
- `locales()`: 10 total, only Spanish one is `es_ES` (no `es_MX`); chosen locale `es_ES`.
- TTS: `es-ES` and `es-US` listed (no `es-MX`), 421 voices matching "es" (substring, loose).

## Android emulator

What the preview run found without a voice, from the project ledger:

- The offline Spanish recognition pack for `es-ES` is missing on the emulator (error 13), so the
  online recognizer is used.
- The default recognition service is `com.google.android.tts` (`GoogleTTSRecognitionService`).
- The system microphone indicator stays on for about 0.3 s after a cancel (recognizer shutdown lag).

A test with a real voice on the emulator has not been recorded yet.

## Chrome

Two problems appeared once the real screens ran in Chrome. Both were fixed in the app, not in the
packages.

- Speech was recognized in English. On web, `speech_to_text 7.5.0` cannot list locales, so the list
  was empty, no locale was passed to the recognizer, and Chrome fell back to the page language
  (`en-US`). Fix: ask for `es-MX` on web when no Spanish locale is listed (commit `97a2738`).
  Checked at runtime: the recognizer starts with `lang: "es-MX"`.
- The first reply was not spoken in Spanish. Chrome loads its voices late, so the first request for
  the language list returned an empty list and the choice was cached for the whole session. Fix: an
  empty list is retried at the next reply, and the list is requested once at construction so the
  voices are loaded before the first reply (commit `2876fdc`). Checked at runtime: 19 voices were
  loaded before any press, and the first reply went out as `es-US` with the voice "Google español de
  Estados Unidos" (before the fix: no language, no voice).

Retest with a real voice on 2026-11-24: Gustavo said "quiero que añadas que tengo que hacer la
tarea" in Chrome and it was recognized in Spanish, word for word. The reply as spoken aloud with his
voice was not recorded here; the Spanish voice was checked only by the runtime check above. The
retest also showed that the app saved the whole phrase as the task title, because the phrase parser
at that time only removed a leading "agrega", "añade", "anota" or "recuérdame"; that is a parser
matter, not a speech one. The parser was extended the same day (commits `5642752` and `4226170`)
and that phrase now gives the task "Hacer la tarea".

## Decision

Keep `speech_to_text` and `flutter_tts`. Known limits:

- The emulator offers `es_ES`, not `es_MX`; the voices are `es-ES` and `es-US`.
- On the web, only Chrome works.
