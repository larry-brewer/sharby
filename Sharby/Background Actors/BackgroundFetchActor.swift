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
  
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    let context = ModelContext(modelContainer)
    modelExecutor = DefaultSerialModelExecutor(modelContext: context)
  }
  
  func fetchAllData() async {
//    modelContext.container.deleteAllData() // Wipes all local data
    //    try! modelContext.delete(model: Coin.self)
//    try! modelContext.delete(model: Network.self)
//    try! modelContext.delete(model: Exchange.self)
//    try! modelContext.delete(model: Pool.self)
//        print("Done deleting")
    
    _ = await ProxyWrapper.shared(modelContainer: modelContainer)

//    if (try! modelContext.fetch(FetchDescriptor<Coin>()).isEmpty) {
//      await CoinMarketCapApi(modelContainer: modelContainer).fetchCoins()
//      print("Fetched coins")
//    }
    
    let fetchedNetworks = await CoinGeckoApi(modelContainer: modelContainer).fetchTop10Networks()
    try! fetchedNetworks.first?.modelContext?.save()


    await withTaskGroup(of: [Exchange].self) { group in
      let networks = try! modelContext.fetch(FetchDescriptor<Network>())

      for network in networks {
        group.addTask {
          await CoinGeckoApi(modelContainer: self.modelContainer).fetchDexes(networkId: network.id)
        }
      }

      var exchangesCount = 0
      for await result in group {
        exchangesCount += result.count
        try! result.first?.modelContext?.save()
      }

      print("Fetched \(exchangesCount) exchanges")
    }

    await CoinGeckoApi(modelContainer: modelContainer).fetchAllPools()

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
