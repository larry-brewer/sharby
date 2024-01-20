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

  @Query let networks: [Network]
  @Query let exchanges: [Exchange]
  @State var firstLoad = true

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

          List(networks) { network in
            NetworkListView(network: network)
          }

          Text("Exchanges")
            .font(.title)

          List(exchanges) { exchange in
            ExchangeListView(exchange: exchange)
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
    }.onAppear {
      Task {
        await loadData()
      }
    }
  }

  func loadData() async {
    if (!firstLoad) {
      return
    }

    self.firstLoad = false
//    try! modelContext.delete(model: Coin.self)
//    try! modelContext.delete(model: Network.self)
//    try! modelContext.delete(model: Exchange.self)
//    try! modelContext.delete(model: Pool.self)
    print("Done deleting")


    if (try! modelContext.fetch(FetchDescriptor<Coin>()).isEmpty) {
      await CoinMarketCapApi().fetchCoins(modelContext: modelContext)
      print("Fetched coins")
    }

    let ethNetworkFetchDescriptor = FetchDescriptor<Network>(predicate: #Predicate{ $0.id == "eth" })
    let ethFetch = try! modelContext.fetch(ethNetworkFetchDescriptor)

    var eth: Network
    if ethFetch.count == 0 {
      await CoinGeckoApi().fetchTop10Networks(modelContext: modelContext)
      print("Fetched networks")
    }

    eth = try! modelContext.fetch(ethNetworkFetchDescriptor).first!

    if (exchanges.isEmpty) {
      let _ = await CoinGeckoApi().fetchDexes(network: eth, modelContext: modelContext)
    }

    await ProxyWrapper.shared()
    for exchange in exchanges {
      print("Fetching pools from exchange: \(exchange.name)")
      await CoinGeckoApi().fetchPools(network: eth, dex: exchange, modelContext: modelContext)
    }

//    let pools = try! modelContext.fetch(FetchDescriptor<Pool>())
//    CrossExchangeArbyStrategy().perform(pools: pools)
  }
}

#Preview {
  MainView()
    .modelContainer(for: Network.self, inMemory: true)
}
