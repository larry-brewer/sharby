//
//  StableCoinArbyStrategy.swift
//  Sharby
//
//  Created by Matt Zawodniak on 12/3/24.
//

import Foundation
import SwiftData

struct StableCoinArbyStrategy {
  static var stableCoins: [String] = ["USDT", "USDC", "DAI"]

  func stableArbitrage(pools: [Pool]) {
    var coinPairToPrices = [String: [Pool]]()

    for pool in pools where pool.quotePerBase != nil && pool.basePerQuote != nil {
      if var coinPair = coinPairToPrices[pool.name.standardFormatting()] {
        coinPair.append(pool)
        coinPairToPrices.updateValue(coinPair, forKey: pool.name.standardFormatting())
      } else {
        var coinPool = [Pool]()
        coinPool.append(pool)
        coinPairToPrices[pool.name.standardFormatting()] = coinPool
      }
    }

    for trade in coinPairToPrices {
      let maxForward = trade.value.max(by: { $0.quotePerBase! > $1.quotePerBase! })
      let maxBackward = trade.value.max(by: { $0.basePerQuote! > $1.basePerQuote! })
      let loopProfit = ((maxForward?.quotePerBase ?? 0) * (maxBackward?.basePerQuote ?? 0))

      if loopProfit > 1.01 {

        print("Found a trade with profit \((loopProfit - 1)*100)% of $\(maxForward!.baseTokenPriceUSD) using \(trade.key) on \(maxForward?.exchange?.name) and \(trade.key.reversed()) on \(maxBackward?.exchange?.name)")
      }
    }


  }

//  func findTradeLoops(coinPairToPrices: [String: [Pool]]) -> [[String: [Pool]]] {
//    var lengthOneChains = [[String: [Pool]]]()
//
//    for (coin1, pool1) in coinPairToPrices {
//      let start1 = coin1.components(separatedBy: " ").first
//      let end1 = coin1.components(separatedBy: " ").last
//
//      for (coin2, pool2) in coinPairToPrices where coin1 != coin2 {
//        let start2 = coin2.components(separatedBy: " ").first
//        let end2 = coin2.components(separatedBy: " ").last
//
//        if start1 == end2 && start2 == end1 {
//          lengthOneChains.append()
//        }
//      }
//    }
//
//    return lengthOneChains
//  }
}
