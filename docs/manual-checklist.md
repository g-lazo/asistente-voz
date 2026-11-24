# Manual checklist

The voice paths cannot be covered by unit tests, so they are checked by hand. Run the script once on
each target, from a clean start (no signed-in session, no tasks for the test account), and write
`pass` or `fail` in the last column. Anything that fails goes back as a bug with the row number.

- Android emulator: start it with `make emulator`, then `make android`.
- Chrome: run `make web` and open `http://localhost:8080` in Chrome. Allow the microphone when asked.

The UI is in Spanish; the quoted texts below are exactly what the app shows. To "hold" the
microphone on both targets, press the mouse button on it and keep it down. Use two different
accounts for rows 1 and 8 (for example `uno@example.com` and `dos@example.com`, any password of at
least 6 characters).

## Android emulator

| # | Step | Expected result | Pass/fail |
|---|------|-----------------|-----------|
| 1 | On the sign-in screen choose "Crear cuenta", enter an email and a password, and submit. | The home screen opens on the "Asistente" tab. The first bubble reads "Hola. Mantén presionado el micrófono y dime qué quieres anotar. Por ejemplo: "agrega comprar leche mañana"." and the hint under the microphone reads "Mantén presionado para hablar". | |
| 2 | Hold the microphone and say "agrega comprar leche", then release. | While held, the hint reads "Suelta para enviar · desliza a la izquierda para cancelar" and the words appear above the button as you speak. After release a user bubble shows the phrase, and the assistant bubble reads `Listo, agregué "Comprar leche". Llevas 1 pendiente.` The same sentence is spoken aloud. The "Mis tareas" tab title shows (1), and "Comprar leche" is listed with no date. The document appears in the Firebase console under `users/<uid>/tasks`. | |
| 3 | Hold and say "recuérdame pagar el internet el viernes", then release. | The assistant bubble says `Listo, agregué "Pagar el internet" para el viernes ...` with the date of the next Friday after today (for example "viernes 20 de noviembre" when run on Thursday 19 November 2026), followed by "Llevas 2 pendientes.". In "Mis tareas" the row shows the short label for that Friday, such as "vie 20 nov". | |
| 4 | Hold, start talking, slide the pointer to the left, and release. | While sliding the hint reads "Suelta para cancelar". After release the hint shows "Cancelado" briefly, no user bubble is added, no answer is given, and "Mis tareas" and the Firebase console are unchanged. | |
| 5 | In "Mis tareas", tick the checkbox of one task, untick it, tick it again. Then press the delete button of a task and confirm. | A ticked task is struck through and moves to the bottom of the list, and the pending count in the tab title drops by one. Unticking brings it back. The delete button asks "¿Eliminar esta tarea?"; "Eliminar" removes the row, "Cancelar" keeps it. | |
| 6 | Press the mute button in the app bar (tooltip "Silenciar voz"), then dictate "agrega regar las plantas". | The icon changes (tooltip becomes "Activar voz"). The assistant bubble appears with `Listo, agregué "Regar las plantas". Llevas ...` (with the current pending count) but nothing is spoken. | |
| 7 | Press sign out (tooltip "Cerrar sesión"), then sign in again with the same account. Also close and reopen the app. | The sign-in screen appears after signing out. After signing in, the same tasks are listed in the same order. After closing and reopening, the app goes straight to the home screen without asking for credentials. | |
| 8 | Sign out, then create or sign in with a second account. | The assistant opens with the greeting only, the "Mis tareas" tab shows 0 pending and the message "Aún no tienes tareas. Ve al Asistente y dicta la primera." None of the first account's tasks are visible. | |
| 9 | Hold the microphone, say a few words ("agrega comprar"), pause for about three seconds without releasing, then say the rest ("pan") and release. | The phrase in the user bubble contains both parts ("comprar pan"); the words said before the pause are not lost. One task "Comprar pan" is saved. | |
| 10 | Turn the network off (on the emulator, enable airplane mode), then dictate "agrega llamar al banco". | After about 10 seconds the assistant bubble reads "No pude guardar la tarea. Revisa tu conexión e inténtalo otra vez." No "Listo" answer is given. After the network is back on, "Llamar al banco" does not appear in "Mis tareas". If speech recognition itself fails while offline, write that in the cell and repeat the row going offline right after the phrase is recognized. | |

