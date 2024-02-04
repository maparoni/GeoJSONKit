//
//  GeoJSON.swift
//  GeoJSONKit
//
//  Created by Adrian Schönig on 31.01.18.
//  Copyright © 2018 Adrian Schönig. All rights reserved.
//

import Foundation

/// Representation of a [GeoJSON](https://geojson.org) document
public struct GeoJSON: Hashable {

  /// A latitude or longitude in degrees. Should use `WGS84`.
  public typealias Degrees = Double

  /// An azimuth measured in degrees clockwise from true north.
  public typealias Direction = Double

  /// A distance in meters.
  public typealias Distance = Double

  public enum SerializationError: Error {
    case cannotGetEncodedAsUTF8
    case unexpectedRoot
    case missingOrInvalidRequiredField(String)
    case wrongNumberOfCoordinates(String)
    case wrongTypeOfSimpleGeometry(String)
  }
  
  /// A GeoJSON object may represent a region of space (a Geometry), a
  /// spatially bounded entity (a Feature), or a list of Features (a
  /// FeatureCollection).
  public enum GeoJSONObject: Hashable {
    /// A region of space
    case geometry(GeometryObject)

    /// A spatially bounded entity.
    case feature(Feature)
    
    /// A list of Features
    case featureCollection([Feature])
  }
  
  /// GeoJSON supports the following geometry types:
  /// Point, LineString, Polygon, MultiPoint, MultiLineString,
  /// MultiPolygon, and GeometryCollection.
  public enum GeometryObject: Hashable {
    /// A single region of space
    case single(Geometry)
    
    /// Multiple regions of the same type
    case multi([Geometry])
    
    /// Multiple regions of different types
    case collection([GeometryObject])
    
    public init(dict: [String: Any]) throws {
      guard let typeString = dict["type"] as? String, let type = GeoJSONType(rawValue: typeString) else {
        throw SerializationError.missingOrInvalidRequiredField("type")
      }

      switch type {
      case .point, .lineString, .polygon:
        guard let coordinates = dict["coordinates"] as? [Any] else {
          throw SerializationError.missingOrInvalidRequiredField("coordinates")
        }
        
        let geometry = try Geometry(coordinates: coordinates)
        self = .single(geometry)
        
      case .multiPoint, .multiLineString, .multiPolygon:
        guard let multiCoordinates = dict["coordinates"] as? [[Any]] else {
          throw SerializationError.missingOrInvalidRequiredField("coordinates")
        }
        let geometries = try multiCoordinates.map { try Geometry(coordinates: $0) }
        self = .multi(geometries)
        
      case .geometryCollection:
        guard let geometryDicts = dict["geometries"] as? [[String: Any]] else {
          throw SerializationError.missingOrInvalidRequiredField("geometries")
        }
        let geometries = try geometryDicts.map { (dict: [String: Any]) throws -> GeometryObject in
          return try GeometryObject(dict: dict)
        }
        self = .collection(geometries)
        
      case .feature:
        throw SerializationError.wrongTypeOfSimpleGeometry("Can't turn Feature into GeometryObject")
      case .featureCollection:
        throw SerializationError.wrongTypeOfSimpleGeometry("Can't turn FeatureCollection into GeometryObject")
      }
    }
    
    public var type: GeoJSONType {
      switch self {
      case .single(let geometry):
        switch geometry {
        case .point: return .point
        case .lineString: return .lineString
        case .polygon: return .polygon
        }
        
      case .multi(let geometries):
        switch geometries.first! {
        case .point: return .multiPoint
        case .lineString: return .multiLineString
        case .polygon: return .multiPolygon
        }
        
      case .collection:
        return .geometryCollection
      }
    }
    
    public func toJSON(prune: Bool) -> [String: AnyHashable] {
      var json: [String: Any] = [
        "type": type.rawValue
      ]
      
      switch self {
      case .single(let geometry):
        json["coordinates"] = geometry.coordinatesJSON(prune: prune)
      case .multi(let geometries):
        json["coordinates"] = geometries.map { $0.coordinatesJSON(prune: prune) }
      case .collection(let geometries):
        json["geometries"] = geometries.map { $0.toJSON(prune: prune) }
      }
      
      return json.hashable
    }
      
  }
  
