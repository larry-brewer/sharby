//
//  ProxyWrapper.swift
//  Sharby
//
//  Created by Larry Brewer on 1/20/24.
//

import Foundation
import SwiftData

struct FetchProxiesResponse: Codable {
  let data:[Proxy]

}

actor ProxyWrapper {
  // Static property for the singleton instance
  private static var instance: ProxyWrapper?
  // Private initializer to restrict instantiation
  
  let modelContainer: ModelContainer
  let modelContext: ModelContext

  private init(modelContainer: ModelContainer) {
    self.modelContainer = modelContainer
    self.modelContext = ModelContext(modelContainer)
    self.modelContext.autosaveEnabled = true
  }

  static func shared(modelContainer: ModelContainer) async -> ProxyWrapper {
    if ProxyWrapper.instance == nil {
      ProxyWrapper.instance = ProxyWrapper(modelContainer: modelContainer)

//      await ProxyWrapper.instance!.loadProxies()

//      Task {
        await ProxyWrapper.instance!.fetchProxies()
//      }
    }

    return ProxyWrapper.instance!
  }

  let api_key = "tbao5onmzszuo4f1c55h"
  
  var proxies = [Proxy]()
  var denyListedProxies = [Proxy]()
  var fetchingProxies = false

  var proxy_cap_per_minute = 29
  var proxy_request_count = [Proxy:Int]()

  @Published var rpm = 0

  func loadProxies() {
    self.proxies = try! modelContext.fetch(FetchDescriptor<Proxy>())
  }

  func roundRobinProxyConfig() async -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default

    var proxy: Proxy?

    repeat {
      if let randomProxy = proxies.randomElement() {
        if ((proxy_request_count[randomProxy] ?? 0) < proxy_cap_per_minute) {
          proxy = randomProxy
          proxy_request_count[randomProxy] = (proxy_request_count[randomProxy] ?? 0) + 1

          Task {
            try await Task.sleep(nanoseconds: 60 * 1_000_000_000)

            print("reducing \(randomProxy) by 1")
            self.proxy_request_count[randomProxy]! -= 1
            self.rpm -= 1
          }
        }
      }

      try! await Task.sleep(nanoseconds: 500_000_000)
    } while proxy == nil

    
    if let proxy = proxy {
      configuration.connectionProxyDictionary = [
        kCFNetworkProxiesHTTPEnable as String: 1,
        kCFNetworkProxiesHTTPProxy as String: proxy.url,
        kCFNetworkProxiesHTTPPort as String: proxy.port,
        kCFNetworkProxiesHTTPSEnable as String: 1,
        kCFNetworkProxiesHTTPSProxy as String: proxy.url,
        kCFNetworkProxiesHTTPSPort as String: proxy.port
      ]
    }

    self.rpm += 1

    return configuration
  }

  func fetchProxies() async {
    if (fetchingProxies) { //This might be able to be removed
      return
    }

    fetchingProxies = true

    print("fetching proxies")
    guard let url = URL(string: "https://api.proxyscrape.com/v2/account/datacenter_shared/proxy-list?auth=\(api_key)&type=getproxies&country[]=all&protocol=http&format=json&status=all") else {
      print("Invalid proxies URL")
      return
    }

    do {
//      After parsing, filter the current proxy list for any proxies we should remove and remove them
//      Add a func to blacklist and save a proxy
//      Create a generic request wrapper and refactor CoinGeckoApi
      let (data, _) = try await URLSession.shared.data(from: url)

      let json = try JSONSerialization.jsonObject(with: data, options: [])
      
      let allProxiesResponse = try JSONDecoder().decode(FetchProxiesResponse.self, from: data)
      let proxies = allProxiesResponse.data
      
      for proxy in proxies {
        modelContext.insert(proxy)
      }
      
      try! modelContext.save()
      self.loadProxies()
    } catch {
      // Handle errors
      print("Error fetching proxies: \(error)")
      fetchingProxies = false
    }
  }

  func denyListProxy(proxyString: String) {
    if let proxy = proxies.first(where: { $0.name == proxyString } ) {

      proxies.removeAll { $0 == proxy }

      denyListedProxies.append(proxy)
    }
  }
}
