//
//  ContentView.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var buttonTitle = "Start"

    var body: some View {
      VStack {
        HStack(spacing: 10) {
          VStack {
            Text("Opportunities")
              .font(.title)

            List {
              OpportunityListView(name: "Opportunity 1")
              OpportunityListView(name: "Opportunity 2")
              OpportunityListView(name: "Opportunity 3")
            }
          }

          VStack {
            Text("Coins")
              .font(.title)

            List {
              // Content for "Coins" table view
              CoinListView(name: "Bitcoin")
              CoinListView(name: "Ethereum")
              CoinListView(name:  "Litecoin")
              // Add more rows as needed
            }

            Text("Exchanges")
              .font(.title)

            List {
              // Content for "Exchanges" table view
              ExchangeListView(name: "Binance")
              ExchangeListView(name: "Coinbase")
              ExchangeListView(name: "Kraken")
              // Add more rows as needed
            }
          }
        }

        Button(action: {
          // Toggle button title between "Start" and "Stop"
          if buttonTitle == "Start" {
            buttonTitle = "Stop"
          } else {
            buttonTitle = "Start"
          }
        }) {
          Text(buttonTitle)
            .font(.title)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
      }
    }
}

#Preview {
    MainView()
        .modelContainer(for: Item.self, inMemory: true)
}
