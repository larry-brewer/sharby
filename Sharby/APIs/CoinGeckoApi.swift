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
  
  let MARKET_CAP_MINIMUM = Decimal(100_000)


  let modelContainer: ModelContainer
  let modelContext: ModelContext

  init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelContext.autosaveEnabled = true
  }

  struct FetchNetworksResponse: Codable {
    let data:[Network]
  }

  func fetchTop10Networks() async -> [Network] {
    let networksUrl = URL(string: "\(BASE_URL)/networks")!
    var allNetworks: [Network] = []

    do {
      // Perform the API request and wait for the response

      let result = try await fetchData(url: networksUrl)

      if let data = result.data {
        let allNetworksResp = try JSONDecoder().decode(FetchNetworksResponse.self, from: data)
        let topNetworks = allNetworksResp.data

        for network in topNetworks {
          modelContext.insert(network)
          allNetworks.append(network)
          break
        }
      }
    } catch {
      // Handle errors
      print("Network Error: \(error)")
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
      let result = try await fetchData(url: dexesUrl)

      if let data = result.data {
        let allDexesResponse = try JSONDecoder().decode(FetchDexesResponse.self, from: data)
        let dexes = allDexesResponse.data

        for dex in dexes {
          dex.networks.append(network)
          allDexes.append(dex)
        }
      }

    } catch {
      // Handle errors
      print("Dex Error: \(error)")
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
    
    print("Fetching pools for \(exchanges.count)")
    var index = 0
    for dex in exchanges {
      Task {
       await fetchPoolsBy(dex: dex)
      }

      index += 1
    }
  }

  func fetchPoolsBy(dex: Exchange) async -> [Pool] {
    var allPools: [Pool] = []

    await withTaskGroup(of: [Pool].self) { group in
      for network in dex.networks {
        for index in 1...10{ //TODO Make this back to 10
          if network.name == "Ethereum" {
            print("Fetching pools by \(dex.name): \(network.name)")
            group.addTask {
              await CoinGeckoApi(modelContainer: modelContainer).fetchPoolsBy(dex: dex, network: network, index: index)
            }
          }
        }
      }

      for await result in group {
        allPools.append(contentsOf: result)
        try! result.first?.modelContext?.save()
      }
    }

    print("\(allPools.count) fetched for \(dex).")
    return allPools
  }

  func fetchPoolsBy(dex: Exchange, network: Network, index: Int) async -> [Pool] {
    let poolsUrl = URL(string: "\(BASE_URL)/networks/\(network.id)/dexes/\(dex.id)/pools?page=\(index)")!

    do {
      let result = try await fetchData(url: poolsUrl)

      if let data = result.data {

        let poolsData = try JSONDecoder().decode(FetchPoolsResponse.self, from: data)

        let pools = poolsData.data

        for pool in pools {
          modelContext.insert(pool)
          pool.exchange = dex
          pool.network = network
        }

        return pools
      }
    } catch {
      // Handle errors for each task
      print("Error in task: \(error)")
    }

    return []
  }

//  TODO make this return a codable using generics
  func fetchData(url:URL) async throws -> (data: Data?, json: Any?) {
    let session = await URLSession(configuration: ProxyWrapper.shared(modelContainer: modelContainer).roundRobinProxyConfig())

    do {
      let (data, _) = try await session.data(from: url)
//      TODO Dex Error still throwing parsing and not being caught below
      let json = try JSONSerialization.jsonObject(with: data, options: [])
      //      let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
      //
      //      let decoder = JSONDecoder()
      //      decoder.userInfo[CodingUserInfoKey(rawValue: "jsonDictionary")!] = json
      return (data, json)
    }
    catch let error as NSError where error._domain == kCFErrorDomainCFNetwork as String && error._code == 310 {
      if let proxyUrl = session.configuration.connectionProxyDictionary?[kCFNetworkProxiesHTTPProxy as String] as? String,
         let proxyPort = session.configuration.connectionProxyDictionary?[kCFNetworkProxiesHTTPPort as String] as? Int {
        await ProxyWrapper.shared(modelContainer: modelContainer).denyListProxy(proxyString: "\(proxyUrl):\(proxyPort)")

        return try await fetchData(url: url) //Try again? Hopefully this will never cause an infinite recursion, no?
      }
      else {
        print("Could not find failing proxy")
        throw error
      }

    }
    catch let error as NSError where error._domain == kCFErrorDomainCFNetwork as String && error._code == 3840 {
      print("Could not parse JSON")
      return (nil, nil)
    }
    catch {
      throw error
    }
  }
}
