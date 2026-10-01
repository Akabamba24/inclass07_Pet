import 'dart:async';

import 'package:flutter/foundation.dart';

enum PetMood { unhappy, neutral, happy }

enum PetOutcome { playing, won, lost }

enum PetActivity { run, fetch, sleep }

@immutable
class PetState {
  const PetState({
    required this.name,
    required this.happiness,
    required this.hunger,
    required this.energy,
    this.activity = PetActivity.fetch,
    this.outcome = PetOutcome.playing,
  });

  factory PetState.initial({String name = 'Pip'}) =>
      PetState(name: name, happiness: 70, hunger: 35, energy: 75);

  final String name;
  final int happiness;
  final int hunger;
  final int energy;
  final PetActivity activity;
  final PetOutcome outcome;

  PetMood get mood => PetRules.moodFor(happiness);

  PetState copyWith({
    String? name,
    int? happiness,
    int? hunger,
    int? energy,
    PetActivity? activity,
    PetOutcome? outcome,
  }) => PetState(
    name: name ?? this.name,
    happiness: happiness ?? this.happiness,
    hunger: hunger ?? this.hunger,
    energy: energy ?? this.energy,
    activity: activity ?? this.activity,
    outcome: outcome ?? this.outcome,
  );
}

/// Pure state transitions for care actions. Widgets do not own game rules.
abstract final class PetRules {
  static int clampMeter(int value) => value.clamp(0, 100).toInt();

  static PetMood moodFor(int happiness) {
    if (happiness < 30) return PetMood.unhappy;
    if (happiness > 70) return PetMood.happy;
    return PetMood.neutral;
  }

  static PetState rename(PetState state, String name) {
    final normalized = name.trim();
    if (normalized.isEmpty) return state;
    return state.copyWith(name: normalized);
  }

  static PetState feed(PetState state) {
    final nextHunger = clampMeter(state.hunger - 10);
    final happinessDelta = nextHunger < 30 ? -20 : 10;
    return state.copyWith(
      hunger: nextHunger,
      happiness: clampMeter(state.happiness + happinessDelta),
    );
  }

  static PetState play(PetState state) {
    if (state.energy < 15) return state;
    return state.copyWith(
      happiness: clampMeter(state.happiness + 15),
      hunger: clampMeter(state.hunger + 5),
      energy: clampMeter(state.energy - 15),
    );
  }

  static PetState selectActivity(PetState state, PetActivity activity) =>
      state.copyWith(activity: activity);

  static PetState doActivity(PetState state) => switch (state.activity) {
    PetActivity.run when state.energy >= 25 => state.copyWith(
      happiness: clampMeter(state.happiness + 20),
      hunger: clampMeter(state.hunger + 10),
      energy: clampMeter(state.energy - 25),
    ),
    PetActivity.fetch when state.energy >= 10 => state.copyWith(
      happiness: clampMeter(state.happiness + 12),
      hunger: clampMeter(state.hunger + 5),
      energy: clampMeter(state.energy - 10),
    ),
    PetActivity.sleep => state.copyWith(
      happiness: clampMeter(state.happiness + 5),
      hunger: clampMeter(state.hunger + 5),
      energy: clampMeter(state.energy + 35),
    ),
    _ => state,
  };

  /// Hunger reaches 100 before the following overflow tick costs happiness.
  static PetState hungerTick(PetState state) {
    if (state.hunger < 100) {
      return state.copyWith(hunger: clampMeter(state.hunger + 5));
    }
    return state.copyWith(
      hunger: 100,
      happiness: clampMeter(state.happiness - 20),
    );
  }
}

/// Owns game timers and terminal rules; the screen owns and disposes this service.
class PetCareController extends ChangeNotifier {
  PetCareController({
    PetState? initialState,
    this.hungerInterval = const Duration(seconds: 30),
    this.winDuration = const Duration(minutes: 3),
  }) : _state = initialState ?? PetState.initial();

  final Duration hungerInterval;
  final Duration winDuration;
  PetState _state;
  Timer? _hungerTimer;
  Timer? _winTimer;
  bool _started = false;
  bool _disposed = false;
  int _hungerTimerStarts = 0;

  PetState get state => _state;
  bool get canCare => _state.outcome == PetOutcome.playing;

  @visibleForTesting
  int get hungerTimerStarts => _hungerTimerStarts;

  @visibleForTesting
  bool get hasActiveHungerTimer => _hungerTimer?.isActive ?? false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _startHungerTimer();
    _resolveOutcome();
    notifyListeners();
  }

  void rename(String name) => _apply(PetRules.rename(_state, name));

  void feed() => _act(PetRules.feed);

  void play() => _act(PetRules.play);

  void selectActivity(PetActivity activity) =>
      _act((state) => PetRules.selectActivity(state, activity));

  void doSelectedActivity() => _act(PetRules.doActivity);

  void _act(PetState Function(PetState) action) {
    if (!canCare || _disposed) return;
    _apply(action(_state));
  }

  void _apply(PetState next) {
    if (_disposed || identical(next, _state)) return;
    _state = next;
    _resolveOutcome();
    notifyListeners();
  }

  void _startHungerTimer() {
    _hungerTimer?.cancel();
    if (_disposed || _state.outcome != PetOutcome.playing) return;
    _hungerTimerStarts++;
    _hungerTimer = Timer.periodic(hungerInterval, (_) => _onHungerTick());
  }

  void _onHungerTick() {
    if (_disposed || !canCare) return;
    _state = PetRules.hungerTick(_state);
    _resolveOutcome();
    notifyListeners();
  }

  void _resolveOutcome() {
    if (_state.outcome != PetOutcome.playing) {
      _stopTimers();
      return;
    }
    if (_state.hunger == 100 && _state.happiness <= 10) {
      _state = _state.copyWith(outcome: PetOutcome.lost);
      _stopTimers();
      return;
    }
    if (_state.happiness > 80) {
      _winTimer ??= Timer(winDuration, _finishWin);
    } else {
      _winTimer?.cancel();
      _winTimer = null;
    }
  }

  void _finishWin() {
    _winTimer = null;
    if (_disposed ||
        _state.outcome != PetOutcome.playing ||
        _state.happiness <= 80) {
      return;
    }
    _state = _state.copyWith(outcome: PetOutcome.won);
    _stopTimers();
    notifyListeners();
  }

  void _stopTimers() {
    _hungerTimer?.cancel();
    _hungerTimer = null;
    _winTimer?.cancel();
    _winTimer = null;
  }

  void reset() {
    if (_disposed) return;
    _stopTimers();
    _state = PetState.initial(name: _state.name);
    if (_started) _startHungerTimer();
    _resolveOutcome();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    super.dispose();
  }
}
