import Foundation

public struct Equatorial {
    public var ra: Double   // hours 0...24
    public var dec: Double  // degrees
    public init(ra: Double, dec: Double) { self.ra = ra; self.dec = dec }
}

public enum EphemerisEngine {
    public static func heliocentric(_ id: BodyID, date: Date) -> Vec3 {
        if id == .sun { return Vec3(x: 0, y: 0, z: 0) }
        let T = Astro.centuriesSinceJ2000(Astro.julianDay(date))
        let info = BodyCatalog.info(id)
        guard let el = info.elements else { return .init(x: 0, y: 0, z: 0) }
        if let parent = id.parent {
            let parentPos = heliocentric(parent, date: date)
            return parentPos + Kepler.heliocentric(elements: el, T: T)
        }
        return Kepler.heliocentric(elements: el, T: T)
    }

    /// Geocentric ecliptic AU (Sun = −Earth).
    public static func geocentric(_ id: BodyID, date: Date) -> Vec3 {
        let earth = heliocentric(.earth, date: date)
        if id == .earth { return Vec3(x: 0, y: 0, z: 0) }
        return heliocentric(id, date: date) - earth
    }

    public static func equatorial(_ id: BodyID, date: Date) -> Equatorial {
        let g = geocentric(id, date: date)
        let eps = Astro.obliquity * Astro.deg
        let xe = g.x
        let ye = g.y * cos(eps) - g.z * sin(eps)
        let ze = g.y * sin(eps) + g.z * cos(eps)
        var ra = atan2(ye, xe) * Astro.rad / 15 // hours
        if ra < 0 { ra += 24 }
        let dec = atan2(ze, sqrt(xe * xe + ye * ye)) * Astro.rad
        return Equatorial(ra: ra, dec: dec)
    }

    public static func distanceAU(_ id: BodyID, date: Date) -> Double {
        geocentric(id, date: date).length
    }
}
