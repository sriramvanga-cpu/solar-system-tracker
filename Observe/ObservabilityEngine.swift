import Foundation

public struct Horizontal {
    public var altitude: Double // deg
    public var azimuth: Double  // deg, 0=N, 90=E
    public init(altitude: Double, azimuth: Double) { self.altitude = altitude; self.azimuth = azimuth }
}

public struct RiseSetTransit {
    public var rise: Date?
    public var transit: Date?
    public var set: Date?
    public init(rise: Date?, transit: Date?, set: Date?) { self.rise = rise; self.transit = transit; self.set = set }
}

public struct VisibilityWindow {
    public var start: Date?
    public var end: Date?
    public init(start: Date?, end: Date?) { self.start = start; self.end = end }
}

public struct BodySkyReport {
    public var altitude: Double
    public var azimuth: Double
    public var rise: Date?
    public var transit: Date?
    public var set: Date?
    public var visibleTonight: VisibilityWindow
    public var magnitude: Double?
    public var angularDiameterArcsec: Double
    public var distanceAU: Double
    public var distanceKm: Double
    public var illumination: Double? // 0...1
    public var aboveHorizon: Bool
    public init(altitude: Double, azimuth: Double, rise: Date?, transit: Date?, set: Date?, visibleTonight: VisibilityWindow, magnitude: Double?, angularDiameterArcsec: Double, distanceAU: Double, distanceKm: Double, illumination: Double?, aboveHorizon: Bool) {
        self.altitude = altitude; self.azimuth = azimuth; self.rise = rise; self.transit = transit; self.set = set
        self.visibleTonight = visibleTonight; self.magnitude = magnitude; self.angularDiameterArcsec = angularDiameterArcsec
        self.distanceAU = distanceAU; self.distanceKm = distanceKm; self.illumination = illumination; self.aboveHorizon = aboveHorizon
    }
}

public enum ObservabilityEngine {
    public static func localSiderealTimeHours(date: Date, longitudeDeg: Double) -> Double {
        let jd = Astro.julianDay(date)
        let T = Astro.centuriesSinceJ2000(jd)
        // GMST hours (approx)
        var gmst = 18.697374558 + 24.06570982441908 * (jd - 2_451_545.0)
        gmst += 0.000026 * T * T
        let lst = gmst + longitudeDeg / 15
        var x = lst.truncatingRemainder(dividingBy: 24)
        if x < 0 { x += 24 }
        return x
    }

    public static func horizontal(eq: Equatorial, date: Date, latDeg: Double, lonDeg: Double) -> Horizontal {
        let lst = localSiderealTimeHours(date: date, longitudeDeg: lonDeg)
        let ha = (lst - eq.ra) * 15 * Astro.deg // hour angle rad
        let dec = eq.dec * Astro.deg
        let lat = latDeg * Astro.deg
        let sinAlt = sin(dec) * sin(lat) + cos(dec) * cos(lat) * cos(ha)
        let alt = asin(min(1, max(-1, sinAlt)))
        let cosAz = (sin(dec) - sin(lat) * sin(alt)) / (cos(lat) * cos(alt) + 1e-15)
        let sinAz = -sin(ha) * cos(dec) / (cos(alt) + 1e-15)
        var az = atan2(sinAz, cosAz) * Astro.rad
        if az < 0 { az += 360 }
        return Horizontal(altitude: alt * Astro.rad, azimuth: az)
    }

    public static func altitude(of id: BodyID, date: Date, lat: Double, lon: Double) -> Double {
        horizontal(eq: EphemerisEngine.equatorial(id, date: date), date: date, latDeg: lat, lonDeg: lon).altitude
    }

