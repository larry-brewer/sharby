//
//  ExchangeCoin.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

@Model
final class ExchangeCoin {
  var coin: Coin
  var exchange: Exchange
  var price: Decimal

  init(coin: Coin, exchange: Exchange, price: Decimal) {
    self.coin = coin
    self.exchange = exchange
    self.price = price
  }
}
