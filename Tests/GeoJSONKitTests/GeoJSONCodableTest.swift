//
//  GeoJSONCodableTest.swift
//  GeoJSONKit
//
//  Created by Adrian Schönig on 4/8/21.
//

import XCTest

@testable import GeoJSONKit

final class GeoJSONCodableTest: XCTestCase {
    
  func testPoint() throws {
    let data = try XCTestCase.loadData(filename: "point")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .single(geometry) = parsed,
      case let .point(position) = geometry
      else { return XCTFail("Unexpected structure") }
    
    XCTAssertEqual(0.0, position.latitude)
    XCTAssertEqual(100.0, position.longitude)
    XCTAssertNil(position.altitude)
  }
  
  func testMultiPoint() throws {
    let data = try XCTestCase.loadData(filename: "multipoint")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)

    guard
      case let .multi(geometries) = parsed,
      case let .point(position1) = geometries[0],
      case let .point(position2) = geometries[1]
      else { return XCTFail("Unexpected structure") }
    
    XCTAssertEqual(2, geometries.count)

    XCTAssertEqual(0.0, position1.latitude)
    XCTAssertEqual(100.0, position1.longitude)
    XCTAssertNil(position1.altitude)

    XCTAssertEqual(1.0, position2.latitude)
    XCTAssertEqual(101.0, position2.longitude)
    XCTAssertNil(position2.altitude)
  }
  
  func testLineString() throws {
    let data = try XCTestCase.loadData(filename: "linestring")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .single(geometry) = parsed,
      case let .lineString(lineString) = geometry
      else { return XCTFail("Unexpected structure") }
    
    let positions = lineString.positions
    XCTAssertEqual(2, positions.count)
    
    XCTAssertEqual(0.0, positions[0].latitude)
    XCTAssertEqual(100.0, positions[0].longitude)
    XCTAssertNil(positions[0].altitude)
    
    XCTAssertEqual(1.0, positions[1].latitude)
    XCTAssertEqual(101.0, positions[1].longitude)
    XCTAssertNil(positions[1].altitude)

  }
  
  func testMultiLineString() throws {
    let data = try XCTestCase.loadData(filename: "multilinestring")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .multi(geometries) = parsed,
      case let .lineString(lineString1) = geometries[0],
      case let .lineString(lineString2) = geometries[1]
      else { return XCTFail("Unexpected structure") }
    
    let positions1 = lineString1.positions
    let positions2 = lineString2.positions

    XCTAssertEqual(2, geometries.count)
    XCTAssertEqual(2, positions1.count)
    XCTAssertEqual(2, positions2.count)

    XCTAssertEqual(0.0, positions1[0].latitude)
    XCTAssertEqual(100.0, positions1[0].longitude)
    XCTAssertNil(positions1[0].altitude)
    
    XCTAssertEqual(1.0, positions1[1].latitude)
    XCTAssertEqual(101.0, positions1[1].longitude)
    XCTAssertNil(positions1[1].altitude)

    XCTAssertEqual(2.0, positions2[0].latitude)
    XCTAssertEqual(102.0, positions2[0].longitude)
    XCTAssertNil(positions2[0].altitude)
    
    XCTAssertEqual(3.0, positions2[1].latitude)
    XCTAssertEqual(103.0, positions2[1].longitude)
    XCTAssertNil(positions2[1].altitude)
  }
  
  func testPolygon() throws {
    let data = try XCTestCase.loadData(filename: "polygon")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .single(geometry) = parsed,
      case let .polygon(polygon) = geometry
      else { return XCTFail("Unexpected structure") }

    let external = polygon.exterior
    let positions = external.positions
    XCTAssertEqual(1, polygon.positionsArray.count)
    XCTAssertEqual(5, positions.count)
    
    XCTAssertEqual(0.0, positions[0].latitude)
    XCTAssertEqual(100.0, positions[0].longitude)
    XCTAssertNil(positions[0].altitude)
    
    XCTAssertEqual(0.0, positions[1].latitude)
    XCTAssertEqual(101.0, positions[1].longitude)
    XCTAssertNil(positions[1].altitude)
  }
  
  func testPolygonWithHole() throws {
    let data = try XCTestCase.loadData(filename: "polygon-hole")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .single(geometry) = parsed,
      case let .polygon(polygon) = geometry,
      let hole = polygon.interiors.first
      else { return XCTFail("Unexpected structure") }
    
    let positions1 = polygon.exterior.positions
    let positions2 = hole.positions
    XCTAssertEqual(2, polygon.positionsArray.count)
    XCTAssertEqual(5, positions1.count)
    XCTAssertEqual(5, positions2.count)

    XCTAssertEqual(0.0, positions1[0].latitude)
    XCTAssertEqual(100.0, positions1[0].longitude)
    XCTAssertNil(positions1[0].altitude)
    
    XCTAssertEqual(0.0, positions1[1].latitude)
    XCTAssertEqual(101.0, positions1[1].longitude)
    XCTAssertNil(positions1[1].altitude)
    
    XCTAssertEqual(0.8, positions2[0].latitude)
    XCTAssertEqual(100.8, positions2[0].longitude)
    XCTAssertNil(positions2[0].altitude)
    
    XCTAssertEqual(0.2, positions2[1].latitude)
    XCTAssertEqual(100.8, positions2[1].longitude)
    XCTAssertNil(positions2[1].altitude)
  }
  
  func testMultiPolygon() throws {
    let data = try XCTestCase.loadData(filename: "multipolygon")
    let parsed = try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data)
    XCTAssertNotNil(parsed)
  }
  
  func testFeatureCollection() throws {
    let data = try XCTestCase.loadData(filename: "featurecollection")
    XCTAssertThrowsError(try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data))
  }

  func testGeometryCollection() throws {
    let data = try XCTestCase.loadData(filename: "geometrycollection")
    XCTAssertThrowsError(try JSONDecoder().decode(GeoJSON.GeometryObject.self, from: data))
  }
  
  static var allTests = [
    ("testPoint", testPoint),
    ("testMultiPoint", testMultiPoint),
    ("testLineString", testLineString),
    ("testMultiLineString", testMultiLineString),
    ("testPolygon", testPolygon),
    ("testPolygonWithHole", testPolygonWithHole),
    ("testMultiPolygon", testMultiPolygon),
    ("testFeatureCollection", testFeatureCollection),
    ("testGeometryCollection", testGeometryCollection),
  ]
    
}
