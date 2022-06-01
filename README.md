# GeoJSONKit

[![Swift](https://github.com/maparoni/GeoJSONKit/actions/workflows/swift.yml/badge.svg)](https://github.com/maparoni/GeoJSONKit/actions/workflows/swift.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaparoni%2FGeoJSONKit%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maparoni/GeoJSONKit)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaparoni%2FGeoJSONKit%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/maparoni/GeoJSONKit)

Yet another GeoJSON library in Swift. This is a tiny framework with a focus on simplicity, use of Swift's enums and parsing performance.

Note: There's no full support for `Codable`. It's provided for the [`GeoJSON.GeometryObject` part](https://github.com/maparoni/GeoJSONKit/blob/main/Sources/GeoJSONKit/GeoJSON%2BCodable.swift). That's on purpose and there are other libraries listed below that fully support `Codable`, if that's what you're after.

This package has various extensions:

- [GeoJSONKit+Turf](https://github.com/maparoni/geojsonkit-turf) for powerful spatial analysis, all in Swift
- [GeoJSONKit+GEOS](https://gitlab.com/maparoni/geojsonkit-geos) for interfacing with the [Geometry Engine - Open Source](https://trac.osgeo.org/geos)
- [GeoJSONKit+Vapor](https://gitlab.com/maparoni/geojsonkit/snippets/1972906) for server-side usage

Alternative packages:

- [GEOSwift](https://github.com/GEOSwift/GEOSwift)
- [mapbox/turf-swift](https://github.com/mapbox/turf-swift)

## Installation

### Swift Package Manager

To install GeoJSONKit using the [Swift Package Manager](https://swift.org/package-manager/), add the following package to the `dependencies` in your Package.swift file:

```swift
.package(url: "https://github.com/maparoni/geojsonkit.git", from: "0.5.0")
```

Then `import GeoJSONKit` in any Swift file in your module.
