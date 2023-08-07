// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "GeoJSONKit",
  products: [
    .library(
      name: "GeoJSONKit",
      targets: ["GeoJSONKit"]),
  ],
  targets: [
    .target(
      name: "GeoJSONKit"),
    .testTarget(
      name: "GeoJSONKitTests",
      dependencies: ["GeoJSONKit"]),
  ]
)
