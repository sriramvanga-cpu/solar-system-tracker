import Foundation

public struct BodyColor: Equatable {
    public var r, g, b: Double
    public static let yellow = BodyColor(r: 1, g: 0.9, b: 0.2)
    public init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
}

public enum BodyID: String, CaseIterable, Identifiable, Hashable {
    case sun, mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
    case moon, io, europa, ganymede, callisto, titan, triton
    case ceres, pluto

    public var id: String { rawValue }

    public var displayName: String {
        rawValue.prefix(1).uppercased() + rawValue.dropFirst()
    }

    /// Parent for satellite orbits; nil = heliocentric.
    public var parent: BodyID? {
        switch self {
        case .moon: return .earth
        case .io, .europa, .ganymede, .callisto: return .jupiter
        case .titan: return .saturn
        case .triton: return .neptune
        default: return nil
        }
    }

    public var isMoon: Bool { parent != nil }
}

public struct BodyInfo {
    public let id: BodyID
    public let elements: KeplerElements?
    /// Equatorial radius km.
    public let radiusKm: Double
    /// Visual absolute magnitude H (or special-cased in ObservabilityEngine).
    public let H: Double
    /// Geometric albedo (phase models).
    public let albedo: Double
    public let color: BodyColor
    public init(id: BodyID, elements: KeplerElements?, radiusKm: Double, H: Double, albedo: Double, color: BodyColor) {
        self.id = id; self.elements = elements; self.radiusKm = radiusKm; self.H = H; self.albedo = albedo; self.color = color
    }
}

