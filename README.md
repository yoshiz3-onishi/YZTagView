# YZTagView

This is a so simple tag view witch can add and remove.

![Screenshot](https://cloud.githubusercontent.com/assets/19931466/19482817/2a1b7562-958d-11e6-834c-538c589354a8.PNG)

## Installation

Clone or download the repository and manually add the file `TagView.swift` to your project and target.

## Usage

#### Default usage
```swift
let tagView = TagView( position: CGPoint( x: 0, y: 0 ), size: CGSize( width: frame.width, height: frame.height ) )
addSubview( tagView )
```

#### With options
```swift
let options: [TagViewOptions] =
[
    .InnerMergine( 0.0 ),
    .AutoGlowHeight( true ),
    .Font( UIFont.systemFontOfSize( 14 ) ),
    .TagBackgroundColor( UIColor.whiteColor() ),
    .TagTextColor( UIColor.lightGrayColor()),
    .AddButtonBackgroundColor( UIColor.whiteColor() ),
    .AddButtonTextColor( UIColor.grayColor() ),
]

let tagView = TagView( position: CGPoint( x: 0, y: 0 ), size: CGSize( width: frame.width, height: frame.height, options: options ) )
addSubview( tagView )
```

## Contact

Mail: [trace.helloworld@gmail.com](trace.helloworld@gmail.com)

## License

TagView is available under the [MIT License](https://github.com/bennibrightside/ShadowView/blob/master/LICENSE)
