import SwiftUI

@main
struct SolarSystemTrackerApp: App {
    @StateObject private var clock = SimulationClock()
    @StateObject private var location = ObserverLocation()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clock)
                .environmentObject(location)
                .frame(minWidth: 900, minHeight: 600)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
