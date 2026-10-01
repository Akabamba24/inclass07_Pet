// In-Class Activity 07 — Digital Pet
// Student: Augustin Kabamba (solo contributor)
// Date: October 1, 2026

import 'dart:async';

import 'package:flutter/material.dart';

import 'pet/pet_game.dart';

void main() => runApp(const DigitalPetApp());

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Pip’s Pet Care',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF58A889),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF101A19),
      useMaterial3: true,
    ),
    home: const PetHomePage(),
  );
}

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage>
    with SingleTickerProviderStateMixin {
  late final PetCareController _game;
  final TextEditingController _nameController = TextEditingController(
    text: 'Pip',
  );
  late final AnimationController _breathingController;
  late final Animation<double> _breathingScale;
  Timer? _bounceTimer;
  Timer? _reactionTimer;
  String? _reaction;
  bool _bouncing = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _game = PetCareController()..addListener(_onGameChanged);
    _game.start();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _breathingScale = Tween<double>(begin: 1, end: 1.018).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce == _reduceMotion &&
        (_breathingController.isAnimating || reduce)) {
      return;
    }
    _reduceMotion = reduce;
    if (reduce) {
      _breathingController
        ..stop()
        ..value = 0;
    } else {
      _breathingController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceTimer?.cancel();
    _reactionTimer?.cancel();
    _game
      ..removeListener(_onGameChanged)
      ..dispose();
    _nameController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  PetState get _pet => _game.state;

  Color get _moodColor => switch (_pet.mood) {
    PetMood.unhappy => const Color(0xFFFF7777),
    PetMood.neutral => const Color(0xFFFFD166),
    PetMood.happy => const Color(0xFF70D69B),
  };

  String get _moodLabel => switch (_pet.mood) {
    PetMood.unhappy => 'Needs some love',
    PetMood.neutral => 'Doing okay',
    PetMood.happy => 'Feeling great',
  };

  String get _petMessage {
    if (_pet.outcome == PetOutcome.won) {
      return 'Best day ever!';
    }
    if (_pet.outcome == PetOutcome.lost) {
      return 'I need a little care. Restart?';
    }
    if (_pet.hunger > 80) {
      return 'I’m getting hungry…';
    }
    if (_pet.happiness < 30) {
      return 'Will you play with me?${_pet.name} is lonley';
    }
    if (_pet.energy < 20) {
      return 'A nap would help!{_pet.name} needs to rest';
    }
    return 'Hi, I’m ${_pet.name}!';
  }

  String get _expression => switch (_pet.mood) {
    PetMood.unhappy => '🙁',
    PetMood.neutral => '😌',
    PetMood.happy => '😸',
  };

  double get _moodScale {
    if (_reduceMotion) return 1;
    return switch (_pet.mood) {
      PetMood.unhappy => .94,
      PetMood.neutral => 1,
      PetMood.happy => 1.06,
    };
  }

  void _confirmName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showMessage('Enter a name for your pet first.');
      return;
    }
    _game.rename(name);
    _nameController.text = _game.state.name;
    FocusScope.of(context).unfocus();
    _showMessage('Hello, ${_game.state.name}!');
  }

  void _careAction(VoidCallback action, String reaction) {
    if (!_game.canCare) return;
    final oldState = _pet;
    action();
    if (identical(_pet, oldState)) {
      _showMessage('Pip needs more energy. Try a nap.');
      return;
    }
    _animateAction(reaction);
  }

  void _animateAction(String reaction) {
    _bounceTimer?.cancel();
    _reactionTimer?.cancel();
    setState(() {
      _bouncing = true;
      _reaction = reaction;
    });
    _bounceTimer = Timer(const Duration(milliseconds: 260), () {
      if (!mounted) return;
      setState(() => _bouncing = false);
    });
    _reactionTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      setState(() => _reaction = null);
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _resetGame() {
    _bounceTimer?.cancel();
    _reactionTimer?.cancel();
    _game.reset();
    setState(() {
      _bouncing = false;
      _reaction = null;
    });
    _showMessage('A fresh start for ${_game.state.name}.');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pip’s Pet Care', style: TextStyle(fontSize: 19)),
          Text('A tiny world to look after', style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(
          key: const Key('reset-button'),
          tooltip: 'Restart pet care',
          onPressed: _resetGame,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final petCard = _buildPetCard();
          final details = _buildDetails();
          if (constraints.maxWidth > constraints.maxHeight) {
            return Row(
              children: [
                Expanded(flex: 6, child: petCard),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 16, 20),
                    child: details,
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              Expanded(flex: 5, child: petCard),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: details,
                ),
              ),
            ],
          );
        },
      ),
    ),
  );

  Widget _buildPetCard() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF192623),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .07)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            'PIP’S LITTLE WORLD',
            style: TextStyle(
              color: _moodColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final petSize = constraints.biggest.shortestSide * .88;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedScale(
                      scale: _bouncing ? 1.1 : 1,
                      duration: _reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: AnimatedBuilder(
                        animation: _breathingScale,
                        builder: (context, child) => Transform.scale(
                          scale: _reduceMotion ? 1 : _breathingScale.value,
                          child: child,
                        ),
                        child: Transform.scale(
                          scale: _moodScale,
                          child: Semantics(
                            image: true,
                            label: '${_pet.name}, ${_moodLabel.toLowerCase()}',
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                _moodColor,
                                BlendMode.modulate,
                              ),
                              child: Image.asset(
                                'assets/pip.png',
                                key: const Key('pet-image'),
                                width: petSize,
                                height: petSize,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: constraints.maxWidth * .08,
                      top: constraints.maxHeight * .12,
                      child: AnimatedSlide(
                        offset: _reaction == null
                            ? const Offset(0, .35)
                            : Offset.zero,
                        duration: _reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 180),
                        child: AnimatedOpacity(
                          opacity: _reaction == null ? 0 : 1,
                          duration: _reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 180),
                          child: Text(
                            _reaction ?? '',
                            style: const TextStyle(fontSize: 30),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          AnimatedSwitcher(
            duration: _reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: Padding(
              key: ValueKey('$_expression-$_petMessage'),
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_expression, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _petMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _moodLabel,
                    style: TextStyle(
                      color: _moodColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDetails() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildNameEditor(),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: Text(
              'PET STATUS',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          _outcomeBadge(),
        ],
      ),
      const SizedBox(height: 9),
      _meter('Happiness', _pet.happiness, _moodColor, Icons.favorite_rounded),
      _meter(
        'Hunger',
        _pet.hunger,
        const Color(0xFFFFA45B),
        Icons.restaurant_rounded,
      ),
      _meter(
        'Energy',
        _pet.energy,
        const Color(0xFF73B9FF),
        Icons.bolt_rounded,
      ),
      const SizedBox(height: 10),
      _buildCareActions(),
      const SizedBox(height: 6),
      Text(
        'Every 30 seconds hunger rises by 5. Keep happiness above 80 for 3 minutes to win.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    ],
  );

  Widget _buildNameEditor() => Row(
    children: [
      Expanded(
        child: TextField(
          key: const Key('pet-name-field'),
          controller: _nameController,
          textInputAction: TextInputAction.done,
          maxLength: 18,
          decoration: const InputDecoration(
            labelText: 'Pet name',
            counterText: '',
            prefixIcon: Icon(Icons.pets_rounded),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _confirmName(),
        ),
      ),
      const SizedBox(width: 8),
      FilledButton(
        key: const Key('confirm-name-button'),
        onPressed: _confirmName,
        child: const Text('Save'),
      ),
    ],
  );

  Widget _outcomeBadge() {
    final (label, icon) = switch (_pet.outcome) {
      PetOutcome.playing => ('PLAYING', Icons.spa_rounded),
      PetOutcome.won => ('WINNER', Icons.emoji_events_rounded),
      PetOutcome.lost => ('NEEDS CARE', Icons.favorite_border_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _moodColor.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _moodColor),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: _moodColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _meter(String label, int value, Color color, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(
              '$value / 100',
              key: Key('meter-$label'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value / 100),
          duration: _reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          builder: (context, progress, _) => Semantics(
            label: '$label, $value out of 100',
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              borderRadius: BorderRadius.circular(12),
              color: color,
              backgroundColor: Colors.white.withValues(alpha: .08),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildCareActions() {
    final canAct = _game.canCare;
    final enoughPlayEnergy = _pet.energy >= 15;
    final enoughActivityEnergy = switch (_pet.activity) {
      PetActivity.run => _pet.energy >= 25,
      PetActivity.fetch => _pet.energy >= 10,
      PetActivity.sleep => true,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CARE ACTIONS',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('feed-button'),
                onPressed: canAct ? () => _careAction(_game.feed, '🥕') : null,
                icon: const Icon(Icons.restaurant_rounded),
                label: const Text('Feed'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('play-button'),
                onPressed: canAct && enoughPlayEnergy
                    ? () => _careAction(_game.play, '🎾')
                    : null,
                icon: const Icon(Icons.sports_baseball_rounded),
                label: const Text('Play · 15 energy'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<PetActivity>(
          key: const Key('activity-picker'),
          initialValue: _pet.activity,
          selectedItemBuilder: (context) => PetActivity.values
              .map(
                (activity) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_activityShortLabel(activity)),
                ),
              )
              .toList(),
          decoration: const InputDecoration(
            labelText: 'Choose an activity',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_run_rounded),
          ),
          items: PetActivity.values
              .map(
                (activity) => DropdownMenuItem<PetActivity>(
                  value: activity,
                  child: Text(_activityLabel(activity)),
                ),
              )
              .toList(),
          onChanged: canAct
              ? (activity) {
                  if (activity != null) _game.selectActivity(activity);
                }
              : null,
        ),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          key: const Key('do-activity-button'),
          onPressed: canAct && enoughActivityEnergy
              ? () => _careAction(
                  _game.doSelectedActivity,
                  _activityReaction(_pet.activity),
                )
              : null,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_activityActionLabel(_pet.activity)),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            'Run costs 25 energy · Fetch costs 10 · Sleep restores 35.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        if (_pet.outcome != PetOutcome.playing) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Start a new day'),
          ),
        ],
      ],
    );
  }

  static String _activityLabel(PetActivity activity) => switch (activity) {
    PetActivity.run => 'Run · costs 25 energy',
    PetActivity.fetch => 'Play fetch · costs 10 energy',
    PetActivity.sleep => 'Take a nap · restores 35 energy',
  };

  static String _activityShortLabel(PetActivity activity) => switch (activity) {
    PetActivity.run => 'Run',
    PetActivity.fetch => 'Fetch',
    PetActivity.sleep => 'Sleep',
  };

  static String _activityActionLabel(PetActivity activity) =>
      switch (activity) {
        PetActivity.run => 'Go for a run',
        PetActivity.fetch => 'Play fetch',
        PetActivity.sleep => 'Take a nap',
      };

  static String _activityReaction(PetActivity activity) => switch (activity) {
    PetActivity.run => '🏃',
    PetActivity.fetch => '🎾',
    PetActivity.sleep => '💤',
  };
}
