//
//  ProxyWrapper.swift
//  Sharby
//
//  Created by Larry Brewer on 1/20/24.
//

import Foundation

actor ProxyWrapper {
  // Static property for the singleton instance
  private static var instance: ProxyWrapper?
  // Private initializer to restrict instantiation
  private init() { }
  
  static func shared() async -> ProxyWrapper {
    if ProxyWrapper.instance == nil {
      ProxyWrapper.instance = ProxyWrapper()

      await ProxyWrapper.instance!.fetchProxies()
    }

    return ProxyWrapper.instance!
  }


  let api_key = "tbao5onmzszuo4f1c55h"
  var proxies: [String]?

  var proxy_cap_per_minute = 29
  var proxy_request_count = [String:Int]()

  func roundRobinProxyConfig() -> URLSessionConfiguration {
    let configuration = URLSessionConfiguration.default
    
    var proxy: String?

    repeat {
      if let randomProxy = proxies?.randomElement() {
        if ((proxy_request_count[randomProxy] ?? 0) < proxy_cap_per_minute) {
          proxy = randomProxy
          proxy_request_count[randomProxy] = (proxy_request_count[randomProxy] ?? 0) + 1

          Task {
            try await Task.sleep(nanoseconds: 60 * 1_000_000_000)
            
            print("reducing \(randomProxy) by 1")
            self.proxy_request_count[randomProxy]! -= 1
          }
        }
      }
    } while proxy == nil
    
    let proxyParts = proxy?.split(separator: ":")
    print("Using proxy: \(proxyParts)")
    configuration.connectionProxyDictionary = [
      kCFNetworkProxiesHTTPEnable as String: 1,
      kCFNetworkProxiesHTTPProxy as String: proxyParts!.first!,
      kCFNetworkProxiesHTTPPort as String: Int(proxyParts!.last!)!,
      kCFNetworkProxiesHTTPSEnable as String: 1,
      kCFNetworkProxiesHTTPSProxy as String: proxyParts!.first!,
      kCFNetworkProxiesHTTPSPort as String: Int(proxyParts!.last!)!
    ]

    return configuration
  }

  func fetchProxies() async {
    print("fetching proxies")
    guard let url = URL(string: "https://api.proxyscrape.com/v2/account/datacenter_shared/proxy-list?auth=\(api_key)&type=getproxies&country[]=all&protocol=http&format=normal&status=all") else {
      print("Invalid proxies URL")
      return
    }

    do {
      // Perform the network request asynchronously
      let (data, _) = try await URLSession.shared.data(from: url)

      // Process the received data
      if let dataString = String(data: data, encoding: .utf8) {
        proxies = dataString.components(separatedBy: "\r\n")
        print("Fetched \(proxies!.count) proxies")
      }
    } catch {
      // Handle errors
      print("Error fetching proxies: \(error)")
    }
  }
}
