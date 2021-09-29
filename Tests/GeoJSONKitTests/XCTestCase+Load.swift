//
//  XCTestCase+Load.swift
//  GeoJSONKitTests
//
//  Created by Adrian Schönig on 17.02.18.
//  Copyright © 2018 Adrian Schönig. All rights reserved.
//

import XCTest

extension XCTestCase {

  static func url(filename: String, ofType fileType: String = "geojson") -> URL {
    let sourceFile = URL(fileURLWithPath: #file)
    let directory = sourceFile.deletingLastPathComponent()
    let resourceURL =
      directory
        .appendingPathComponent("data", isDirectory: true)
        .appendingPathComponent(filename)
        .appendingPathExtension(fileType)
    return resourceURL
  }
  
  static func loadData(filename: String, ofType fileType: String = "geojson") throws -> Data {
    return try Data(contentsOf: url(filename: filename, ofType: fileType))
  }
  
}
