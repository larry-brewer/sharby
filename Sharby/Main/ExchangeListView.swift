//
//  ExchangeListView.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import Foundation

struct ExchangeListView: View {
  let exchange: Exchange

  var body: some View {
    Text("\(exchange.name)")
  }
}
