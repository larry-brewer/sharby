//
//  BackgroundFetchActor.swift
//  Sharby
//
//  Created by Larry Brewer on 1/21/24.
//

import Foundation
import SwiftData

actor BackgroundFetchActor: ModelActor {
  let modelContainer: ModelContainer
  let modelExecutor: any ModelExecutor
  
  let coinGeckoApi: CoinGeckoApi
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    modelExecutor = DefaultSerialModelExecutor(modelContext: context)

    self.coinGeckoApi = CoinGeckoApi(modelContainer: modelContainer)
  }
  
  func fetchAllData() async {
    //    try! modelContext.delete(model: Coin.self)
    try! modelContext.delete(model: Network.self)
    try! modelContext.delete(model: Exchange.self)
    try! modelContext.delete(model: Pool.self)
        print("Done deleting")
    
    _ = await ProxyWrapper.shared()

    if (try! modelContext.fetch(FetchDescriptor<Coin>()).isEmpty) {
      await CoinMarketCapApi(modelContainer: modelContainer).fetchCoins()
      print("Fetched coins")
    }

    let ethNetworkFetchDescriptor = FetchDescriptor<Network>()
    var networks = try! modelContext.fetch(ethNetworkFetchDescriptor)

    if networks.count == 0 {
      networks = await coinGeckoApi.fetchTop10Networks()
      try! coinGeckoApi.modelContext.save()
    }


    await withTaskGroup(of: [Exchange].self) { group in
      let exchanges = try! modelContext.fetch(FetchDescriptor<Exchange>())
      
      if (exchanges.isEmpty) {
        for network in networks {
          group.addTask {
            await CoinGeckoApi(modelContainer: self.modelContainer).fetchDexes(networkId: network.id)
          }
        }

        var exchangesCount = 0
        for await result in group {
          exchangesCount += result.count
        }
        
        print("Fetched \(exchangesCount) exchanges")
      }
    }

    await coinGeckoApi.fetchAllPools()
    
//    All exchanges are being fetched for each network now. We may have to handle more than 1 network in each exchange
//    Pools are not fetching right now
//    Make exchange fetching trigger pool fetching
//    Make Strategies run 1/sec for now
//    Switch UI to be wallet instead of networks
//    Switch UI to be strategies instead of Exchanges
//    Add RPM to UI
//    Add check box for fetchData
//
  }
}
