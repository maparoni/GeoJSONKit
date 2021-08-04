//
//  GeoJSON+Codable.swift
//  GeoJSONKit
//
//  Created by Adrian Schönig on 4/8/21.
//

import Foundation

extension GeoJSON.GeometryObject: Decodable {
  
  enum CodingKeys: String, CodingKey {
    case type
    case coordinates
    case geometries
  }
  
  public enum CodingError: Error {
    case featuresNotSupported
    case geometryCollectionNotSupported
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(GeoJSON.GeoJSONType.self, forKey: .type)
    
    switch type {
    case .feature, .featureCollection:
      throw CodingError.featuresNotSupported
    case .geometryCollection:
      throw CodingError.geometryCollectionNotSupported
      
    case .point:
      let coordinates = try container.decode([Double].self, forKey: .coordinates)
      self = .single(.point(Self.position(from: coordinates)))

    case .multiPoint:
      let coordinates = try container.decode([[Double]].self, forKey: .coordinates)
      let positions = coordinates.map(Self.position(from:))
      self = .multi(positions.map { .point($0) })
      
    case .lineString:
      let coordinates = try container.decode([[Double]].self, forKey: .coordinates)
      let positions = coordinates.map(Self.position(from:))
      self = .single(.lineString(.init(positions: positions)))

    case .multiLineString:
      let coordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
      let positionsArray = coordinates.map { $0.map(Self.position(from:)) }
      self = .multi(positionsArray.map { .lineString(.init(positions: $0)) })

    case .polygon:
      let coordinates = try container.decode([[[Double]]].self, forKey: .coordinates)
      let positionsArray = coordinates.map { $0.map(Self.position(from:)) }
      self = .single(.polygon(.init(positionsArray)))

    case .multiPolygon:
      let coordinates = try container.decode([[[[Double]]]].self, forKey: .coordinates)
      let positionsArrayArray = coordinates.map { $0.map { $0.map(Self.position(from:)) }}
      self = .multi(positionsArrayArray.map { .polygon(.init($0)) })
    }
  }
  
  private static func position(from coordinates: [Double]) -> GeoJSON.Position {
    .init(latitude: coordinates[1], longitude: coordinates[0], altitude: coordinates.count > 2 ? coordinates[2] : nil)
  }

}
