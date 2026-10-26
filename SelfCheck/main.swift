#if canImport(SolarCore)
import SolarCore
#endif

@main
enum SelfCheckMain {
    static func main() {
        SelfChecks.run()
    }
}
