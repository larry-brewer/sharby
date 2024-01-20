//
//  CoinMarketCapApi.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

struct CoinMarketCapApi {
  let API_KEY = "3cb8a9a0-d42a-48f9-905c-661b51812238"
  let MAX_COIN_RANK = 100

  struct FetchCoinsResponse: Codable {
    let data:[Coin]
  }

  func fetchCoins(modelContext: ModelContext) async {
    let coinsUrl = URL(string: "https://pro-api.coinmarketcap.com/v1/cryptocurrency/map?sort=cmc_rank&CMC_PRO_API_KEY=\(API_KEY)")!

    do {
      // Perform the API request and wait for the response
      let (data, _) = try await URLSession.shared.data(from: coinsUrl)

      // Parse the JSON response
      let json = try JSONSerialization.jsonObject(with: data, options: [])

      let fetchCoinsResponse = try JSONDecoder().decode(FetchCoinsResponse.self, from: data)
      let coins = fetchCoinsResponse.data

      for coin in coins {
        modelContext.insert(coin)
        if (coin.rank == MAX_COIN_RANK) {
          break
        }
      }

      try modelContext.save()
      print("Coin count: \(coins.count)")
    } catch {
      // Handle errors
      print("Error: \(error)")
    }
  }
}

