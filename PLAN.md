# Plan: Support "no thumb" and "default Material thumb" modes

Target version: **1.1.0** (additive, non-breaking)

## Goal

`GradientSlider` currently forces an image thumb. Add two more modes so one widget covers all three:

| Mode | How the caller asks for it |
| --- | --- |
| Image thumb (today's behaviour) | `thumbAsset: 'assets/thumb.png'` |
| Default Material thumb | pass nothing (no `thumbAsset`) |
| No thumb at all | `showThumb: false` |

## Current blockers

- `lib/gradient_slider.dart:9,23` — `thumbAsset` is a **required, non-nullable `String`**.
- `lib/gradient_slider.dart:63` — `rootBundle.load(widget.thumbAsset)` runs unconditionally and throws on a bad/empty path.
- No API surface for "no thumb"; the default thumb only appears accidentally in the frames before `_loadImage()` resolves.

## Verified facts

- Flutter's `Slider.build` resolves `thumbShape: sliderTheme.thumbShape ?? defaults.thumbShape` and
  `overlayShape: sliderTheme.overlayShape ?? defaults.overlayShape`
  (`packages/flutter/lib/src/material/slider.dart:923-924`).
  → Leaving `thumbShape: null` in our `SliderThemeData` gives the standard `RoundSliderThumbShape` **and** keeps
  `assert(sliderTheme.thumbShape != null)` (`lib/gradient_slider.dart:135`) satisfied. No change needed in the track shape.
- `GradientSliderTrackShape.paint` receives `thumbCenter` from the render object regardless of thumb shape, so the
  gradient split point stays correct with `noThumb`.

## API changes (`lib/gradient_slider.dart`)

```dart
final String? thumbAsset;                 // was: required String
final bool showThumb;                     // new, default true
final SliderComponentShape? thumbShape;   // new, escape hatch for a fully custom shape
final SliderComponentShape? overlayShape; // new, optional
```

Constructor: drop `required` from `thumbAsset`, add `this.showThumb = true`, `this.thumbShape`, `this.overlayShape`.

Making a required param optional does **not** break existing call sites — every current usage still compiles.

### Resolution precedence in `build()`

```dart
SliderComponentShape? resolvedThumb() {
  if (!widget.showThumb) return SliderComponentShape.noThumb;
  if (widget.thumbShape != null) return widget.thumbShape;
  return myShape; // null while loading, or when no asset -> Material default
}

SliderComponentShape? resolvedOverlay() {
  if (widget.overlayShape != null) return widget.overlayShape;
  if (!widget.showThumb) return SliderComponentShape.noOverlay; // no ripple with no thumb
  return null; // Material default
}
```

Wire both into the existing `SliderThemeData`.

## Behavioural changes

1. **`_loadImage()`** — return early when `thumbAsset == null`; wrap the decode in `try/catch` so a missing asset
   degrades to the default thumb instead of throwing an unhandled async error. Guard `setState` with `mounted`.
2. **`_updateThumbShape()`** — currently no-ops when `thumbImage == null`; must also *clear* `myShape` when the asset
   is removed.
3. **`didUpdateWidget`** — handle the `null` transitions:
   - asset `null -> non-null`: `_loadImage()`
   - asset `non-null -> null`: clear `thumbImage` and `myShape`
   - asset changed: `_loadImage()` (existing)
   - size changed: `_updateThumbShape()` (existing)
   - `showThumb` / `thumbShape` / `overlayShape` changed: nothing needed, `build()` reads them directly.

## Files to touch

| File | Change |
| --- | --- |
| `lib/gradient_slider.dart` | API + resolution logic + null-safe image loading (main work) |
| `lib/src/image_thumb_shape.dart` | No change |
| `example/lib/main.dart` | Show all three modes stacked in a `Column` |
| `README.md` | New "Thumb modes" section, 3 snippets, update props table with `showThumb` / `thumbShape` / `overlayShape`, mark `thumbAsset` optional |
| `CHANGELOG.md` | `## 1.1.0` entry |
| `pubspec.yaml` | `version: 1.1.0` |

## Verification

- `flutter analyze` clean at repo root.
- `cd example && flutter run` — confirm visually:
  - image thumb still renders as before (regression check),
  - default mode shows the round Material thumb with the gradient track intact,
  - `showThumb: false` shows a bare gradient track that still drags and still splits active/inactive at the right point.
- Confirm no debug assert fires in the default-thumb case (the `sliderTheme.thumbShape != null` assert).

## Notes

- Delete this `PLAN.md` (or add a `.pubignore`) before `flutter pub publish` so it doesn't ship in the package.
