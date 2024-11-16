//
//  Proxy.swift
//  Sharby
//
//  Created by Larry Brewer on 1/23/24.
//

import Foundation
import SwiftData

enum ProxyParsingError: Error {
  case missingName
  // Add other cases for different error types as needed
}

@Model
final class Proxy: Codable, CustomDebugStringConvertible {
  var debugDescription: String {
    "\(self.name)"
  }

  @Attribute(.unique) var name: String
  var url: String
  var port: Int
  var status: String
  var countryCode: String

  var denyListed = false

  enum CodingKeys: String, CodingKey {
    case name
  }

  required init(from decoder: Decoder) throws {
    var container = try decoder.unkeyedContainer()
    do {
      let name = try container.decode(String.self)

      let proxyParts = name.split(separator: ":")
      self.name = name
      self.url = String(proxyParts.first!)
      self.port = Int(proxyParts.last!)!

      _ = try container.decode(String.self) //HTTP or sock
      self.status = try container.decode(String.self)
      self.countryCode = try container.decode(String.self)
    }
    catch {
      throw ProxyParsingError.missingName
    }
  }

  func encode(to encoder: Encoder) throws {

  }
}
