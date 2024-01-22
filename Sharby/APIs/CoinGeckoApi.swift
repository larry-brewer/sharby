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

  let modelContainer: ModelContainer
  let modelContext: ModelContext
  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelContext.autosaveEnabled = false
  }

  struct FetchNetworksResponse: Codable {
    let data:[Network]
  }

  func fetchTop10Networks() async -> [Network] {
    let networksUrl = URL(string: "\(BASE_URL)/networks")!
    var allNetworks: [Network] = []

    do {
      // Perform the API request and wait for the response
      let session = await URLSession(configuration: ProxyWrapper.shared().roundRobinProxyConfig())
      let (data, _) = try await session.data(from: networksUrl)

      // Parse the JSON response
      let json = try JSONSerialization.jsonObject(with: data, options: [])

      let allNetworksResp = try JSONDecoder().decode(FetchNetworksResponse.self, from: data)
      let topNetworks = allNetworksResp.data

      for network in topNetworks {
        if (Network.allowedNetworkIds.contains(network.id)) {
          modelContext.insert(network)
          allNetworks.append(network)
        }
      }
    } catch {
      // Handle errors
      print("Error: \(error)")
    }

    print("Fetched \(allNetworks.count) networks")

    return allNetworks
  }

  struct FetchDexesResponse: Codable {
    let data:[Exchange]
  }

  func fetchDexes(networkId: String) async -> [Exchange] {
    guard let network = try! modelContext.fetch(FetchDescriptor<Network>(predicate: #Predicate{ $0.id == networkId })).first else {
      print("Could not find network with id: \(networkId)")
      return []
    }
    
    let dexesUrl = URL(string: "\(BASE_URL)/networks/\(network.id)/dexes")!
    var allDexes: [Exchange] = []

    do {
      // Perform the API request and wait for the response
      let session = await URLSession(configuration: ProxyWrapper.shared().roundRobinProxyConfig())
      let (data, _) = try await session.data(from: dexesUrl)

      // Parse the JSON response
      let json = try JSONSerialization.jsonObject(with: data, options: [])

      let allDexesResponse = try JSONDecoder().decode(FetchDexesResponse.self, from: data)
      let dexes = allDexesResponse.data

      for dex in dexes {
        dex.networks.append(network)
        allDexes.append(dex)
      }
    } catch {
      // Handle errors
      print("Error: \(error)")
    }
    
    return allDexes
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
          switch error {
            case PoolParsingError.missingPrice:
              _ = "Mute this"
            default:
              print("Error decoding a Pool: \(error)")
          }
        }
      }
      self.data = decodedPools
    }
  }


  func fetchAllPools() async {
    let exchanges = try! modelContext.fetch(FetchDescriptor<Exchange>(sortBy: [SortDescriptor(\.name)]))

    var index = 0
    for dex in exchanges {
      Task {
       await fetchPoolsBy(dex: dex)
      }

      if (index == 0) {
        break
      }

      index += 1
    }
  }

  func fetchPoolsBy(dex: Exchange) async -> [Pool] {
    var allPools: [Pool] = []
    print("Starting pool fetch for dex \(dex)")
    await withTaskGroup(of: [Pool].self) { group in
      for network in dex.networks {
        for index in 1...2 { //Make this back to 10
          group.addTask {
            await fetchPoolsBy(dex: dex, network: network, index: index)
          }
        }
      }

      for await result in group {
        allPools.append(contentsOf: result)
      }
    }

    print("\(allPools.count) fetched for \(dex).")
    return allPools
  }

  func fetchPoolsBy(dex: Exchange, network: Network, index: Int) async -> [Pool] {
    let poolsUrl = URL(string: "\(BASE_URL)/networks/\(network.id)/dexes/\(dex.id)/pools?page=\(index)")!

    do {
      let session = await URLSession(configuration: ProxyWrapper.shared().roundRobinProxyConfig())
      let (data, _) = try await session.data(from: poolsUrl)
      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]

      let decoder = JSONDecoder()
      decoder.userInfo[CodingUserInfoKey(rawValue: "jsonDictionary")!] = json

      if (json.keys.contains("data")) {
        let poolsData = try decoder.decode(FetchPoolsResponse.self, from: data)

        let pools = poolsData.data
        
        for pool in pools {
          pool.name
          
          modelContext.insert(pool)
          pool.exchange = dex
          pool.network = network
        }

        return pools
      }
      else {
        print("Data missing: \(json)")
      }
    } catch {
      // Handle errors for each task
      print("Error in task: \(error)")
    }

    return []
  }
}
