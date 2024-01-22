//
//  Coin.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

@Model
final class Coin: Codable {
  enum CodingKeys: CodingKey {
    case id, rank, name, symbol
  }

  var rank: Int
  var name: String
  @Attribute(.unique) var symbol: String

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.rank = try container.decode(Int.self, forKey: .rank)
    self.name = try container.decode(String.self, forKey: .name)
    self.symbol = try container.decode(String.self, forKey: .symbol)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(rank, forKey: .rank)
    try container.encode(name, forKey: .name)
    try container.encode(symbol, forKey: .symbol)
  }
}
