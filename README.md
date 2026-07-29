
 A slider widget, supports image thumb, track gradient and border

![Image thumb, default Material thumb, range slider and no thumb](https://raw.githubusercontent.com/ihsankottupadam/flutter-gradient-slider/master/screenshots/slider_modes.png)

## Features

* Custom thumb image
* Default Material thumb, or no thumb at all
* Works with both `Slider` and `RangeSlider`
* Active track gradient
* Inactive track gradient
* Track border
* Track border color

## Usage



```dart
 GradientSlider(
  thumbAsset: 'assets/vert_thumb.png',
  thumbHeight: 30,
  thumbWidth: 30,
  trackBorder: 1,
  trackBorderColor: Colors.black,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  inactiveTrackGradient:
      LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade800]),
  slider: Slider(value: 0.5, onChanged: (value) {}
  ),
)
```

## Thumb modes

**Image thumb** — pass `thumbAsset`:

```dart
GradientSlider(
  thumbAsset: 'assets/vert_thumb.png',
  thumbHeight: 30,
  thumbWidth: 30,
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

Any `ImageProvider` works too — network, file, memory, or a `package:` asset —
via `thumbImage`, which takes precedence over `thumbAsset`:

```dart
GradientSlider(
  thumbImage: const NetworkImage('https://example.com/thumb.png'),
  thumbHeight: 30,
  thumbWidth: 30,
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

**Default Material thumb** — just omit `thumbAsset`:

```dart
GradientSlider(
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

**No thumb** — set `showThumb: false`. The track still responds to drags:

```dart
GradientSlider(
  showThumb: false,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

`thumbHeight` and `thumbWidth` only apply to the image thumb.

> **Note:** a `showThumb: false` slider is slightly **wider** than one with a thumb.
> Flutter derives the track's horizontal padding from the thumb and overlay size, so
> hiding both collapses that padding to zero. If you stack a no-thumb slider next to
> normal ones and need them to line up, wrap it in `Padding` to compensate.

### Styling the default thumb

Set the thumb color on the `Slider` you pass to `slider:`:

```dart
GradientSlider(
  slider: Slider(
    value: 0.5,
    thumbColor: Colors.white,
    onChanged: (value) {},
  ),
)
```

## Range slider

Pass a `RangeSlider` as `slider:` — same widget, no extra setup. The gradient
fills the span **between** the two thumbs:

```dart
GradientSlider(
  trackHeight: 10,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  inactiveTrackGradient:
      LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade800]),
  slider: RangeSlider(
    values: rangeValues,
    min: 0,
    max: 10,
    onChanged: (v) => setState(() => rangeValues = v),
  ),
)
```

`thumbAsset`, `trackBorder` and the disabled fade all work exactly as they do
for a single-thumb slider. Use `rangeThumbShape` for a fully custom thumb, the
counterpart of `thumbShape`.

Two differences worth knowing:

* `showThumb: false` applies to `Slider` only. A range slider always keeps its
  thumbs, since without them there is no cue as to which end you are dragging.
* The active span cannot be drawn taller than the rest of the track —
  `RangeSliderTrackShape.paint` has no `additionalActiveTrackHeight` parameter,
  unlike the single-thumb equivalent.

### Theming

`GradientSlider` merges onto the inherited `SliderTheme` rather than replacing it, so anything
it doesn't set itself — tick marks, value indicator, overlay color, and so on — can still be
configured from a `SliderTheme` (or `ThemeData.sliderTheme`) above it:

```dart
SliderTheme(
  data: const SliderThemeData(
    activeTickMarkColor: Colors.white,
    showValueIndicator: ShowValueIndicator.always,
  ),
  child: GradientSlider(
    activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
    slider: Slider(value: 0.5, divisions: 5, label: '50%', onChanged: (value) {}),
  ),
)
```

| Type | Properties | 
| --- |:---:| 
| String? | thumbAsset
| ImageProvider? | thumbImage
| double | thumbHeight
| double | thumbWidth
| bool | showThumb
| SliderComponentShape | thumbShape
| RangeSliderThumbShape | rangeThumbShape
| SliderComponentShape | overlayShape
| Widget | slider
| Gradient | activeTrackGradient
| Gradient | inactiveTrackGradient
| Color | inactiveTrackColor
| double | trackHeight
| double | trackBorder
| Color | trackBorderColor