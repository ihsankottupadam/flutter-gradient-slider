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