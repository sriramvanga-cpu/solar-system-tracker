import Foundation

/// Assert-based self-checks for ephemeris / observability.
public enum SelfChecks {
    public static func run() {
        let now = Date()
        let earthR = EphemerisEngine.heliocentric(.earth, date: now).length
        assert((0.98...1.02).contains(earthR), "Earth distance \(earthR) AU not ~1")
        print("OK Earth \(String(format: "%.5f", earthR)) AU")

        let moonArcsec = ObservabilityEngine.angularDiameterArcsec(of: .moon, date: now)
        let moonDeg = moonArcsec / 3600
        assert((0.45...0.60).contains(moonDeg), "Moon angular size \(moonDeg)° not ~0.5°")
        print("OK Moon \(String(format: "%.3f", moonDeg))°")

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: Int((-74.0 / 15.0) * 3600))!
        var c = DateComponents()
        c.year = 2024; c.month = 3; c.day = 20; c.hour = 12
        let day = cal.date(from: c)!
        let lat = 40.0, lon = -74.0
        let sun = ObservabilityEngine.riseSetTransit(of: .sun, day: day, lat: lat, lon: lon)
        assert(sun.rise != nil && sun.set != nil, "Sun missing rise/set at lat \(lat)")
        assert(sun.rise! < sun.set!, "Sun rise should be before set")
        print("OK Sun rise \(sun.rise!) < set \(sun.set!)")

        let moonAU = EphemerisEngine.distanceAU(.moon, date: now)
        let moonKm = moonAU * Astro.auKm
        assert((350_000...450_000).contains(moonKm), "Moon distance \(moonKm) km out of range")
        print("OK Moon distance \(String(format: "%.0f", moonKm)) km")

        print("All self-checks passed.")
    }
}
