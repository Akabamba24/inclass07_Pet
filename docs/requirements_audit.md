# Activity 07 requirements audit

Audit date: October 1, 2026. This checklist compares the project with the Activity 07 assignment requirements. A checked item means there is implementation or test evidence in this repository; it does not mean the item has been uploaded to iCollege.

## Core app

- [x] Editable pet name with confirmation; the screen disposes its `TextEditingController`.
- [x] Happiness and hunger meters stay within 0–100; the Graduate energy meter also stays within range.
- [x] Visible mood text and icon accompany the red/yellow/green `ColorFiltered` tint at the required happiness thresholds.
- [x] One original, transparent grayscale PNG is registered in `pubspec.yaml` and used by the app.
- [x] Feed and Play update the related meters and show action feedback.
- [x] Hunger increases by 5 every 30 seconds.
- [x] Win requires happiness above 80 continuously for three minutes; falling to 80 cancels the pending win.
- [x] Loss occurs at hunger 100 and happiness 10 or lower; care actions are disabled after an outcome.
- [x] Reset restores starting meters, cancels the win timer, and starts one hunger timer.
- [x] Timers and controllers are canceled/disposed by their owners.
- [x] Portrait and landscape layouts are included in Pixel 10 emulator screenshots.

## Graduate pathway

- [x] Energy system: Play costs 15; Run costs 25; Fetch costs 10; Sleep restores 35; insufficient energy disables the action.
- [x] Activity selection: Run, Fetch, and Sleep each update the relevant meters.
- [x] Visual polish and accessible motion: bounce/reactions, animated meters, expression/message switching, mood tint/scale, and reduced-motion support.
- [x] Optional idle-breathing `AnimationController` is owned by the screen and disposed.
- [x] Game rules are separated from rendering in `PetRules` and `PetCareController`.
- [x] Automated tests cover state transitions, bounds, win timing/cancellation, loss, reset, disposal, low energy, UI behavior, and reduced-motion rendering.
- [x] A design choice and its trade-off are in [architecture.md](architecture.md).
- [x] Solo assignment confirmed by the student; the two-team pull-request review workflow does not apply.

## Repository evidence and documentation

- [ ] Repository README is omitted at the student's request; the assignment page lists it as a required submission item.
- [x] Emulator screenshots and test evidence are in `docs/evidence/` and the architecture note.
- [x] `github_link.txt` contains the repository URL.
- [x] No team issue or pull-request links are needed for this solo assignment.
- [ ] Finish the entire manual test matrix on-device. Portrait/landscape, Feed, Play, Sleep, and Reset were checked. The 29/30/70/71 visual boundaries, low-energy disabled UI, reduced-motion setting, and long timer boundaries have automated coverage, but were not all manually demonstrated on-device.

## Individual submission

- [x] `docs/reflection.txt` contains draft answers to all ten questions in simple English.
- [ ] Add the student ID and review/personalize the reflection answers.
- [ ] Transfer the final reflection to the required named Word `.docx` file.
- [x] Release APK was built, installed, and launched; a copy is in Downloads as `DigitalPet_AugustinKabamba.apk`.
- [ ] Confirm the course accepts that solo APK name or rename it to `DigitalPet_TeamName.apk` using the instructor’s required team name.
- [ ] Upload `github_link.txt`, the correctly named APK, and the Word reflection to the labeled iCollege folder.
- [ ] Verify the three uploaded files and the repository link in iCollege.
