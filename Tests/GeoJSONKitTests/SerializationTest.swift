//
//  SerializationTest.swift
//  
//
//  Created by Adrian Schönig on 13/3/2022.
//

import XCTest

@testable import GeoJSONKit

class SerializationTest: XCTestCase {
  
  func testPointToDictAndBack() throws {
    let point = GeoJSON.GeometryObject.single(.point(.init(latitude: -33.9451, longitude: 151.2581)))
    let pointAsDict = point.toJSON(prune: true)
    let fromDict = try GeoJSON.GeometryObject(dict: pointAsDict)
    XCTAssertEqual(point, fromDict)
  }
  
  func testGeometryRoundtrip() throws {
    for name in ["point", "linestring", "multilinestring", "multipoint", "multipolygon", "polygon", "polygon-hole", "geometrycollection"] {
      
      let data = try XCTestCase.loadData(filename: name)
      let parsed = try GeoJSON(data: data)
      
      guard
        case let .geometry(geometry) = parsed.object
        else { return XCTFail("Unexpected structure") }

      let asDict = geometry.toJSON(prune: true)
      let fromDict = try GeoJSON.GeometryObject(dict: asDict)
      XCTAssertEqual(geometry, fromDict)
    }
  }
}
