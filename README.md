
 A slider widget, supports image thumb, track gradient and border

![](https://user-images.githubusercontent.com/58967706/198696817-c2f09f94-e5dd-43fe-9dfe-937697b09d7c.jpeg)

## Features

* Custom thumb image
* Default Material thumb, or no thumb at all
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

### Styling the default thumb

Set thumb colors on the `Slider` you pass to `slider:`, not on an outer `SliderTheme` —
`GradientSlider` installs its own `SliderTheme`, which replaces rather than merges with any
theme above it:

```dart
GradientSlider(
  slider: Slider(
    value: 0.5,
    thumbColor: Colors.white,
    onChanged: (value) {},
  ),
)
```

| Type | Properties | 
| --- |:---:| 
| String? | thumbAsset
| double | thumbHeight
| double | thumbWidth
| bool | showThumb
| SliderComponentShape | thumbShape
| SliderComponentShape | overlayShape
| Widget | slider
| Gradient | activeTrackGradient
| Gradient | inactiveTrackGradient
| Color | inactiveTrackColor
| double | trackHeight
| double | trackBorder
| Color | trackBorderColor