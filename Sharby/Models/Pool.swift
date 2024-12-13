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
  var baseTokenPriceNativeCurrency: Decimal?
  var quoteTokenPriceNativeCurrency: Decimal?
  var marketCapUSD: Decimal?
  var reserveInUSD: Decimal?
  var quotePerBase: Decimal?
  var basePerQuote: Decimal?
  var baseTokenPriceUSD: Decimal?
  var fee: Decimal?
  var fdvUSD: Decimal? //  To check maximum allowable profit ignoring slippage
  var priceChangePercentage: PriceChangePercentage // To help with volatility estimates
  var transactions: Transactions


  @Relationship(deleteRule: .noAction)
  var exchange: Exchange?

  @Relationship(deleteRule: .noAction)
  var network: Network?
  
  enum CodingKeys: String, CodingKey {
    case id
    case attributes
    case relationships
  }

  enum AttributesKeys: String, CodingKey {
    case name
    case base_token_price_native_currency
    case quote_token_price_native_currency
    case market_cap_usd
    case quote_token_price_base_token
    case base_token_price_quote_token
    case base_token_price_usd
    case fdv_usd
    case price_change_percentage
    case transactions
  }

  enum RelationshipsKeys: String, CodingKey {
    case dex
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    
    do {
      let attributesContainer = try container.nestedContainer(keyedBy: AttributesKeys.self, forKey: .attributes)
      let poolName = try attributesContainer.decode(String.self, forKey: .name)
      if poolName.last == "%" {
        name = poolName.standardFormatting()
        fee = Decimal(string: poolName.components(separatedBy: " ").last!)! / 100
      } else {
        name = poolName
      }

      let stringBaseNativePrice = try? attributesContainer.decode(String.self, forKey: .base_token_price_native_currency)

      if let stringBaseNativePrice = stringBaseNativePrice,
         let price = Decimal(string: stringBaseNativePrice) {
        self.baseTokenPriceNativeCurrency = price
      }
      else {
//        throw PoolParsingError.missingPrice
      }

      let stringQuoteNativePrice = try? attributesContainer.decode(String.self, forKey: .quote_token_price_native_currency)
      if let stringQuoteNativePrice = stringQuoteNativePrice,
         let price = Decimal(string: stringQuoteNativePrice) {
        self.quoteTokenPriceNativeCurrency = price
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
//        print("Base Token Does Not Have USD Price")
        self.baseTokenPriceUSD = 0
      }

      let stringFdv = try? attributesContainer.decode(String.self, forKey: .fdv_usd)
      if let stringFdv = stringFdv,
         let fdvUSD = Decimal(string: stringFdv) {
        self.fdvUSD = fdvUSD
      } else {
        // print("No FDV for this pool")
        self.fdvUSD = 0
      }

      let stringQuotePerBase = try? attributesContainer.decode(String.self, forKey: .quote_token_price_base_token)
      if let stringQuotePerBase = stringQuotePerBase,
         let quotePerBase = Decimal(string: stringQuotePerBase) {
        self.quotePerBase = quotePerBase
      } else {
//        print("Quote Per Base was not coded.")
        self.quotePerBase = 0
      }

      let stringBasePerQuote = try? attributesContainer.decode(String.self, forKey: .base_token_price_quote_token)
      if let stringBasePerQuote = stringBasePerQuote,
         let basePerQuote = Decimal(string: stringBasePerQuote) {
        self.basePerQuote = basePerQuote
      }

      priceChangePercentage = try attributesContainer.decode(PriceChangePercentage.self, forKey: .price_change_percentage)

      transactions = try attributesContainer.decode(Transactions.self, forKey: .transactions)
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
    try attributesContainer.encode(baseTokenPriceNativeCurrency, forKey: .base_token_price_native_currency)
  }

  struct TransactionPeriodDetails: Codable {
    let buys: Int
    let sells: Int
    let buyers: Int
    let sellers: Int
  }

  struct Transactions: Codable {
    let m5: TransactionPeriodDetails
    let m15: TransactionPeriodDetails
    let m30: TransactionPeriodDetails
    let h1: TransactionPeriodDetails
    let h24: TransactionPeriodDetails
  }

  struct PriceChangePercentage: Codable {
    let m5: String
    let h1: String
    let h6: String
    let h24: String
  }
}
