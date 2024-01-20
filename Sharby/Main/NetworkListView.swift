//
//  CoinView.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import Foundation

struct NetworkListView: View {
  let network: Network

  var body: some View {
    Text("\(network.name)")
  }
}
