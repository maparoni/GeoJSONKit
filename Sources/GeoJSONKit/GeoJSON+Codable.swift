//
//  GeoJSON+Codable.swift
//  GeoJSONKit
//
//  Created by Adrian Schönig on 4/8/21.
//

import Foundation

extension GeoJSON.GeometryObject: Codable {
  
  enum CodingKeys: String, CodingKey {
    case type
    case coordinates
    case geometries
  }
  
  public enum CodingError: Error {
    case notAGeometry
    case unsupportedCoordinateCount
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(GeoJSON.GeoJSONType.self, forKey: .type)
    
    switch type {
    case .feature, .featureCollection:
      throw CodingError.notAGeometry

    case .geometryCollection:
      let geometries = try container.decode([GeoJSON.GeometryObject].self, forKey: .geometries)
      self = .collection(geometries)
      
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
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(type, forKey: .type)

    func addCoordinates(_ coordinates: [Any]) throws {
      if let single = coordinates as? [Double] {
        try container.encode(single, forKey: .coordinates)
      } else if let double = coordinates as? [[Double]] {
        try container.encode(double, forKey: .coordinates)
      } else if let triple = coordinates as? [[[Double]]] {
        try container.encode(triple, forKey: .coordinates)
      } else if let quatruple = coordinates as? [[[[Double]]]] {
        try container.encode(quatruple, forKey: .coordinates)
      } else if let single = coordinates as? [Decimal] {
        try container.encode(single, forKey: .coordinates)
      } else if let double = coordinates as? [[Decimal]] {
        try container.encode(double, forKey: .coordinates)
      } else if let triple = coordinates as? [[[Decimal]]] {
        try container.encode(triple, forKey: .coordinates)
      } else if let quatruple = coordinates as? [[[[Decimal]]]] {
        try container.encode(quatruple, forKey: .coordinates)
      } else {
        throw CodingError.unsupportedCoordinateCount
      }
    }
    
    switch self {
    case .collection(let geometries):
      try container.encode(geometries, forKey: .geometries)
      
    case .single(let geometry):
      try addCoordinates(geometry.coordinatesJSON(prune: false))

    case .multi(let geometries):
      try addCoordinates(geometries.map { $0.coordinatesJSON(prune: false) })
    }
  }
}

extension GeoJSON.Feature {
  
  /// Create a feature with the provided `Encodable` model as the properties
  /// - Parameters:
  ///   - geometry: Geometry
  ///   - properties: Known structure to use for the properties
  ///   - id: GeoJSON-compatible ID, i.e., an Integer or a String
  ///   - configure: Optional handler to configure how to encode the `Encodable`
  public init<P: Encodable>(geometry: GeoJSON.GeometryObject, model: P, id: AnyHashable? = nil, configure: (inout JSONEncoder) -> Void  = { _ in }) throws {
    var encoder = JSONEncoder()
    configure(&encoder)
    let data = try encoder.encode(model)
    let asDict = try JSONSerialization.jsonObject(with: data) as? [String: AnyHashable]
    self.init(geometry: geometry, properties: asDict, id: id)
  }
  
  /// Parses the properties as the provided `Decodable` model
  /// - Parameters:
  ///   - type: Known structure to decode the feature's properties again
  ///   - configure: Optional handler to configure how to decode the `Decodable`
  /// - Returns: Properties decoded as the provided `Decodable`
  public func model<P: Decodable>(as type: P.Type, configure: (inout JSONDecoder) -> Void  = { _ in }) throws -> P {
    let asData = try JSONSerialization.data(withJSONObject: properties ?? [:])
    var decoder = JSONDecoder()
    configure(&decoder)
    return try decoder.decode(P.self, from: asData)
  }
  
}