  /// The type of a GeoJSON, representing the value of the top-level "type" field in the JSON
  public enum GeoJSONType: String, Codable, CaseIterable {
    case feature = "Feature"
    case featureCollection = "FeatureCollection"
    case point = "Point"
    case multiPoint = "MultiPoint"
    case lineString = "LineString"
    case multiLineString = "MultiLineString"
    case polygon = "Polygon"
    case multiPolygon = "MultiPolygon"
    case geometryCollection = "GeometryCollection"
  }
  
  /// A GeoJSON Position, with latitude, longitude and optional altitude
  public struct Position: Hashable {
    public var latitude: Degrees
    public var longitude: Degrees
    public var altitude: Distance?
    
    public init(latitude: Degrees, longitude: Degrees, altitude: Distance? = nil) {
      self.latitude = latitude
      self.longitude = longitude
      self.altitude = altitude
    }
    
    fileprivate init(coordinates: [Any]) throws {
      guard coordinates.count >= 2 else {
        throw SerializationError.wrongNumberOfCoordinates("At least 2 per position")
      }
      
      if let lat = coordinates[1] as? Degrees, let lng = coordinates[0] as? Degrees {
        latitude = lat
        longitude = lng
      } else if let lat = coordinates[1] as? Decimal, let lng = coordinates[0] as? Decimal {
        latitude = GeoJSON.Degrees((lat as NSDecimalNumber).doubleValue)
        longitude = GeoJSON.Degrees((lng as NSDecimalNumber).doubleValue)
      } else {
        throw SerializationError.wrongTypeOfSimpleGeometry("Expected \(Degrees.self) for coordinates but got \(Swift.type(of: coordinates[0])) (\(coordinates[0])) and \(Swift.type(of: coordinates[1])) (\(coordinates[1]))")
      }
      altitude = coordinates.count >= 3 ? coordinates[2] as? Degrees : nil
    }
    
    fileprivate func toJSON() -> [Degrees] {
      var json = [longitude, latitude]
      if let alt = altitude {
        json.append(alt)
      }
      return json
    }
  }
  
  public struct LineString: Hashable {
    public var positions: [Position]
    
    // We precompute this as it's static, but slow to re-compute
    private let precomputedHash: Int
    
    public init(positions: [Position]) {
      self.positions = positions
      
      var hasher = Hasher()
      hasher.combine(positions)
      precomputedHash = hasher.finalize()
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(precomputedHash)
    }
  }
  
  public struct Polygon: Hashable {
    public struct LinearRing: Hashable {
      public var positions: [Position]
      
      // We precompute this as it's static, but slow to re-compute
      private let precomputedHash: Int
      
      public init(positions: [Position]) {
        var adjusted = positions
        if let first = adjusted.first, first != adjusted.last {
          adjusted.append(first)
        }
        self.positions = adjusted
        
        var hasher = Hasher()
        hasher.combine(adjusted)
        precomputedHash = hasher.finalize()
      }
      
      public func hash(into hasher: inout Hasher) {
        hasher.combine(precomputedHash)
      }
    }
        
    public var exterior: LinearRing
    public var interiors: [LinearRing]
    
    // We precompute this as it's static, but slow to re-compute
    private let precomputedHash: Int
    
    public init(_ rings: [[Position]]) {
      self.exterior = LinearRing(positions: rings.first ?? [])
      self.interiors = rings
        .dropFirst()
        .map(LinearRing.init)
      
      var hasher = Hasher()
      hasher.combine(exterior)
      hasher.combine(rings)
      precomputedHash = hasher.finalize()
    }
    
    public init(exterior: LinearRing, interiors: [LinearRing] = []) {
      self.exterior = exterior
      self.interiors = interiors
      
      var hasher = Hasher()
      hasher.combine(exterior)
      hasher.combine(interiors)
      precomputedHash = hasher.finalize()
    }
    
    public func hash(into hasher: inout Hasher) {
      hasher.combine(precomputedHash)
    }
    
    public var positionsArray: [[Position]] {
      get {
        var array: [[Position]] = [exterior.positions]
        for interior in interiors {
          array.append(interior.positions)
        }
        return array
      }
      set {
        exterior = LinearRing(positions: newValue[0])
        interiors = newValue.suffix(from: 1).map { LinearRing(positions: $0) }
      }
    }
  }
  
