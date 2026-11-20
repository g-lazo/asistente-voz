import 'package:material_ui/material_ui.dart';

import 'assistant_controller.dart';

class AssistantTab extends StatelessWidget {
  const AssistantTab({super.key, required this.controller});

  final AssistantController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final messages = controller.messages;
        return SafeArea(
          child: Column(
            children: [
              Expanded(
                // Reversed so the newest bubble sits at the bottom and stays
                // in view without a scroll controller.
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, i) =>
                      _Bubble(message: messages[messages.length - 1 - i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 24),
                  child: Text(
                    controller.partial,
                    key: const Key('partialText'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              _MicButton(controller: controller),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  controller.hint,
                  key: const Key('hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fromUser = message.fromUser;
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        decoration: BoxDecoration(
          color: fromUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: round,
            topRight: round,
            bottomLeft: fromUser ? round : tail,
            bottomRight: fromUser ? tail : round,
          ),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: fromUser ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}

/// Maps pointer events on the button to the controller's press, drag and
/// release. A Listener (not a button) so a hold is not a tap.
class _MicButton extends StatefulWidget {
  const _MicButton({required this.controller});

  final AssistantController controller;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton> {
  double _startX = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = widget.controller.state;
    final listening = state == MicState.listening;
    final armed = state == MicState.cancelArmed;
    final size = listening || armed ? 96.0 : 72.0;
    final fill = armed ? scheme.error : scheme.primary;
    final onFill = armed ? scheme.onError : scheme.onPrimary;
    final halo = armed ? scheme.errorContainer : scheme.primaryContainer;
    return Semantics(
      button: true,
      label: 'Micrófono',
      child: Listener(
        onPointerDown: (e) {
          _startX = e.position.dx;
          widget.controller.pressStart();
        },
        onPointerMove: (e) =>
            widget.controller.dragUpdate(e.position.dx - _startX),
        onPointerUp: (_) => widget.controller.pressEnd(),
        onPointerCancel: (_) => widget.controller.pressEnd(),
        // Competes with the pager's horizontal drag so sliding to cancel does
        // not turn the page; the Listener above still sees every pointer.
        child: GestureDetector(
          onHorizontalDragStart: (_) {},
          onHorizontalDragUpdate: (_) {},
          onHorizontalDragEnd: (_) {},
          child: SizedBox(
            key: const Key('micButton'),
            width: 128,
            height: 128,
            child: Center(
              child: Container(
                width: size + 24,
                height: size + 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening || armed ? halo : null,
                ),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                  ),
                  child: Icon(
                    armed ? Icons.close : Icons.mic,
                    color: onFill,
                    size: size * 0.45,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
