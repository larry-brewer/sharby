//
//  String.swift
//  Sharby
//
//  Created by Matt Zawodniak on 11/18/24.
//

import Foundation

extension String {
  func standardFormatting() -> String {
    var coinPair: String = self
    if coinPair.last == "%" {
      let lastSpace = coinPair.lastIndex(where: {$0 == " "}) ?? coinPair.endIndex
      coinPair.removeSubrange(lastSpace..<coinPair.endIndex)
    }

    coinPair = coinPair.capitalized
    return coinPair
  }
}