  public enum Geometry: Hashable {
    // identified by coordinates + geometries

    case point(Position)
    case lineString(LineString)
    case polygon(Polygon)
    
    fileprivate init(coordinates: [Any]) throws {
      if let coordinates = coordinates as? [[[Any]]] {
        let positions = try coordinates.map { try $0.map { try Position(coordinates: $0) }}
        self = .polygon(Polygon(positions))
      } else if let coordinates = coordinates as? [[Any]] {
        let positions = try coordinates.map { try Position(coordinates: $0) }
        self = .lineString(LineString(positions: positions))
      } else {
        let position = try Position(coordinates: coordinates)
        self = .point(position)
      }
    }
    
    func coordinatesJSON(prune: Bool) -> [Any] {
      if prune {
        switch self {
        case .point(let position):
          return position.toJSON().prune
        case .lineString(let lineString):
          return lineString.positions.map { $0.toJSON().prune }
        case .polygon(let polygon):
          return polygon.positionsArray.map { $0.map { $0.toJSON().prune } }
        }
      } else {
        switch self {
        case .point(let position):
          return position.toJSON()
        case .lineString(let lineString):
          return lineString.positions.map { $0.toJSON() }
        case .polygon(let polygon):
          return polygon.positionsArray.map { $0.map { $0.toJSON() } }
        }
      }
    }
  }
  
  /// Features in GeoJSON contain a Geometry object and additional properties.
  public struct Feature: Hashable {
    public var geometry: GeometryObject
    
    /// Optional properties, as a dictionary.
    public var properties: [String: AnyHashable]?
    
    public var id: AnyHashable? // number or string
    
    public init(geometry: GeometryObject, properties: [String: AnyHashable]? = nil, id: AnyHashable? = nil) {
      self.geometry = geometry
      self.properties = properties
      self.id = id
    }
    
    public init(dict: [String: Any]) throws {
      guard let geometryDict = dict["geometry"] as? [String: Any] else {
        throw SerializationError.missingOrInvalidRequiredField("geometry")
      }
      
      geometry = try GeometryObject(dict: geometryDict)
      properties = (dict["properties"] as? [String: Any])?.compactMapValues(Adjuster.hashable(_:))
      id = dict["id"] as? AnyHashable
    }
    
    /// - Warning: If there are no properties, the `properties` field will be omitted, to avoid dealing
    ///     with `nil` values in a dictionary. This is strictly speaking not compliant with the [GeoJSON spec](https://datatracker.ietf.org/doc/html/rfc7946#section-3.2),
    ///     which says this value should be present with a JSON null value.
    public func toJSON(prune: Bool = true) -> [String: AnyHashable] {
      var json: [String: Any] = [
        "type": "Feature",
        "geometry": geometry.toJSON(prune: prune)
      ]
      json["properties"] = prune ? properties?.prune : properties
      json["id"] = id
      return json.hashable
    }
  }
 
  public struct BoundingBox: Hashable {
    public let southWesterlyLatitude:  Degrees
    public let southWesterlyLongitude: Degrees
    public let northEasterlyLatitude:  Degrees
    public let northEasterlyLongitude: Degrees

    public let minimumElevation: Distance?
    public let maximumElevation: Distance?
    private let minWasFirst: Bool
    
