//
//  Pool.swift
//  Sharby
//
//  Created by Larry Brewer on 1/17/24.
//

import Foundation
import SwiftData

@Model
final class Pool: Codable {
  @Attribute(.unique) var id: String
  var name: String
  var price: Decimal

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

    let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
    name = try attributesContainer.decode(String.self, forKey: .name)
    price = Decimal(string: try attributesContainer.decode(String.self, forKey: .base_token_price_native_currency))!
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)

    var attributesContainer = container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
    try attributesContainer.encode(name, forKey: .name)
    try attributesContainer.encode(price, forKey: .base_token_price_native_currency)
  }
}
