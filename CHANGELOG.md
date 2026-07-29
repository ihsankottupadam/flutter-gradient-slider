## 1.3.0

* Added `thumbImage`, accepting any `ImageProvider` — `NetworkImage`,
  `FileImage`, `MemoryImage` or a `package:` asset. Previously the thumb could
  only come from a local asset path
* Exported `ImageThumbShape`, which was missing while its range counterpart was
  exported
* `Slider.secondaryTrackValue` now renders a buffer track; previously the
  secondary offset was accepted and silently ignored. Added
  `secondaryTrackGradient` to style it
* Added `additionalActiveTrackHeight`, previously hardcoded to Material's 2 for
  sliders and unavailable for range sliders. Null keeps each widget's default
  (2 and 0); an explicit value applies to both
* Added `trackRadius` for square or custom-radius tracks. The track was always
  fully rounded; null keeps that default and over-large values are clamped
* Added `gradientSpansTrack`. The gradient stays anchored to the whole track by
  default; set it to false to compress the full ramp into the active portion —
  the span between the thumbs, for a range slider

## 1.2.0

* `RangeSlider` is now supported — pass one as `slider:` and the gradient fills
  the span between the two thumbs. Previously it rendered as a plain range
  slider with no gradient and no error
* Added `rangeThumbShape`, the `RangeSlider` counterpart of `thumbShape`
* `thumbAsset` now applies to range sliders too. `showThumb` remains
  single-slider only — a range slider always keeps its thumbs
* Exported `GradientRangeSliderTrackShape` and `ImageRangeThumbShape`
* Added the missing return type on an internal method, which cost 10 pub points
  under pub.dev's static analysis
* Upgraded the `lints` dev dependency to 6.x so pub.dev's stricter lints are
  caught locally

## 1.1.0

* `thumbAsset` is now optional — omit it to use the default Material thumb
* Added `showThumb` to hide the thumb and its overlay entirely
* Added `thumbShape` and `overlayShape` for fully custom shapes
* A missing or undecodable thumb asset now falls back to the default thumb instead of throwing
* Settings from an inherited `SliderTheme` are now preserved instead of being discarded, so tick
  marks, the value indicator and the overlay can be themed from above the widget
* Fixed: a disabled slider kept painting its track gradient at full strength

## 1.0.3

* Improved image thumb rendering quality

## 1.0.2

* minor fix
* changes README.md

## 1.0.1

* analytics issue fix

## 1.0.0

* Custom thumb image
* Active track Gradient
* Inactive track Gradient
* Track border
* Track border color