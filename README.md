# GeoJSONKit

Yet another GeoJSON library in Swift. Focus of this library is on simplicity, heavy use of Swift's enums and parsing performance.

Note: There no full support for `Codable`. It's only provided for the `GeoJSON.GeometryObject` part. That's on purpose and there are other libraries listed below that fully support `Codable`, if that's what you're after.

It ~~has~~ will have various extension packages:

- [GeoJSONKit+GEOS](https://gitlab.com/maparoni/geojsonkit-geos) for interfacing with the excellent [Geometry Engine - Open Source](https://trac.osgeo.org/geos)
- GeoJSONKit+MapKit for usage in iOS / Mac apps
- [GeoJSONKit+Turf](https://github.com/maparoni/geojsonkit-turf) for spatial analysis, all in Swift
- [GeoJSONKit+Vapor](https://gitlab.com/maparoni/geojsonkit/snippets/1972906) for server-side usage

Alternative packages:

- [GEOSwift](https://github.com/GEOSwift/GEOSwift), which is *excellent* and has `Codable` support.

## Installation

### Swift Package Manager

To install GeoJSONKit using the [Swift Package Manager](https://swift.org/package-manager/), add the following package to the `dependencies` in your Package.swift file:

```swift
.package(url: "https://github.com/maparoni/geojsonkit.git", from: "0.3.0"),
```

Then `import GeoJSONKit` in any Swift file in your module.
