
 Slider and range slider with gradient tracks, image thumbs, a buffer track and full track styling.

![Image thumb, default Material thumb, range slider and no thumb](https://raw.githubusercontent.com/ihsankottupadam/flutter-gradient-slider/master/screenshots/slider_modes.png)

## Features

* Works with both `Slider` and `RangeSlider`
* Custom thumb image, from an asset or any `ImageProvider`
* Default Material thumb, or no thumb at all
* Active and inactive track gradients
* Gradient anchored to the track, or compressed into the active portion
* Secondary (buffer) track for download and playback progress
* Track border width and color
* Track corner radius, from fully rounded to square
* Configurable active track height
* Fades correctly when the slider is disabled
* Keeps any inherited `SliderTheme` settings

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

### Gradient mapping

By default the gradient is anchored to the **whole track**, so the filled
portion shows only the slice it covers — a thumb near the start reveals just
the first colours. Set `gradientSpansTrack: false` to fit the entire ramp into
the active portion instead:

```dart
GradientSlider(
  gradientSpansTrack: false,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  slider: Slider(value: 0.3, onChanged: (value) {}),
)
```

This matters most for a `RangeSlider`, where the span between the thumbs can be
narrow: anchored, it shows only a sliver of the gradient; compressed, the full
ramp fits between the thumbs wherever they sit.

### Track shape

The track is fully rounded by default. `trackRadius` overrides that — `0` gives
square corners, and anything larger than half the track height is clamped:

```dart
GradientSlider(
  trackHeight: 20,
  trackRadius: 4,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

### Active track height

Material draws a `Slider`'s active side 2px taller than its inactive side, but
draws a `RangeSlider` uniformly. `additionalActiveTrackHeight` overrides both —
set `0` for a flat track, or set it explicitly to make the two widgets match:

```dart
GradientSlider(
  trackHeight: 10,
  additionalActiveTrackHeight: 0,
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  slider: Slider(value: 0.5, onChanged: (value) {}),
)
```

### Secondary (buffer) track

`Slider.secondaryTrackValue` now renders — the buffer is drawn between the thumb
and that value, as in a download or playback progress bar. It uses
`SliderThemeData.secondaryActiveTrackColor` unless you pass
`secondaryTrackGradient`:

```dart
GradientSlider(
  activeTrackGradient: const LinearGradient(colors: [Colors.pink, Colors.blue]),
  secondaryTrackGradient:
      const LinearGradient(colors: [Colors.white24, Colors.white38]),
  slider: Slider(
    value: 0.3,
    secondaryTrackValue: 0.7,
    onChanged: (value) {},
  ),
)
```

As in Material, the buffer only appears when the secondary value is ahead of the
thumb. `RangeSlider` has no secondary track, so this applies to `Slider` only.

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
* `additionalActiveTrackHeight` defaults to 0 here and 2 for a `Slider`,
  matching Material. Set it explicitly and both honour it.

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
| bool | gradientSpansTrack
| double? | trackRadius
| double? | additionalActiveTrackHeight
| Gradient? | secondaryTrackGradient