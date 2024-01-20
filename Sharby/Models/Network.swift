//
//  Network.swift
//  Sharby
//
//  Created by Larry Brewer on 1/17/24.
//

import Foundation
import SwiftData

@Model
final class Network: Codable {
  @Attribute(.unique) var id: String
  var name: String

  enum CodingKeys: String, CodingKey {
    case id
    case attributes
  }

  enum AttributesKeys: String, CodingKey {
    case name
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)

    let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
    name = try attributesContainer.decode(String.self, forKey: .name)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)

    var attributesContainer = container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
    try attributesContainer.encode(name, forKey: .name)
  }
}
