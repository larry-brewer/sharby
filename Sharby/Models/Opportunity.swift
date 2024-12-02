//
//  Opportunity.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

@Model
final class Opportunity {
  // Eventually we need to decide which deals we are collapsing or not. Do we only want the maximum trade pool or do we keep them all to see volume differences, especially if there is still profit to be found?
  var trades: [[String: [Pool]]]
  var tradeValueInCoins: Decimal
  var tradePercent: Decimal
  var tradeValueUSD: Decimal
  var estimatedGas: Decimal?
  var estimatedVolume: Decimal?
  var estimatedStability: Decimal?

  init(trades: [[String : [Pool]]], tradeValueInCoins: Decimal, tradePercent: Decimal, tradeValueUSD: Decimal) {
    self.trades = trades
    self.tradeValueInCoins = tradeValueInCoins
    self.tradePercent = tradePercent
    self.tradeValueUSD = tradeValueUSD
  }
}
