//
//  Pool.swift
//  Sharby
//
//  Created by Larry Brewer on 1/17/24.
//

import Foundation
import SwiftData

enum PoolParsingError: Error {
  case missingPrice
  // Add other cases for different error types as needed
}

@Model
final class Pool: Codable {
  @Attribute(.unique) var id: String
  var name: String
  var price: Decimal

  @Relationship(deleteRule: .noAction)
  var exchange: Exchange?

  @Relationship(deleteRule: .noAction)
  var network: Network?
  
  enum CodingKeys: String, CodingKey {
    case id
    case attributes
  }

  enum AttributesKeys: String, CodingKey {
    case name
    case base_token_price_native_currency
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    
    do {
      let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
      name = try attributesContainer.decode(String.self, forKey: .name)

      let stringPrice = try attributesContainer.decode(String.self, forKey: .base_token_price_native_currency)
      if let price = Decimal(string: stringPrice) {
        self.price = price
      }
      else {
        throw PoolParsingError.missingPrice
      }
    } catch {
      let json = decoder.currentlyDecodingJSON() as! [String: Any]
      guard let attributes = json["attributes"] as? [String: Any],
         let _ = attributes["base_token_price_native_currency"] as? String else {
          throw PoolParsingError.missingPrice
      }
        print("Error decoding a Pool: \(error)")
        print("Found corrupt data at \(decoder.codingPath)")
        print("Corrupt data \(json)")
        throw error
      }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)

    var attributesContainer = container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
    try attributesContainer.encode(name, forKey: .name)
    try attributesContainer.encode(price, forKey: .base_token_price_native_currency)
  }
}
