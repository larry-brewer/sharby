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
      if var coinPair = coinPairToPrices[pool.name] {
        coinPair.append(pool)
        coinPairToPrices.updateValue(coinPair, forKey: pool.name)
      }
      else {
        var coinPool = [Pool]()
        coinPool.append(pool)
        coinPairToPrices[pool.name] = coinPool
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
    for (coin, pools) in coinPairToPrices {
      if pools.count < 2 {
        continue
      }

      print("Comparing: \(coin)")

      let minPool = pools.min(by: { $0.price! < $1.price! })!
      let maxPool = pools.max(by: { $0.price! > $1.price! })!
      let percentDiff = (maxPool.price! - minPool.price!) / 2.0 * 100.0
      print("\(coin): % Diff: \(percentDiff)")
    }
  }
}
