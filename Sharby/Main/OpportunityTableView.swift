//
//  OpportunityTableView.swift
//  Sharby
//
//  Created by Matt Zawodniak on 12/2/24.
//

import SwiftUI
import SwiftData

struct OpportunityTableView: View {
  @Environment(\.modelContext) private var modelContext
  @Query var opportunities: [Opportunity]
  @State private var sortOrder = [KeyPathComparator(\Opportunity.tradePercent)]
  @Binding var selectedOpportunity: Opportunity?
  @State var selection: Opportunity.ID? = nil

    var body: some View {
      Table(opportunities, selection: $selection, sortOrder: $sortOrder) {
        TableColumn("Coin") { opportunity in
          Text("\(opportunity.trades.first!.keys.first!.components(separatedBy: " ").first!)")
        }
        TableColumn("Volume") { opportunity in
          Text("Not Calc Yet")
        }
        TableColumn("% Profit") { opportunity in
          Text("\(opportunity.tradePercent)")
        }
      }
      .onChange(of: selection) {
        selectedOpportunity = opportunities.first(where: { $0.id == selection })
      }
    }
}

//#Preview {
//    OpportunityTableView()
//}
