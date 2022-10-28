
 A slider wiget, supports image thumb, track gradient and border

![](https://user-images.githubusercontent.com/58967706/198696817-c2f09f94-e5dd-43fe-9dfe-937697b09d7c.jpeg)

## Features

* Custom thumb image
* Active trck gradient
* Inctive trck gradient
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

| Type | Properties | 
| --- |:---:| 
| String | thumbAsset
| double | thumbHeight
| double | thumbWidth
| Widget | slider
| Gradient | activeTrackGradient
| Gradient | inactiveTrackGradient
| Color | inactiveTrackColor
| double | trackHeight
| double | trackBorder
| Color | trackBorderColor