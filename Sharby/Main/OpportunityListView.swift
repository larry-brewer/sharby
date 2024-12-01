//
//  OpportunityView.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import SwiftData
import Foundation

struct OpportunityListView: View {
  @Environment(\.modelContext) private var modelContext
  @Query var opportunities: [Opportunity]
  @State private var sortOrder = [KeyPathComparator(\Opportunity.tradePercent)]

  var body: some View {
    VStack {
      ForEach(opportunities.sorted(by: { $0.tradePercent > $1.tradePercent })) { triangle in
        HStack {
          Text((triangle.trades.first?.keys.first!.components(separatedBy: " ").first!)!)
          Text("\(triangle.tradePercent.formatted(.number.precision(.fractionLength(2))))")
          Text("+\(triangle.tradeValueInCoins.formatted(.number.precision(.fractionLength(2))))")
          Text("+\(triangle.tradeValueUSD.formatted(.number.precision(.fractionLength(2))))")
        }
      }
    }
  }
}
