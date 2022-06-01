//
//  ForeignMemberTest.swift
//  
//
//  Created by Adrian Schönig on 1/6/2022.
//

import Foundation

import XCTest

@testable import GeoJSONKit

@available(iOS 10.0, *)
class ForeignMemberTest: XCTestCase {
  
  func testForeignMemberCoding(in geoJSON: GeoJSON) throws {
    let today = ISO8601DateFormatter().string(from: Date())
    
    var json = geoJSON.toJSON()
    
    // Convert the GeoJSON object to valid GeoJSON-T <https://github.com/kgeographer/geojson-t/>.
    XCTAssert(json["when"] == nil)
    let foreigner: [String: AnyHashable] = [
      "timespans": [
        [
          // Starts and ends sometime today.
          "start": [
            "in": today,
          ],
          "end": [
            "in": today,
          ],
        ],
      ],
      "duration": "PT1M", // 1 minute long
      "label": "Today",
    ]
    json["when"] = foreigner
    
    let modifiedData = try JSONSerialization.data(withJSONObject: json, options: [])
    let modifiedObject = try GeoJSON(data: modifiedData)
    
    let roundTrippedJSON = modifiedObject.toJSON()
    
    let when = try XCTUnwrap(roundTrippedJSON["when"] as? [String: Any?])
    XCTAssertEqual(when as NSDictionary, json["when"] as? NSDictionary)
  }
  
  func testForeignMemberCoding() throws {
    let nullIsland = GeoJSON.Position(latitude: 0, longitude: 0)
    try testForeignMemberCoding(in: .init(geometry: .single(.point(nullIsland))))
    try testForeignMemberCoding(in: .init(geometry: .single(.lineString(.init(positions: [nullIsland, nullIsland])))))
    try testForeignMemberCoding(in: .init(geometry: .single(.polygon(.init([[nullIsland, nullIsland]])))))
    try testForeignMemberCoding(in: .init(feature: .init(geometry: .single(.point(nullIsland)))))
    try testForeignMemberCoding(in: .init(features: []))
  }
  
}
