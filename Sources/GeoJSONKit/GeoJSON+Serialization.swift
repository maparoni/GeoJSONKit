//
//  GeoJSON+Serialization.swift
//  
//
//  Created by Adrian Schönig on 29/9/21.
//

import Foundation

extension GeoJSON {
  
  public init(deserializing data: Data) throws {
    try self.init(data: data)
  }
  
  public func serialize() throws -> Data {
    return try toData()
  }
  
}
