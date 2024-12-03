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
  case missingForwardTrade
  // Add other cases for different error types as needed
}

@Model
final class Pool: Codable {
  @Attribute(.unique) var id: String
  var name: String
  var price: Decimal?
  var marketCapUSD: Decimal?
  var reserveInUSD: Decimal?
  var quotePerBase: Decimal?
  var basePerQuote: Decimal?
  var baseTokenPriceUSD: Decimal?

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
    case market_cap_usd
    case quote_token_price_base_token
    case base_token_price_quote_token
    case base_token_price_usd
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    
    do {
      let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
      name = try attributesContainer.decode(String.self, forKey: .name)


      let stringPrice = try? attributesContainer.decode(String.self, forKey: .base_token_price_native_currency)

      if let stringPrice = stringPrice,
         let price = Decimal(string: stringPrice) {
        self.price = price
      }
      else {
//        throw PoolParsingError.missingPrice
      }
      
      let stringMarketCapUSD = try? attributesContainer.decode(String.self, forKey: .market_cap_usd)
      if let stringMarketCapUSD = stringMarketCapUSD,
         let marketCapUSD = Decimal(string: stringMarketCapUSD) {
        self.marketCapUSD = marketCapUSD
      }

      let stringreserveInUSD = try? attributesContainer.decode(String.self, forKey: .market_cap_usd)
      if let stringreserveInUSD = stringreserveInUSD,
         let reserveInUSD = Decimal(string: stringreserveInUSD) {
        self.reserveInUSD = reserveInUSD
      }

      let stringBaseTokenPriceUSD = try? attributesContainer.decode(String.self, forKey: .base_token_price_usd)
      if let stringBaseTokenPriceUSD = stringBaseTokenPriceUSD,
         let baseTokenPriceUSD = Decimal(string: stringBaseTokenPriceUSD) {
        self.baseTokenPriceUSD = baseTokenPriceUSD
      } else {
        print("Base Token Does Not Have USD Price")
        self.baseTokenPriceUSD = 0
      }

      let stringQuotePerBase = try? attributesContainer.decode(String.self, forKey: .quote_token_price_base_token)
      if let stringQuotePerBase = stringQuotePerBase,
         let quotePerBase = Decimal(string: stringQuotePerBase) {
        self.quotePerBase = quotePerBase
      } else {
        print("Quote Per Base was not coded.")
        self.quotePerBase = 0
      }

      let stringBasePerQuote = try? attributesContainer.decode(String.self, forKey: .base_token_price_quote_token)
      if let stringBasePerQuote = stringBasePerQuote,
         let basePerQuote = Decimal(string: stringBasePerQuote) {
        self.basePerQuote = basePerQuote
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
