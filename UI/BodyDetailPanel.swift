import SwiftUI
#if canImport(SolarCore)
import SolarCore
#endif

struct BodyDetailPanel: View {
    let bodyID: BodyID
    var onClose: () -> Void

    @EnvironmentObject private var clock: SimulationClock
    @EnvironmentObject private var location: ObserverLocation

    private var report: BodySkyReport {
        ObservabilityEngine.report(
            for: bodyID,
            date: clock.date,
            lat: location.latitude,
            lon: location.longitude
        )
    }

    private var isSun: Bool { bodyID == .sun }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Circle().fill({
                    let c = BodyCatalog.info(bodyID).color
                    return Color(red: c.r, green: c.g, blue: c.b)
                }()).frame(width: 12, height: 12)
                Text(bodyID.displayName).font(.title2.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    row("Altitude", String(format: "%.1f°", report.altitude))
                    row("Azimuth", String(format: "%.1f°", report.azimuth))
                    row("Above horizon", report.aboveHorizon ? "Yes" : "No")
                    row("Rise", fmt(report.rise))
                    row("Transit", fmt(report.transit))
                    row("Set", fmt(report.set))
                    if !isSun {
                        row("Visible tonight", visibleText(report.visibleTonight))
                        if let m = report.magnitude {
                            row("Magnitude", String(format: "%.2f", m))
                        }
                    }
                    row("Angular size", angSize(report.angularDiameterArcsec))
                    if bodyID != .earth {
                        row("Distance", distText(report))
                    }
                    if let ill = report.illumination, !isSun {
                        row("Illumination", String(format: "%.0f%%", ill * 100))
                    }
                    Text("From \(String(format: "%.2f°", location.latitude)), \(String(format: "%.2f°", location.longitude))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                .padding()
            }
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(.body)
    }

    private func fmt(_ d: Date?) -> String {
        guard let d else { return "—" }
        let tz = TimeZone(secondsFromGMT: Int((location.longitude / 15.0) * 3600)) ?? .current
        let f = Date.FormatStyle(date: .omitted, time: .shortened).timeZone(tz)
        return d.formatted(f)
    }

    private func visibleText(_ w: VisibilityWindow) -> String {
        guard let s = w.start, let e = w.end else { return "Not tonight" }
        return "\(fmt(s)) – \(fmt(e))"
    }

    private func angSize(_ arcsec: Double) -> String {
        if arcsec >= 60 {
            return String(format: "%.2f′", arcsec / 60)
        }
        return String(format: "%.1f″", arcsec)
    }

    private func distText(_ r: BodySkyReport) -> String {
        if r.distanceAU < 0.01 {
            return String(format: "%.0f km", r.distanceKm)
        }
        return String(format: "%.4f AU", r.distanceAU)
    }
}
