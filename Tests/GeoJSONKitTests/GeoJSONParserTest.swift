//
//  GeoJSONParserTest.swift
//  GeoJSONKitTests
//
//  Created by Adrian Schönig on 31.01.18.
//  Copyright © 2018 Adrian Schönig. All rights reserved.
//

import XCTest

@testable import GeoJSONKit

final class GeoJSONParserTest: XCTestCase {
    
  func testPoint() throws {
    let data = try XCTestCase.loadData(filename: "point")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .geometry(object) = parsed.object,
      case let .single(geometry) = object,
      case let .point(position) = geometry
      else { return XCTFail("Unexpected structure") }
    
    XCTAssertEqual(0.0, position.latitude)
    XCTAssertEqual(100.0, position.longitude)
    XCTAssertNil(position.altitude)
  }
  
  func testMultiPoint() throws {
    let data = try XCTestCase.loadData(filename: "multipoint")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)

    guard
      case let .geometry(object) = parsed.object,
      case let .multi(geometries) = object,
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
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .geometry(object) = parsed.object,
      case let .single(geometry) = object,
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
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .geometry(object) = parsed.object,
      case let .multi(geometries) = object,
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
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .geometry(object) = parsed.object,
      case let .single(geometry) = object,
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
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    
    guard
      case let .geometry(object) = parsed.object,
      case let .single(geometry) = object,
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
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }
  
  func testFeatureCollection() throws {
    let data = try XCTestCase.loadData(filename: "featurecollection")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }

  func testGeometryCollection() throws {
    let data = try XCTestCase.loadData(filename: "geometrycollection")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }

  func testTripGo() throws {
    let data = try XCTestCase.loadData(filename: "tripgo")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }
  
  func testWorld() throws {
    let data = try XCTestCase.loadData(filename: "world")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }
  
  func testNuremberg() throws {
    let data = try XCTestCase.loadData(filename: "nuremberg")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }

  func testNSWFires() throws {
    let data = try XCTestCase.loadData(filename: "nsw-fires-180824")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
  }
  
  func testFeatureCollectionFromDict() throws {
    let data = try XCTestCase.loadData(filename: "featurecollection")
    let object = try JSONSerialization.jsonObject(with: data, options: [])
    let dict = try XCTUnwrap(object as? [String: Any])
    let parsed = try GeoJSON(from: dict)
    XCTAssertNotNil(parsed)
  }
  
  func testAdditionalFields() throws {
    let data = try XCTestCase.loadData(filename: "nuremberg")
    let parsed = try GeoJSON(data: data)
    XCTAssertNotNil(parsed)
    let geocoding = try XCTUnwrap(parsed.additionalFields["geocoding"])
    let geocodingDict = try XCTUnwrap(geocoding as? [String: Any])
    XCTAssertEqual(geocodingDict["version"] as? String, "0.2")
    XCTAssertEqual(geocodingDict["attribution"] as? String, "http://pelias.mapzen.com/v1/attribution")
    XCTAssertNotNil(geocodingDict["query"])
    XCTAssertNotNil(geocodingDict["engine"])
    XCTAssertEqual(geocodingDict["timestamp"] as? Int, 1505232719417)
  }
    
}
