//
//  TradeView.swift
//  Sharby
//
//  Created by Matt Zawodniak on 11/29/24.
//

import SwiftUI

struct TradeView: View {
  @State var trade: Pool
  @State var estimatedGas: Decimal
  @State var estimatedFees: Decimal
  @State var estimatedVolume: Decimal
  @State var estimatedProfit: Decimal
  @State var estimatedStability: Int


  var body: some View {
    HStack {
      Text(trade.name)
      Text(trade.exchange?.name ?? "No Exchange")
      Text("\(estimatedProfit)")
      Text("\(estimatedGas)")
      Text("\(estimatedFees)")
      Text("\(estimatedVolume)")
      Text("\(estimatedStability)")
    }
  }
}

//#Preview {
//    TradeView()
//}
