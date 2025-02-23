import SwiftUI

@main
struct Medicare: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Medicines", systemImage: "pills.fill")
                        
                    }
                HistoryView()
                    .tabItem {
                        Label("History", systemImage: "calender.outline")
                        
                    }
                
            }
        }
    }
    
}

