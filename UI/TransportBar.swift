import SwiftUI

struct TransportBar: View {
    @EnvironmentObject private var clock: SimulationClock
    @Binding var showMoons: Bool
    @Binding var showSettings: Bool

    var body: some View {
        HStack(spacing: 12) {
            DatePicker("", selection: $clock.date)
                .labelsHidden()
                .frame(width: 180)

            Button {
                clock.togglePlay()
            } label: {
                Image(systemName: clock.isPlaying ? "pause.fill" : "play.fill")
            }
            .help(clock.isPlaying ? "Pause" : "Play")

            Picker("Speed", selection: $clock.speedDaysPerSecond) {
                ForEach(SimulationClock.speeds, id: \.days) { s in
                    Text(s.label).tag(s.days)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 280)

            Toggle("Moons", isOn: $showMoons)
                .toggleStyle(.checkbox)
                .frame(width: 80)

            Spacer()

            Button {
                clock.pause()
                clock.date = .now
            } label: {
                Text("Now")
            }

            Button {
                showSettings = true
            } label: {
                Image(systemName: "location.circle")
            }
            .help("Observer location")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}
