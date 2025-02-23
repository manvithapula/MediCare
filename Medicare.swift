import SwiftUI

@main
struct Medicare: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Medications", systemImage: "pills")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "clock.badge.checkmark")
                    }
            }
            .tint(.blue) 
        }
    }
}
