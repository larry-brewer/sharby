//
//  Decoder+JSON.swift
//  Sharby
//
//  Created by Larry Brewer on 1/21/24.
//

import Foundation

extension Decoder {
  func currentlyDecodingJSON() -> Any? {
    guard let json = userInfo[CodingUserInfoKey(rawValue: "jsonDictionary")!] else {
      return nil
    }

    return jsonAtPath(codingPath, in: json)
  }

  func jsonAtPath<T: Sequence>(_ path: T, in otherJSON: Any?) -> Any? where T.Element == CodingKey {
    guard let key = path.first(where: {_ in true}) else { return otherJSON }

    if let index = key.intValue {
      guard let array = otherJSON as? [Any] else { return otherJSON }
      return jsonAtPath(codingPath.dropFirst(), in: array[index])
    }
    guard let dictionary = otherJSON as? [String: Any] else { return otherJSON }
    return jsonAtPath(codingPath.dropFirst(), in: dictionary[key.stringValue])

  }
}
