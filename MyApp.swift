import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Medicines", systemImage: "pills.fill")
                    }
            }
        }
    }
}
