/// Which features this build ships with.
///
/// App Review rejected 1.0 (3) under guideline 1.4.2: an app that calculates
/// medical dosages has to come from the medication's manufacturer or from a
/// recognised institution, and this one ships from an individual developer
/// account. The guideline is about who publishes the app, not about how the
/// numbers are worked out, so no change to the dosing logic can satisfy it.
///
/// Rather than maintain a second branch, the dose output is compiled out of
/// the iOS build and left in everywhere else. Play has no equivalent rule, so
/// the Android build keeps every feature.
///
/// Override it explicitly when building:
///
///   flutter build ipa --dart-define=SHOW_DOSES=false
///   flutter build appbundle --dart-define=SHOW_DOSES=true
library;

import 'dart:io' show Platform;

/// Whether this build may show a drug dose for a specific patient.
///
/// Off on iOS. The renal-function value and the reference tables stay on
/// everywhere: creatinine clearance is a measure of kidney function used
/// across medicine, not a drug dose, and a table of the criteria states
/// published guidance without recommending a dose for the patient on screen.
final bool showDoses = () {
  const override = String.fromEnvironment('SHOW_DOSES');
  if (override == 'true') return true;
  if (override == 'false') return false;
  // Platform throws in a plain Dart unit test, where there is no platform.
  try {
    return !Platform.isIOS;
  } on Object {
    return true;
  }
}();