    /// Creates a bounding box encapsulating the provided positions
    ///
    /// - warning: This does not deal with spanning the antimeridian. So, the Fiji case from the GeoJSON specs would result in a 355 degree bounding box and not a 5 degree one. To deal with this, apply the appropriate logic on a level above and then use the `init(coordinates:)` constructor.
    ///
    /// - Parameter positions: Positions to create the bounding box from; has to be at least one!
    public init(positions: [Position]) {
      guard let first = positions.first else { preconditionFailure() }
      var minLat = first.latitude
      var maxLat = first.latitude
      var minLng = first.longitude
      var maxLng = first.longitude
      for point in positions.dropFirst() {
        minLat = min(minLat, point.latitude)
        maxLat = max(maxLat, point.latitude)
        minLng = min(minLng, point.longitude)
        maxLng = max(maxLng, point.longitude)
      }
      southWesterlyLatitude  = minLat
      southWesterlyLongitude = minLng
      northEasterlyLatitude  = maxLat
      northEasterlyLongitude = maxLng
      minimumElevation = nil
      maximumElevation = nil
      minWasFirst = false
    }
    
    
    /// Create a bounding box from the provided coordinates
    /// - Parameter coordinates: 4 or 6 elements in order: south-westerly longitude, south-westerly latitude, (elevation 1), north-easterly lontigude, north-easterly latitude, (elevation 2); where the elevations are optional (but either provide both or none) and there's no required order in which is the minimum and which is the maximum elevation.
    public init(coordinates: [Degrees]) throws {
      switch coordinates.count {
      case 6:
        let first = coordinates[2]
        let second = coordinates[5]
        minimumElevation = min(first, second)
        maximumElevation = max(first, second)
        minWasFirst = first == minimumElevation
        
        southWesterlyLatitude  = coordinates[1]
        southWesterlyLongitude = coordinates[0]
        northEasterlyLatitude  = coordinates[4]
        northEasterlyLongitude = coordinates[3]
      case 4:
        southWesterlyLatitude  = coordinates[1]
        southWesterlyLongitude = coordinates[0]
        northEasterlyLatitude  = coordinates[3]
        northEasterlyLongitude = coordinates[2]
        minimumElevation = nil
        maximumElevation = nil
        minWasFirst = false

      default: throw SerializationError.wrongNumberOfCoordinates("Has to be 4 or 6 for bbox")
      }
    }
    
    fileprivate func toJSON() -> [Degrees] {
      if let min = minimumElevation, let max = maximumElevation {
        let first = minWasFirst ? min : max
        let second = minWasFirst ? max : min
        return [southWesterlyLongitude, southWesterlyLatitude, first, northEasterlyLongitude, northEasterlyLatitude, second]
      } else {
        return [southWesterlyLongitude, southWesterlyLatitude, northEasterlyLongitude, northEasterlyLatitude]
      }
    }
  }
  
  /// Top-level type of the GeoJSON.
  ///
  /// Spec: *A GeoJSON object has a member with the name "type".  The value of
  /// the member MUST be one of the GeoJSON types.*
  public var type: GeoJSONType

  /// Strongly typed primary representation of the GeoJSON, i.e., if it's a feature, feature collection
  /// or a geometry.
  public var object: GeoJSONObject

  /// Bounding box of the GeoJSON, if specifically provided.
  ///
  /// Spec: *A GeoJSON object MAY have a member named "bbox" to include
  /// information on the coordinate range for its Geometries, Features, or
  /// FeatureCollections.*
  public var boundingBox: BoundingBox?
  
  /// Additional fields that we didn't parse
  public var additionalFields: [String: AnyHashable]
  
  /// Initialises a new FeatureCollection.
  public init(features: [Feature], additionalFields: [String: AnyHashable] = [:], boundingBox: BoundingBox? = nil) {
    type = .featureCollection
    object = .featureCollection(features)
    self.additionalFields = additionalFields
    self.boundingBox = boundingBox
  }
  
  /// Initialises a new Feature.
  public init(feature: Feature, additionalFields: [String: AnyHashable] = [:], boundingBox: BoundingBox? = nil) {
    type = .feature
    object = .feature(feature)
    self.additionalFields = additionalFields
    self.boundingBox = boundingBox
  }

  /// Initialises a new Geometry.
  public init(geometry: GeometryObject, additionalFields: [String: AnyHashable] = [:], boundingBox: BoundingBox? = nil) {
    type = geometry.type
    object = .geometry(geometry)
    self.additionalFields = additionalFields
    self.boundingBox = boundingBox
  }
  
  public init(data: Data, textEncoding: String? = nil) throws {
    let compatibleData: Data
    switch textEncoding?.lowercased() {
    case "ascii", "us-ascii":
      let string = String(data: data, encoding: .ascii)
      compatibleData = string?.data(using: .utf8) ?? data
    case "iso-8859-1", "iso-8859-15":
      let string = String(data: data, encoding: .isoLatin1) // close enough
      compatibleData = string?.data(using: .utf8) ?? data
    default:
      compatibleData = data
    }
    
    let decoded = try JSONSerialization.jsonObject(with: compatibleData, options: [])
    guard let dict = decoded as? [String: Any] else {
      throw SerializationError.unexpectedRoot
    }
    
    try self.init(from: dict)
  }
    
