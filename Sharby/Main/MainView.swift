//
//  ContentView.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import SwiftData

struct MainView: View {
  @Environment(\.modelContext) private var modelContext
  @State private var buttonTitle = "Start"

  @Query var networks: [Network]
  @Query var exchanges: [Exchange]
  @State var firstLoad = true
  @State var rpm = 0

  var body: some View {
    VStack {
      HStack(spacing: 10) {
        VStack {
          Text("Opportunities")
            .font(.title)

          List {
            OpportunityListView()
          }
        }

        VStack {
          Text("Coins")
            .font(.title)

          List(networks) { network in
            NetworkListView(network: network)
          }

          Text("Exchanges")
            .font(.title)

          List(exchanges) { exchange in
            ExchangeListView(exchange: exchange)
          }
        }
      }

      Button(action: {
        // Toggle button title between "Start" and "Stop"
        if buttonTitle == "Start" {
          buttonTitle = "Stop"
        } else {
          buttonTitle = "Start"
        }
      }) {
        Text(buttonTitle)
          .font(.title)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      Text("RPM: \(rpm)").padding(20)

    }.onAppear {
      Task {
        await loadData()
      }
    }
  }

  func loadData() async {
    if (!firstLoad) {
      return
    }

    self.firstLoad = false

    Task {
      await BackgroundFetchActor(modelContainer: modelContext.container).fetchAllData()
//
      while true {
//        print("CrossDexArby start")
        let pools = try! modelContext.fetch(FetchDescriptor<Pool>())
        CrossExchangeArbyStrategy().triangularArbitrage(pools: pools, context: modelContext)
//         Wait for 1 minute (60 seconds)
        rpm = await ProxyWrapper.shared(modelContainer: modelContext.container).rpm
        try? await Task.sleep(nanoseconds: 1 * 1_000_000_000)
      }
//
    }
  }
}

#Preview {
  MainView()
    .modelContainer(for: Network.self, inMemory: true)
}
