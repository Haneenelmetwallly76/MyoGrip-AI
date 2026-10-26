import '../core/strings.dart';

enum Finger { thumb, indexFinger, middle, ring, little }

abstract final class GestureMap {
  static const Map<int, Set<Finger>> fingersByGesture = {
    0: {},
    1: {Finger.indexFinger},
    2: {Finger.indexFinger, Finger.middle},
    3: {Finger.thumb, Finger.indexFinger, Finger.middle},
    4: {Finger.indexFinger, Finger.middle, Finger.ring, Finger.little},
    5: {
      Finger.thumb,
      Finger.indexFinger,
      Finger.middle,
      Finger.ring,
      Finger.little,
    },
  };

  static Set<Finger> fingersFor(int? gesture) =>
      fingersByGesture[gesture] ?? const {};

  static String fingerLabel(Finger finger) => switch (finger) {
    Finger.thumb => AppStrings.homeFingerThumb,
    Finger.indexFinger => AppStrings.homeFingerIndex,
    Finger.middle => AppStrings.homeFingerMiddle,
    Finger.ring => AppStrings.homeFingerRing,
    Finger.little => AppStrings.homeFingerLittle,
  };
}
