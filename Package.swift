// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SolarSystemTracker",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SolarSystemTracker", targets: ["SolarSystemTracker"]),
        .executable(name: "SelfCheck", targets: ["SelfCheck"]),
    ],
    targets: [
        .target(
            name: "SolarCore",
            path: ".",
            exclude: [
                "LICENSE", "Info.plist", "project.yml", "SolarSystemTracker.entitlements",
                "SolarSystemTracker", "UI", "Observe/ObserverLocation.swift", "SelfCheck",
                "SolarSystemTracker.xcodeproj", ".git", ".agents", ".cursor", ".build",
            ],
            sources: [
                "Ephemeris/Kepler.swift",
                "Ephemeris/BodyCatalog.swift",
                "Ephemeris/EphemerisEngine.swift",
                "Observe/ObservabilityEngine.swift",
                "Ephemeris/SelfChecks.swift",
            ]
        ),
        .executableTarget(
            name: "SelfCheck",
            dependencies: ["SolarCore"],
            path: "SelfCheck"
        ),
        .executableTarget(
            name: "SolarSystemTracker",
            dependencies: ["SolarCore"],
            path: ".",
            exclude: [
                "LICENSE", "Info.plist", "project.yml", "SolarSystemTracker.entitlements",
                "Ephemeris", "SelfCheck", "Observe/ObservabilityEngine.swift",
                "SolarSystemTracker.xcodeproj", ".git", ".agents", ".cursor", ".build",
            ],
            sources: [
                "SolarSystemTracker/SolarSystemTrackerApp.swift",
                "SolarSystemTracker/ContentView.swift",
                "SolarSystemTracker/SimulationClock.swift",
                "SolarSystemTracker/LocationSettingsView.swift",
                "Observe/ObserverLocation.swift",
                "UI/OrbitCanvas.swift",
                "UI/TransportBar.swift",
                "UI/BodyDetailPanel.swift",
            ]
        ),
    ]
)