  public init(from dict: [String: Any]) throws {

    guard let typeString = dict["type"] as? String, let type = GeoJSONType(rawValue: typeString) else {
      throw SerializationError.missingOrInvalidRequiredField("type")
    }
    self.type = type
    
    switch type {
    case .feature:
      self.object = .feature(try Feature(dict: dict))
      
    case .featureCollection:
      guard let featuresArray = dict["features"] as? [[String: Any]] else {
        throw SerializationError.missingOrInvalidRequiredField("features")
      }
      let features = try featuresArray.map { try Feature(dict: $0)}
      self.object = .featureCollection(features)
      
    default:
      self.object = .geometry(try GeometryObject(dict: dict))
    }
    
    if let coordinates = dict["bbox"] as? [Degrees] {
      self.boundingBox = try BoundingBox(coordinates: coordinates)
    } else {
      self.boundingBox = nil
    }
    
    let knownRootFields = ["type", "features", "bbox", "id", "geometry", "geometries", "properties", "coordinates"]
    additionalFields = dict.filter { key, _ in
      !knownRootFields.contains(key)
    }.compactMapValues(Adjuster.hashable(_:))
  }
  
  public init(geoJSONString string: String) throws {
    guard let data = string.data(using: .utf8) else {
      throw SerializationError.cannotGetEncodedAsUTF8
    }
    try self.init(data: data)
  }

  
  public func toData(options: JSONSerialization.WritingOptions = [], prune: Bool = true) throws -> Data {
    return try JSONSerialization.data(withJSONObject: toJSON(prune: prune), options: options)
  }
  
  public func toJSON(prune: Bool = true) -> [String: AnyHashable] {
    var json = [String: Any]()
    
    json["type"] = type.rawValue
    
    let bbJson = boundingBox?.toJSON()
    json["bbox"] = prune ? bbJson?.prune : bbJson
    
    let objectJson: [String: Any]
    switch object {
    case .feature(let feature):
      objectJson = feature.toJSON(prune: prune)
    case .featureCollection(let features):
      objectJson = ["features": features.map { $0.toJSON(prune: prune) }]
    case .geometry(let geometry):
      objectJson = geometry.toJSON(prune: prune)
    }
    json.merge(objectJson) { a, _ in a }

    let additional = prune ? additionalFields.prune : additionalFields
    json.merge(additional) { a, _ in a }
    
    return json.hashable
  }
  
}

fileprivate extension Array where Element == GeoJSON.Degrees {
  static let roundingBehaviour = NSDecimalNumberHandler(roundingMode: .plain, scale: 6, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: true)
  
  var prune: [Any] {
    return map {
      (Decimal($0) as NSDecimalNumber).rounding(accordingToBehavior: Array.roundingBehaviour) as Decimal
    }
  }
}

enum Adjuster {
  static func prune(_ value: Any) -> Any {
    if let dict = value as? [String: Any] {
      return dict.mapValues(prune(_:))
    } else if value is Int || value is [Int] || value is [[Int]] || value is Bool || value is [Bool] || value is [[Bool]] {
      return value
    } else if let doubles = value as? [GeoJSON.Degrees] {
      return doubles.prune
    } else if let doubless = value as? [[GeoJSON.Degrees]] {
      return doubless.map(\.prune)
    } else if let double = value as? GeoJSON.Degrees {
      return Decimal(double)
    } else if let array = value as? [Any] {
      return array.map(prune(_:))
    } else {
      return value
    }
  }
  
  static func hashable(_ value: Any) -> AnyHashable? {
    if let dict = value as? [String: Any] {
      return dict.compactMapValues(hashable(_:))
    } else if let array = value as? [Any] {
      return array.compactMap(hashable(_:))
    } else if let hashable = value as? AnyHashable {
      return hashable
    } else {
      assertionFailure("Unexpected non-hashable: \(value) -- \(type(of: value))")
      return nil
    }
  }
}

fileprivate extension Dictionary {
  var prune: [Key: Any] {
    mapValues(Adjuster.prune(_:))
  }

  var hashable: [Key: AnyHashable] {
    compactMapValues(Adjuster.hashable(_:))
  }
}
