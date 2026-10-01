import 'package:digital_pet/pet/pet_game.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PetRules', () {
    test('mood thresholds match the four boundary values', () {
      expect(PetRules.moodFor(29), PetMood.unhappy);
      expect(PetRules.moodFor(30), PetMood.neutral);
      expect(PetRules.moodFor(70), PetMood.neutral);
      expect(PetRules.moodFor(71), PetMood.happy);
    });

    test('feed clamps hunger and applies happiness rule after feeding', () {
      final low = PetRules.feed(PetState.initial().copyWith(hunger: 5));
      expect(low.hunger, 0);
      expect(low.happiness, 50);

      final threshold = PetRules.feed(
        PetState.initial().copyWith(hunger: 40, happiness: 90),
      );
      expect(threshold.hunger, 30);
      expect(threshold.happiness, 100);

      final tooHungry = PetRules.feed(
        PetState.initial().copyWith(hunger: 35, happiness: 90),
      );
      expect(tooHungry.hunger, 25);
      expect(tooHungry.happiness, 70);
    });

    test('play and selected activities clamp meters and charge energy', () {
      final played = PetRules.play(
        PetState.initial().copyWith(happiness: 95, hunger: 98, energy: 15),
      );
      expect((played.happiness, played.hunger, played.energy), (100, 100, 0));
      expect(PetRules.play(played), same(played));
      final almostExhausted = PetState.initial().copyWith(
        energy: 14,
        happiness: 40,
      );
      expect(PetRules.play(almostExhausted), same(almostExhausted));

      final start = PetState.initial().copyWith(energy: 40);
      final running = PetRules.doActivity(
        PetRules.selectActivity(start, PetActivity.run),
      );
      expect((running.happiness, running.hunger, running.energy), (90, 45, 15));
      final tooTiredToRun = PetRules.selectActivity(
        start.copyWith(energy: 24),
        PetActivity.run,
      );
      expect(PetRules.doActivity(tooTiredToRun), same(tooTiredToRun));

      final fetching = PetRules.doActivity(
        PetRules.selectActivity(start, PetActivity.fetch),
      );
      expect(
        (fetching.happiness, fetching.hunger, fetching.energy),
        (82, 40, 30),
      );
      final tooTiredToFetch = PetRules.selectActivity(
        start.copyWith(energy: 9),
        PetActivity.fetch,
      );
      expect(PetRules.doActivity(tooTiredToFetch), same(tooTiredToFetch));

      final resting = PetRules.doActivity(
        PetRules.selectActivity(start, PetActivity.sleep),
      );
      expect((resting.happiness, resting.hunger, resting.energy), (75, 40, 75));
      expect(PetRules.clampMeter(105), 100);
      expect(PetRules.clampMeter(-5), 0);
    });

    test('hunger reaches 100 before overflow reduces happiness', () {
      final at95 = PetState.initial().copyWith(hunger: 95, happiness: 50);
      final at100 = PetRules.hungerTick(at95);
      expect((at100.hunger, at100.happiness), (100, 50));
      final overflow = PetRules.hungerTick(at100);
      expect((overflow.hunger, overflow.happiness), (100, 30));
    });

    test('name is trimmed and an empty name is ignored', () {
      final state = PetState.initial();
      expect(PetRules.rename(state, '  Miso  ').name, 'Miso');
      expect(PetRules.rename(state, '  '), same(state));
    });
  });

  group('PetCareController timers and outcomes', () {
    test('win requires happiness above 80 for three continuous minutes', () {
      fakeAsync((async) {
        final controller = PetCareController(
          initialState: PetState.initial().copyWith(
            happiness: 81,
            hunger: 0,
            energy: 100,
          ),
        )..start();

        async.elapse(const Duration(minutes: 2, seconds: 59));
        expect(controller.state.outcome, PetOutcome.playing);
        controller.play(); // Raises happiness while the threshold remains met.
        async.elapse(const Duration(seconds: 1));
        expect(controller.state.outcome, PetOutcome.won);
        expect(controller.hasActiveHungerTimer, isFalse);
        controller.dispose();
      });
    });

    test('dropping to exactly 80 cancels the pending win timer', () {
      fakeAsync((async) {
        final controller = PetCareController(
          initialState: PetState.initial().copyWith(
            happiness: 100,
            hunger: 0,
            energy: 100,
          ),
        )..start();

        async.elapse(const Duration(minutes: 2, seconds: 59));
        controller.feed(); // Resulting hunger < 30 costs 20 happiness.
        expect(controller.state.happiness, 80);
        async.elapse(const Duration(seconds: 1));
        expect(controller.state.outcome, PetOutcome.playing);

        controller.dispose();
      });
    });

    test('loss occurs at hunger 100 and happiness 10 or lower', () {
      fakeAsync((async) {
        final controller = PetCareController(
          initialState: PetState.initial().copyWith(
            happiness: 30,
            hunger: 95,
            energy: 100,
          ),
        )..start();

        async.elapse(const Duration(seconds: 30));
        expect(controller.state.hunger, 100);
        expect(controller.state.happiness, 30);
        async.elapse(const Duration(seconds: 30));
        expect(controller.state.hunger, 100);
        expect(controller.state.happiness, 10);
        expect(controller.state.outcome, PetOutcome.lost);
        expect(controller.hasActiveHungerTimer, isFalse);
        controller.feed();
        expect(controller.state.hunger, 100);
        controller.dispose();
      });
    });

    test('reset restarts exactly one hunger timer and dispose cancels it', () {
      fakeAsync((async) {
        final controller = PetCareController(
          hungerInterval: const Duration(seconds: 30),
        )..start();
        expect(controller.hungerTimerStarts, 1);
        async.elapse(const Duration(seconds: 30));
        expect(controller.state.hunger, 40);

        controller.reset();
        expect(controller.hungerTimerStarts, 2);
        expect(controller.hasActiveHungerTimer, isTrue);
        expect(controller.state.hunger, 35);
        async.elapse(const Duration(seconds: 30));
        expect(controller.state.hunger, 40);

        controller.dispose();
        expect(controller.hasActiveHungerTimer, isFalse);
        async.elapse(const Duration(minutes: 2));
        expect(controller.state.hunger, 40);
      });
    });
  });
}
