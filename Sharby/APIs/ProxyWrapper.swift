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
  private init() {

  }

  static func shared() async -> ProxyWrapper {
    if ProxyWrapper.instance == nil {
      ProxyWrapper.instance = ProxyWrapper()

      await ProxyWrapper.instance!.startRpmTimer()

      await ProxyWrapper.instance!.fetchProxies()
    }

    return ProxyWrapper.instance!
  }


  let api_key = "tbao5onmzszuo4f1c55h"
  var proxies: [String]?
  var fetchingProxies = false

  var proxy_cap_per_minute = 29
  var proxy_request_count = [String:Int]()

  
  @Published var rpm = 0
  
  var isRpmTimerCancelled = false
  func startRpmTimer() {
    Task { [weak self] in
      while let strongSelf = self, await !strongSelf.isRpmTimerCancelled  {
        try await Task.sleep(nanoseconds: UInt64(60 * 1_000_000_000))
        await strongSelf.printRpm()
      }
    }
  }

  func printRpm() {
    if (self.rpm > 0) {
      print("RPM: \(self.rpm)")
    }
  }

  func roundRobinProxyConfig() async -> URLSessionConfiguration {
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
            self.rpm -= 1
          }
        }
      }

      try! await Task.sleep(nanoseconds: 500_000_000)
    } while proxy == nil || proxy!.isEmpty

    let proxyParts = proxy?.split(separator: ":")
    let url = proxyParts!.first!
    let ip = Int(proxyParts!.last!)!
    
    configuration.connectionProxyDictionary = [
      kCFNetworkProxiesHTTPEnable as String: 1,
      kCFNetworkProxiesHTTPProxy as String: url,
      kCFNetworkProxiesHTTPPort as String: ip,
      kCFNetworkProxiesHTTPSEnable as String: 1,
      kCFNetworkProxiesHTTPSProxy as String: url,
      kCFNetworkProxiesHTTPSPort as String: ip
    ]

    self.rpm += 1

    return configuration
  }

  func fetchProxies() async {
    if (fetchingProxies) {
      return
    }

    fetchingProxies = true

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
        fetchingProxies = false
      }
    } catch {
      // Handle errors
      print("Error fetching proxies: \(error)")
      fetchingProxies = false
    }
  }
}