    /// Sample local civil day (timezone from longitude); interpolate horizon crossings. Transit = max altitude.
    public static func riseSetTransit(of id: BodyID, day: Date, lat: Double, lon: Double, stepMinutes: Int = 3) -> RiseSetTransit {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: Int((lon / 15.0) * 3600)) ?? TimeZone(secondsFromGMT: 0)!
        let start = cal.startOfDay(for: day)
        let step = TimeInterval(stepMinutes * 60)
        var rise: Date?
        var set: Date?
        var transit: Date?
        var maxAlt = -90.0
        var prevAlt = altitude(of: id, date: start, lat: lat, lon: lon)
        var t = start
        let end = start.addingTimeInterval(86_400)
        while t <= end {
            let next = min(t.addingTimeInterval(step), end)
            let alt = altitude(of: id, date: next, lat: lat, lon: lon)
            if alt > maxAlt { maxAlt = alt; transit = next }
            if prevAlt < 0 && alt >= 0 && rise == nil {
                rise = interpolateCrossing(t0: t, a0: prevAlt, t1: next, a1: alt)
            }
            if prevAlt >= 0 && alt < 0 && set == nil {
                set = interpolateCrossing(t0: t, a0: prevAlt, t1: next, a1: alt)
            }
            prevAlt = alt
            t = next
            if t == end { break }
        }
        return RiseSetTransit(rise: rise, transit: transit, set: set)
    }

    private static func interpolateCrossing(t0: Date, a0: Double, t1: Date, a1: Double) -> Date {
        let f = abs(a0) / (abs(a0) + abs(a1) + 1e-15)
        return t0.addingTimeInterval(t1.timeIntervalSince(t0) * f)
    }

    /// Body above horizon and Sun below civil twilight (−6°) on that night (observer-local civil day).
    public static func visibleTonight(of id: BodyID, day: Date, lat: Double, lon: Double, stepMinutes: Int = 5) -> VisibilityWindow {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: Int((lon / 15.0) * 3600)) ?? TimeZone(secondsFromGMT: 0)!
        let start = cal.startOfDay(for: day)
        let step = TimeInterval(stepMinutes * 60)
        var first: Date?
        var last: Date?
        var t = start
        let end = start.addingTimeInterval(86_400)
        while t <= end {
            let bodyAlt = altitude(of: id, date: t, lat: lat, lon: lon)
            let sunAlt = altitude(of: .sun, date: t, lat: lat, lon: lon)
            if bodyAlt > 0 && sunAlt < -6 {
                if first == nil { first = t }
                last = t
            }
            let next = t.addingTimeInterval(step)
            if next > end { break }
            t = next
        }
        return VisibilityWindow(start: first, end: last)
    }

    public static func angularDiameterArcsec(of id: BodyID, date: Date) -> Double {
        let distKm = EphemerisEngine.distanceAU(id, date: date) * Astro.auKm
        let r = BodyCatalog.info(id).radiusKm
        guard distKm > 0 else { return 0 }
        return 2 * atan(r / distKm) * Astro.rad * 3600
    }

    public static func illumination(of id: BodyID, date: Date) -> Double? {
        switch id {
        case .sun, .earth: return nil
        case .moon:
            // Illuminated fraction from geocentric elongation (new⇒0, full⇒1).
            let sun = EphemerisEngine.geocentric(.sun, date: date)
            let moon = EphemerisEngine.geocentric(.moon, date: date)
            let cosElong = (sun.x * moon.x + sun.y * moon.y + sun.z * moon.z)
                / (sun.length * moon.length + 1e-15)
            return (1 - min(1, max(-1, cosElong))) / 2
        default:
            let body = EphemerisEngine.heliocentric(id, date: date)
            let earth = EphemerisEngine.heliocentric(.earth, date: date)
            let r = body.length
            let delta = (body - earth).length
            let R = earth.length
            let cosPhase = (r * r + delta * delta - R * R) / (2 * r * delta + 1e-15)
            return (1 + min(1, max(-1, cosPhase))) / 2
        }
    }

    public static func magnitude(of id: BodyID, date: Date) -> Double? {
        let info = BodyCatalog.info(id)
        switch id {
        case .sun: return -26.74
        case .earth: return nil
        case .moon:
            let illum = illumination(of: .moon, date: date) ?? 0.5
            let dist = EphemerisEngine.distanceAU(.moon, date: date) * Astro.auKm / 384_400
            // Rough: full moon −12.7, scales with illuminated fraction + distance.
            return -12.7 + 2.5 * log10(max(0.05, 1 / (illum + 1e-3))) + 5 * log10(max(0.1, dist))
        default:
            let r = EphemerisEngine.heliocentric(id, date: date).length
            let delta = EphemerisEngine.distanceAU(id, date: date)
            let R = EphemerisEngine.heliocentric(.earth, date: date).length
            let cosPhase = (r * r + delta * delta - R * R) / (2 * r * delta + 1e-15)
            let phase = acos(min(1, max(-1, cosPhase))) * Astro.rad
            // ponytail: simple phase function; HG if asteroid photometry needed.
            let phaseMag = 0.026 * phase + 4.2e-9 * pow(phase, 3) // deg form (Bowell-ish)
            return info.H + 5 * log10(max(1e-6, r * delta)) + phaseMag
        }
    }

    public static func report(for id: BodyID, date: Date, lat: Double, lon: Double) -> BodySkyReport {
        let eq = EphemerisEngine.equatorial(id, date: date)
        let hor = horizontal(eq: eq, date: date, latDeg: lat, lonDeg: lon)
        let rst = riseSetTransit(of: id, day: date, lat: lat, lon: lon)
        let distAU = EphemerisEngine.distanceAU(id, date: date)
        return BodySkyReport(
            altitude: hor.altitude,
            azimuth: hor.azimuth,
            rise: rst.rise,
            transit: rst.transit,
            set: rst.set,
            visibleTonight: id == .sun ? VisibilityWindow(start: nil, end: nil) : visibleTonight(of: id, day: date, lat: lat, lon: lon),
            magnitude: magnitude(of: id, date: date),
            angularDiameterArcsec: angularDiameterArcsec(of: id, date: date),
            distanceAU: distAU,
            distanceKm: distAU * Astro.auKm,
            illumination: illumination(of: id, date: date),
            aboveHorizon: hor.altitude > 0
        )
    }
}
