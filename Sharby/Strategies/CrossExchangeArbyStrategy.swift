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
    var coinPairToPrices: [String: [Pool]] = [:]

    for pool in pools {
      
      if var coinPair = coinPairToPrices[pool.name] {
        coinPair.append(pool)
      }
      else {
        var coinPool = [Pool]()
        coinPool.append(pool)
        coinPairToPrices[pool.name] = coinPool
      }
    }

    for (coin, pools) in coinPairToPrices {
      if pools.count < 2 {
        continue
      }

      print("Comparing: \(coin)")

      let minPool = pools.min(by: { $0.price < $1.price })!
      let maxPool = pools.max(by: { $0.price > $1.price })!
      let percentDiff = (maxPool.price - minPool.price) / 2.0 * 100.0
      print("\(coin): % Diff: \(percentDiff)")
    }
  }
}