public enum BodyCatalog {
    /// JPL Keplerian elements (approx) at J2000 + century rates. Source: NASA/JPL SSD.
    public static let all: [BodyInfo] = [
        BodyInfo(id: .sun, elements: nil, radiusKm: 695_700, H: -26.74, albedo: 1, color: .yellow),
        BodyInfo(id: .mercury, elements: KeplerElements(
            a: 0.38709927, e: 0.20563593, i: 7.00497902, L: 252.25032364, varpi: 77.45779628, Omega: 48.33076593,
            aDot: 0.00000037, eDot: 0.00001906, iDot: -0.00594749, LDot: 149472.67411175, varpiDot: 0.16047689, OmegaDot: -0.12534081
        ), radiusKm: 2439.7, H: -0.60, albedo: 0.142, color: BodyColor(r: 0.7, g: 0.7, b: 0.7)),
        BodyInfo(id: .venus, elements: KeplerElements(
            a: 0.72333566, e: 0.00677672, i: 3.39467605, L: 181.97909950, varpi: 131.60246718, Omega: 76.67984255,
            aDot: 0.00000390, eDot: -0.00004107, iDot: -0.00078890, LDot: 58517.81538729, varpiDot: 0.00268329, OmegaDot: -0.27769418
        ), radiusKm: 6051.8, H: -4.47, albedo: 0.689, color: BodyColor(r: 0.9, g: 0.8, b: 0.5)),
        BodyInfo(id: .earth, elements: KeplerElements(
            a: 1.00000261, e: 0.01671123, i: -0.00001531, L: 100.46457166, varpi: 102.93768193, Omega: 0.0,
            aDot: 0.00000562, eDot: -0.00004392, iDot: -0.01294668, LDot: 35999.37244981, varpiDot: 0.32327364, OmegaDot: 0.0
        ), radiusKm: 6371.0, H: -3.86, albedo: 0.367, color: BodyColor(r: 0.2, g: 0.5, b: 1.0)),
        BodyInfo(id: .mars, elements: KeplerElements(
            a: 1.52371034, e: 0.09339410, i: 1.84969142, L: -4.55343205, varpi: -23.94362959, Omega: 49.55953891,
            aDot: 0.00001847, eDot: 0.00007882, iDot: -0.00813131, LDot: 19140.30268499, varpiDot: 0.44441088, OmegaDot: -0.29257343
        ), radiusKm: 3389.5, H: -1.52, albedo: 0.170, color: BodyColor(r: 0.9, g: 0.3, b: 0.2)),
        BodyInfo(id: .jupiter, elements: KeplerElements(
            a: 5.20288700, e: 0.04838624, i: 1.30439695, L: 34.39644051, varpi: 14.72847983, Omega: 100.47390909,
            aDot: -0.00011607, eDot: -0.00013253, iDot: -0.00183714, LDot: 3034.74612775, varpiDot: 0.21252668, OmegaDot: 0.20469106
        ), radiusKm: 69_911, H: -9.40, albedo: 0.538, color: BodyColor(r: 0.9, g: 0.7, b: 0.5)),
        BodyInfo(id: .saturn, elements: KeplerElements(
            a: 9.53667594, e: 0.05386179, i: 2.48599187, L: 49.95424423, varpi: 92.59887831, Omega: 113.66242448,
            aDot: -0.00125060, eDot: -0.00050991, iDot: 0.00193609, LDot: 1222.49362201, varpiDot: -0.41897216, OmegaDot: -0.28867794
        ), radiusKm: 58_232, H: -8.88, albedo: 0.499, color: BodyColor(r: 0.9, g: 0.85, b: 0.5)),
        BodyInfo(id: .uranus, elements: KeplerElements(
            a: 19.18916545, e: 0.04725744, i: 0.77263783, L: 313.23810451, varpi: 170.95427630, Omega: 74.01692522,
            aDot: -0.00196176, eDot: -0.00004397, iDot: -0.00242939, LDot: 428.48202785, varpiDot: 0.40805281, OmegaDot: 0.04240589
        ), radiusKm: 25_362, H: -7.19, albedo: 0.488, color: BodyColor(r: 0.5, g: 0.8, b: 0.9)),
        BodyInfo(id: .neptune, elements: KeplerElements(
            a: 30.06992276, e: 0.00859048, i: 1.77004347, L: -55.12002969, varpi: 44.96476227, Omega: 131.78422574,
            aDot: 0.00026291, eDot: 0.00005105, iDot: 0.00035372, LDot: 218.45945325, varpiDot: -0.32241464, OmegaDot: -0.00508664
        ), radiusKm: 24_622, H: -6.87, albedo: 0.442, color: BodyColor(r: 0.3, g: 0.4, b: 0.9)),
        // Moon: mean orbit about Earth (a in km). ponytail: low-order lunar mean elements; ELP/MPP if arcmin needed.
        BodyInfo(id: .moon, elements: KeplerElements(
            a: 384_400, e: 0.0549, i: 5.145, L: 218.316, varpi: 83.353, Omega: 125.08,
            LDot: 13.176358 * 36525, varpiDot: 0.1114 * 36525, OmegaDot: -0.05295 * 36525, aIsKm: true
        ), radiusKm: 1737.4, H: 0.21, albedo: 0.136, color: BodyColor(r: 0.85, g: 0.85, b: 0.85)),
        // Galilean moons — circular mean a (km), mean motion baked into LDot (°/cy).
        BodyInfo(id: .io, elements: moon(aKm: 421_800, periodDays: 1.769, L0: 40), radiusKm: 1821.6, H: -1.68, albedo: 0.63, color: BodyColor(r: 1, g: 0.9, b: 0.5)),
        BodyInfo(id: .europa, elements: moon(aKm: 671_100, periodDays: 3.551, L0: 120), radiusKm: 1560.8, H: -1.41, albedo: 0.67, color: BodyColor(r: 0.8, g: 0.85, b: 1)),
        BodyInfo(id: .ganymede, elements: moon(aKm: 1_070_400, periodDays: 7.155, L0: 200), radiusKm: 2634.1, H: -2.09, albedo: 0.43, color: BodyColor(r: 0.7, g: 0.7, b: 0.6)),
        BodyInfo(id: .callisto, elements: moon(aKm: 1_882_700, periodDays: 16.69, L0: 280), radiusKm: 2410.3, H: -1.05, albedo: 0.22, color: BodyColor(r: 0.5, g: 0.45, b: 0.4)),
        BodyInfo(id: .titan, elements: moon(aKm: 1_221_870, periodDays: 15.945, L0: 90), radiusKm: 2574.7, H: -1.28, albedo: 0.22, color: BodyColor(r: 0.9, g: 0.7, b: 0.3)),
        BodyInfo(id: .triton, elements: moon(aKm: 354_759, periodDays: 5.877, L0: 180, retrograde: true), radiusKm: 1353.4, H: -1.2, albedo: 0.76, color: BodyColor(r: 0.7, g: 0.8, b: 0.9)),
        BodyInfo(id: .ceres, elements: KeplerElements(
            a: 2.767, e: 0.0785, i: 10.59, L: 95.99, varpi: 73.6, Omega: 80.3,
            LDot: 0.214 * 36525
        ), radiusKm: 473, H: 3.34, albedo: 0.09, color: BodyColor(r: 0.6, g: 0.55, b: 0.5)),
        BodyInfo(id: .pluto, elements: KeplerElements(
            a: 39.482, e: 0.2488, i: 17.16, L: 238.93, varpi: 224.07, Omega: 110.30,
            LDot: 145.18
        ), radiusKm: 1188.3, H: -0.7, albedo: 0.49, color: BodyColor(r: 0.75, g: 0.7, b: 0.65)),
    ]

    public static let byID: [BodyID: BodyInfo] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func info(_ id: BodyID) -> BodyInfo { byID[id]! }

    /// Map bodies drawn by default (planets + sun + dwarf); moons optional.
    public static let primaryMap: [BodyID] = [
        .sun, .mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune, .moon, .ceres, .pluto
    ]

    public static let majorMoons: [BodyID] = [.io, .europa, .ganymede, .callisto, .titan, .triton]

    private static func moon(aKm: Double, periodDays: Double, L0: Double, retrograde: Bool = false) -> KeplerElements {
        let n = 360.0 / periodDays // °/day
        let sign = retrograde ? -1.0 : 1.0
        return KeplerElements(
            a: aKm, e: 0.001, i: retrograde ? 180 : 0.1, L: L0, varpi: L0, Omega: 0,
            LDot: sign * n * 36525, varpiDot: sign * n * 36525, aIsKm: true
        )
    }
}
