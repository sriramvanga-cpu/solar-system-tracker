import SwiftUI
#if canImport(SolarCore)
import SolarCore
#endif

struct ContentView: View {
    @EnvironmentObject private var clock: SimulationClock
    @EnvironmentObject private var location: ObserverLocation
    @State private var selected: BodyID?
    @State private var showMoons = false
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                OrbitCanvas(date: clock.date, selected: $selected, showMoons: showMoons)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                TransportBar(showMoons: $showMoons, showSettings: $showSettings)
            }
            if let selected {
                BodyDetailPanel(bodyID: selected) {
                    self.selected = nil
                }
                .frame(width: 300)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selected)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            LocationSettingsView()
                .environmentObject(location)
                .frame(width: 360, height: 280)
        }
    }
}
