import 'package:digital_pet/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pet screen renders status and applies a feed action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DigitalPetApp());
    await tester.pump();

    expect(find.text('Pip’s Pet Care'), findsOneWidget);
    expect(find.text('70 / 100'), findsOneWidget);
    expect(find.text('35 / 100'), findsOneWidget);
    expect(find.text('75 / 100'), findsOneWidget);
    expect(find.text('Doing okay'), findsOneWidget);
    expect(find.byKey(const Key('pet-image')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feed-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('50 / 100'), findsOneWidget);
    expect(find.text('25 / 100'), findsOneWidget);
  });

  testWidgets('saving a pet name updates the derived pet message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DigitalPetApp());
    await tester.pump();
    await tester.enterText(find.byKey(const Key('pet-name-field')), 'Miso');
    await tester.tap(find.byKey(const Key('confirm-name-button')));
    await tester.pump();

    expect(find.text('Hi, I’m Miso!'), findsOneWidget);
    expect(find.bySemanticsLabel('Miso, doing okay'), findsOneWidget);
  });

  testWidgets('reduced-motion mode renders and screen cleanup is safe', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: const PetHomePage(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Hi, I’m Pip!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 31));
    expect(tester.takeException(), isNull);
  });

  testWidgets('energy disables care and a nap restores it', (tester) async {
    tester.view.physicalSize = const Size(440, 956);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DigitalPetApp());
    await tester.pump();

    for (var action = 0; action < 5; action++) {
      await tester.tap(find.byKey(const Key('play-button')));
      await tester.pump(const Duration(milliseconds: 60));
    }
    expect(find.text('0 / 100'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('play-button')))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byKey(const Key('activity-picker')));
    await tester.tap(find.byKey(const Key('activity-picker')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Take a nap · restores 35 energy'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('do-activity-button')));
    await tester.tap(find.byKey(const Key('do-activity-button')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('35 / 100'), findsOneWidget);
  });
}
