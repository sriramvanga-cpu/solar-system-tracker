import Foundation

public enum Astro {
    public static let auKm = 149_597_870.7
    public static let deg = Double.pi / 180
    public static let rad = 180 / Double.pi
    /// J2000 obliquity of the ecliptic (degrees).
    public static let obliquity = 23.43928

    public static func julianDay(_ date: Date) -> Double {
        date.timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    public static func centuriesSinceJ2000(_ jd: Double) -> Double {
        (jd - 2_451_545.0) / 36_525
    }

    public static func norm360(_ d: Double) -> Double {
        var x = d.truncatingRemainder(dividingBy: 360)
        if x < 0 { x += 360 }
        return x
    }

    /// Solve Kepler's equation M = E − e sin E (angles in radians).
    public static func eccentricAnomaly(M: Double, e: Double) -> Double {
        var E = e < 0.8 ? M : Double.pi
        for _ in 0..<12 {
            let d = E - e * sin(E) - M
            E -= d / (1 - e * cos(E))
            if abs(d) < 1e-10 { break }
        }
        return E
    }
}

public struct Vec3: Equatable {
    public var x, y, z: Double
    public init(x: Double, y: Double, z: Double) { self.x = x; self.y = y; self.z = z }
    public var length: Double { sqrt(x * x + y * y + z * z) }
    public static func - (a: Vec3, b: Vec3) -> Vec3 { Vec3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z) }
    public static func + (a: Vec3, b: Vec3) -> Vec3 { Vec3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z) }
    public static func * (a: Vec3, s: Double) -> Vec3 { Vec3(x: a.x * s, y: a.y * s, z: a.z * s) }
}

public struct KeplerElements {
    /// Semi-major axis AU (or km for moon-around-planet, flagged via `aIsKm`).
    public var a: Double
    public var e: Double
    public var i: Double
    public var L: Double
    public var varpi: Double
    public var Omega: Double
    public var aDot: Double
    public var eDot: Double
    public var iDot: Double
    public var LDot: Double
    public var varpiDot: Double
    public var OmegaDot: Double
    public var aIsKm: Bool

    public init(
        a: Double, e: Double, i: Double, L: Double, varpi: Double, Omega: Double,
        aDot: Double = 0, eDot: Double = 0, iDot: Double = 0,
        LDot: Double = 0, varpiDot: Double = 0, OmegaDot: Double = 0, aIsKm: Bool = false
    ) {
        self.a = a; self.e = e; self.i = i; self.L = L; self.varpi = varpi; self.Omega = Omega
        self.aDot = aDot; self.eDot = eDot; self.iDot = iDot
        self.LDot = LDot; self.varpiDot = varpiDot; self.OmegaDot = OmegaDot; self.aIsKm = aIsKm
    }

    public func at(_ T: Double) -> (a: Double, e: Double, i: Double, L: Double, varpi: Double, Omega: Double) {
        (a + aDot * T, e + eDot * T, i + iDot * T, L + LDot * T, varpi + varpiDot * T, Omega + OmegaDot * T)
    }
}

public enum Kepler {
    /// Heliocentric ecliptic XYZ in AU (parent-centric moons converted to AU).
    public static func heliocentric(elements: KeplerElements, T: Double) -> Vec3 {
        let (a0, e, iDeg, L, varpi, Omega) = elements.at(T)
        let a = elements.aIsKm ? a0 / Astro.auKm : a0
        let M = Astro.norm360(L - varpi) * Astro.deg
        let E = Astro.eccentricAnomaly(M: M, e: e)
        let xv = a * (cos(E) - e)
        let yv = a * sqrt(max(0, 1 - e * e)) * sin(E)
        let v = atan2(yv, xv)
        let r = sqrt(xv * xv + yv * yv)
        let iw = (varpi - Omega) * Astro.deg
        let om = Omega * Astro.deg
        let i = iDeg * Astro.deg
        let xh = r * (cos(om) * cos(v + iw) - sin(om) * sin(v + iw) * cos(i))
        let yh = r * (sin(om) * cos(v + iw) + cos(om) * sin(v + iw) * cos(i))
        let zh = r * (sin(v + iw) * sin(i))
        return Vec3(x: xh, y: yh, z: zh)
    }
}
