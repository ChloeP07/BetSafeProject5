import 'dart:async';

import 'package:betsafeproject5/widgets/motion.dart';

/// Runs before every test file in this folder.
///
/// The decorative flutter_animate effects each start with a zero-length timer,
/// which a test that ends on the same frame would leave pending. They are off
/// here; test/motion_test.dart turns them on to check them.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Motion.effects = false;
  await testMain();
}