## Chrome

| # | Step | Expected result | Pass/fail |
|---|------|-----------------|-----------|
| 1 | On the sign-in screen choose "Crear cuenta", enter an email and a password, and submit. | The home screen opens on the "Asistente" tab. The first bubble reads "Hola. Mantén presionado el micrófono y dime qué quieres anotar. Por ejemplo: "agrega comprar leche mañana"." and the hint under the microphone reads "Mantén presionado para hablar". | |
| 2 | Hold the microphone and say "agrega comprar leche", then release. | While held, the hint reads "Suelta para enviar · desliza a la izquierda para cancelar" and the words appear above the button as you speak. After release a user bubble shows the phrase, and the assistant bubble reads `Listo, agregué "Comprar leche". Llevas 1 pendiente.` The same sentence is spoken aloud. The "Mis tareas" tab title shows (1), and "Comprar leche" is listed with no date. The document appears in the Firebase console under `users/<uid>/tasks`. | |
| 3 | Hold and say "recuérdame pagar el internet el viernes", then release. | The assistant bubble says `Listo, agregué "Pagar el internet" para el viernes ...` with the date of the next Friday after today (for example "viernes 20 de noviembre" when run on Thursday 19 November 2026), followed by "Llevas 2 pendientes.". In "Mis tareas" the row shows the short label for that Friday, such as "vie 20 nov". | |
| 4 | Hold, start talking, slide the pointer to the left, and release. | While sliding the hint reads "Suelta para cancelar". After release the hint shows "Cancelado" briefly, no user bubble is added, no answer is given, and "Mis tareas" and the Firebase console are unchanged. | |
| 5 | In "Mis tareas", tick the checkbox of one task, untick it, tick it again. Then press the delete button of a task and confirm. | A ticked task is struck through and moves to the bottom of the list, and the pending count in the tab title drops by one. Unticking brings it back. The delete button asks "¿Eliminar esta tarea?"; "Eliminar" removes the row, "Cancelar" keeps it. | |
| 6 | Press the mute button in the app bar (tooltip "Silenciar voz"), then dictate "agrega regar las plantas". | The icon changes (tooltip becomes "Activar voz"). The assistant bubble appears with `Listo, agregué "Regar las plantas". Llevas ...` (with the current pending count) but nothing is spoken. | |
| 7 | Press sign out (tooltip "Cerrar sesión"), then sign in again with the same account. Also reload the page. | The sign-in screen appears after signing out. After signing in, the same tasks are listed in the same order. After reloading, the app goes straight to the home screen without asking for credentials. | |
| 8 | Sign out, then create or sign in with a second account. | The assistant opens with the greeting only, the "Mis tareas" tab shows 0 pending and the message "Aún no tienes tareas. Ve al Asistente y dicta la primera." None of the first account's tasks are visible. | |
| 9 | Hold the microphone, say a few words ("agrega comprar"), pause for about three seconds without releasing, then say the rest ("pan") and release. | The phrase in the user bubble contains both parts ("comprar pan"); the words said before the pause are not lost. One task "Comprar pan" is saved. | |
| 10 | Turn the network off (in Chrome DevTools, Network tab, choose "Offline"), then dictate "agrega llamar al banco". | After about 10 seconds the assistant bubble reads "No pude guardar la tarea. Revisa tu conexión e inténtalo otra vez." No "Listo" answer is given. After the network is back on, "Llamar al banco" does not appear in "Mis tareas". Chrome recognizes speech through an online service, so recognition may fail while offline; if it does, write that in the cell and note that the offline save could not be exercised from Chrome. | |
