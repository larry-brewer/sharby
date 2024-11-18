//
//  CrossExchangeArbyStrategy.swift
//  Sharby
//
//  Created by Larry Brewer on 1/17/24.
//

import Foundation
import SwiftData

extension Array where Element: Hashable {
  func unique() -> [Element] {
    var seen = Set<Element>()
    return filter { seen.insert($0).inserted }
  }
}

struct CrossExchangeArbyStrategy {
  
  /**
  Find top 20 networks
  Find top 20 pools for each network
  Keep all pools that have crypto int the top 100

   */
  
  func perform(pools: [Pool]) {
    var coinPairToPrices = [String: [Pool]]()
    for pool in pools {
      // A GPT count check approximates that the repeated coins are being collapsed into one, but the [Pool] isn't growing.
      if var coinPair = coinPairToPrices[pool.name.standardFormatting()] {
        coinPair.append(pool)
        coinPairToPrices.updateValue(coinPair, forKey: pool.name.standardFormatting())
      }
      else {
        var coinPool = [Pool]()
        coinPool.append(pool)
        coinPairToPrices[pool.name.standardFormatting()] = coinPool
      }
    }
    print("\(coinPairToPrices.count) coin pairs before culling")
    for (coin, pools) in coinPairToPrices {
      if pools.count < 2 {
        coinPairToPrices.removeValue(forKey: coin)
      }
    }
    print("\(coinPairToPrices.count) coin pairs after culling")
    // We do not have any coin pairs across exchanges. Por Que?
    var lengthOneChains = findLengthOneChains(coinPairToPrices: coinPairToPrices)

    // TODO: This is incredibly hamfisted and should be made into human-quality code. Also, I got no % diff on any trades.
    for (trade1, trade2) in lengthOneChains {
      var trade1Diff: Decimal?
      var trade2Diff: Decimal?
      for (coin, pools) in trade1 {
        if pools.count < 2 {
          continue
        }

        print("Comparing: \(coin)")

        let minPool = pools.min(by: { $0.price! < $1.price! })!
        let maxPool = pools.max(by: { $0.price! > $1.price! })!
        let percentDiff = (maxPool.price! - minPool.price!) / 2.0 * 100.0
        print("\(coin): % Diff: \(percentDiff)")
        trade1Diff = percentDiff
      }
      for (coin, pools) in trade2 {
        if pools.count < 2 {
          continue
        }

        print("Comparing: \(coin)")

        let minPool = pools.min(by: { $0.price! < $1.price! })!
        let maxPool = pools.max(by: { $0.price! > $1.price! })!
        let percentDiff = (maxPool.price! - minPool.price!) / 2.0 * 100.0
        print("\(coin): % Diff: \(percentDiff)")
        trade2Diff = percentDiff
      }

      print("\(trade1.keys) + \(trade2.keys) diff: \(trade1Diff ?? -1) -> \(trade2Diff ?? -1)")
    }

//    for (coin, pools) in coinPairToPrices {
//      if pools.count < 2 {
//        continue
//      }
//
//      print("Comparing: \(coin)")
//
//      let minPool = pools.min(by: { $0.price! < $1.price! })!
//      let maxPool = pools.max(by: { $0.price! > $1.price! })!
//      let percentDiff = (maxPool.price! - minPool.price!) / 2.0 * 100.0
//      print("\(coin): % Diff: \(percentDiff)")
//    }
  }
  // This almost definitely could be more efficient.
  func findLengthOneChains(coinPairToPrices: [String: [Pool]]) -> [([String: [Pool]], [String: [Pool]])] {
    var lengthOneChains = [([String: [Pool]], [String: [Pool]])]()
    // Trades only is just for visibility in console
    var tradesOnly = [(String, String)]()
    for (coin1, pool1) in coinPairToPrices {
      let endCoin1 = coin1.components(separatedBy: " ").last

      for (coin2, pool2) in coinPairToPrices where coin1 != coin2 {
        let startCoin2 = coin2.components(separatedBy: " ").first
        if startCoin2 == endCoin1 {
          lengthOneChains.append(([coin1: pool1], [coin2: pool2]))
          tradesOnly.append((coin1, coin2))
        }
      }
    }
    print("\(lengthOneChains.count) length 1 chains.")
    print(tradesOnly)
    return lengthOneChains
  }
}
