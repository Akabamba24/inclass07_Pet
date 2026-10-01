# Architecture and design trade-off

## Ownership boundary

`PetRules` in `lib/pet/pet_game.dart` is a pure transition layer: given an immutable `PetState`, it returns the next state for a care action, mood lookup, or hunger tick. It owns meter clamping and the action rules. The rules do not import Flutter widgets and are directly unit tested.

`PetCareController` owns the current game state, the periodic hunger timer, the one-shot win timer, and terminal/reset behavior. It notifies the screen after state transitions. The `PetHomePage` owns presentation-only resources: text input, animation controllers, and short-lived bounce/reaction callbacks. `dispose()` releases each resource at the layer that created it. Widgets render state and invoke controller actions; they do not decide game rules.

## Decision: controller-owned timers instead of widget-owned game timers

Both timers live in one small `ChangeNotifier` controller. This keeps the win and loss rules next to state transitions, makes `reset()` responsible for canceling and replacing the hunger timer once, and lets tests advance time without pumping a UI. The trade-off is a small controller abstraction and listener lifecycle to manage; for this single-screen app, it keeps presentation code simpler without introducing a larger state-management package.

The screen still owns its breathing controller and UI feedback timers because those resources exist only for presentation. The controller cancels the hunger and win timers on terminal outcomes and disposal; the screen cancels its feedback timers and disposes both its `AnimationController` and `TextEditingController`.

## Test evidence

Run `flutter test` for the pure rules and controller suite. It checks 29/30/70/71 mood boundaries, meter clamping, feed/play/activity transitions, hunger 95→100→overflow, exact three-minute win, cancellation after happiness falls below 81, loss, reset timer count, and disposal. The win timer is exercised with `fake_async`, so the production timer remains three minutes and is not shortened for tests.
