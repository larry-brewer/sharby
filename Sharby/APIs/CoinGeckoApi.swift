//
//  CoinGeckoApi.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import Foundation
import SwiftData

struct CoinGeckoApi {

  let API_KEY = "CG-uFsg9JLAw7UeECihpwjLM4ys" //For non dex
  let BASE_URL = "https://api.geckoterminal.com/api/v2"

  /**
   For all exchanges
   Get the price of all coins
   // Parse the JSON response
   let json = try JSONSerialization.jsonObject(with: data, options: [])

   */
  func fetchPrices() {

  }
  
  struct FetchDexesResponse: Codable {
    let data:[Exchange]
  }
  func fetchDexes(network: Network, modelContext: ModelContext) async {
    let dexesUrl = URL(string: "\(BASE_URL)/networks/\(network.id)/dexes")!
    var allDexes: [Exchange] = []

    do {
      // Perform the API request and wait for the response
      let (data, _) = try await URLSession.shared.data(from: dexesUrl)

      // Parse the JSON response
            let json = try JSONSerialization.jsonObject(with: data, options: [])

      let allDexesResponse = try JSONDecoder().decode(FetchDexesResponse.self, from: data)
      let dexes = allDexesResponse.data

      for dex in dexes {
        modelContext.insert(dex)
        allDexes.append(dex)
      }

      try modelContext.save()

    } catch {
      // Handle errors
      print("Error: \(error)")
    }

    print("Dexes count: \(allDexes.count)")
  }


  struct FetchNetworksResponse: Codable {
    let data:[Network]
  }
  func fetchTop10Networks(modelContext: ModelContext) async {
    let networksUrl = URL(string: "\(BASE_URL)/networks")!
    var allNetworks: [Network] = []

    do {
      // Perform the API request and wait for the response
      let (data, _) = try await URLSession.shared.data(from: networksUrl)

      // Parse the JSON response
      let json = try JSONSerialization.jsonObject(with: data, options: [])

      let allNetworksResp = try JSONDecoder().decode(FetchNetworksResponse.self, from: data)
      let topNetworks = allNetworksResp.data.prefix(10)

      for network in topNetworks {
        modelContext.insert(network)
        allNetworks.append(network)
      }

      try modelContext.save()

    } catch {
      // Handle errors
      print("Error: \(error)")
    }

    print("Network count: \(allNetworks.count)")
  }

  struct FetchPoolsResponse: Codable {
    let data: [Pool]

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      var dataContainer = try container.nestedUnkeyedContainer(forKey: .data)

      var decodedPools: [Pool] = []
      while !dataContainer.isAtEnd {
        do {
          let pool = try dataContainer.decode(Pool.self)
          decodedPools.append(pool)
        } catch {
          print("Error decoding a Pool: \(error)")
        }
      }
      self.data = decodedPools
    }
  }

  func fetchPools(network: Network, dex: Exchange, modelContext: ModelContext) async {
    var allPools: [Pool] = []

    for index in 1...10 {
      let poolsUrl = URL(string: "\(BASE_URL)/networks/\(network.id)/dexes/\(dex.id)/pools?page=\(index)")!

      do {
        let session = await URLSession(configuration: ProxyWrapper.shared().roundRobinProxyConfig())
        let (data, _) = try await session.data(from: poolsUrl)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

        if (json.keys.contains("data")) {
          let poolsData = try JSONDecoder().decode(FetchPoolsResponse.self, from: data)

          let pools = poolsData.data
          allPools.append(contentsOf: pools)

          if (pools.count < 20) {
            break
          }
        }
        else {
          print("Data missing: \(json)")
        }
      } catch {
        // Handle errors for each task
        print("Error in task: \(error)")
      }
    }

    for pool in allPools {
      modelContext.insert(pool)
    }

    print("Pool count: \(allPools.count)")
    do {
      try modelContext.save()
    } catch {
      // Handle errors in each individual task
      print("Error in fetching: \(error)")
    }
  }
}
