import SwiftUI

struct LocationSettingsView: View {
    @EnvironmentObject private var location: ObserverLocation
    @Environment(\.dismiss) private var dismiss
    @State private var latText = ""
    @State private var lonText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Observer Location").font(.title2.bold())
            Text(location.statusText).foregroundStyle(.secondary)
            Button("Use Current Location") {
                location.requestLocation()
            }
            Divider()
            Text("Manual lat / lon").font(.headline)
            HStack {
                TextField("Latitude", text: $latText)
                TextField("Longitude", text: $lonText)
            }
            Button("Apply Manual") {
                guard let lat = Double(latText), let lon = Double(lonText),
                      (-90...90).contains(lat), (-180...180).contains(lon) else { return }
                location.applyManual(lat: lat, lon: lon)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Done") { dismiss() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .onAppear {
            latText = String(format: "%.6f", location.latitude)
            lonText = String(format: "%.6f", location.longitude)
        }
    }
}
