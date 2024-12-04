//
//  ExpandedTriangleView.swift
//  Sharby
//
//  Created by Matt Zawodniak on 11/29/24.
//

import SwiftUI

struct ExpandedTriangleView: View {
  @Environment(\.modelContext) private var modelContext
  @Binding var opportunity: Opportunity?

  var body: some View {
    VStack {
      ForEach(opportunity!.trades, id: \.self) { trade in
        // Trade, exchange, volume, and maybe trustworthiness?
        HStack {
          Text("\(trade.keys.first ?? "error") -> \(trade.keys.first ?? "error")")
          Text("Exchange: \(trade.values.first!.max(by: { $0.quotePerBase! > $1.quotePerBase! })?.exchange?.name)")
        }
      }
    }
  }
}

//#Preview {
//    ExpandedTriangleView()
//}
