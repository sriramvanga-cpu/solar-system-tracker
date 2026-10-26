import SwiftUI
import AppKit
#if canImport(SolarCore)
import SolarCore
#endif

struct OrbitCanvas: View {
    let date: Date
    @Binding var selected: BodyID?
    var showMoons: Bool

    @State private var scale: CGFloat = 40
    @State private var pan: CGSize = .zero
    @GestureState private var drag: CGSize = .zero

    private var bodies: [BodyID] {
        showMoons ? BodyCatalog.primaryMap + BodyCatalog.majorMoons : BodyCatalog.primaryMap
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(
                x: geo.size.width / 2 + pan.width + drag.width,
                y: geo.size.height / 2 + pan.height + drag.height
            )
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.03, blue: 0.08),
                        Color(red: 0.05, green: 0.06, blue: 0.12),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                Canvas { ctx, _ in
                    drawOrbits(ctx: ctx, center: center)
                    drawBodies(ctx: ctx, center: center)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($drag) { v, state, _ in
                        if hypot(v.translation.width, v.translation.height) >= 4 {
                            state = v.translation
                        }
                    }
                    .onEnded { v in
                        if hypot(v.translation.width, v.translation.height) < 4 {
                            selected = hitTest(at: v.location, center: CGPoint(
                                x: geo.size.width / 2 + pan.width,
                                y: geo.size.height / 2 + pan.height
                            ))
                        } else {
                            pan.width += v.translation.width
                            pan.height += v.translation.height
                        }
                    }
            )
            .background(ScrollWheelCatcher { delta in
                scale = max(2, min(800, scale * (delta > 0 ? 1.1 : 1 / 1.1)))
            })
        }
        .clipped()
    }

    private func mapPoint(_ v: Vec3, center: CGPoint) -> CGPoint {
        CGPoint(x: center.x + CGFloat(v.x) * scale, y: center.y - CGFloat(v.y) * scale)
    }

    private func drawOrbits(ctx: GraphicsContext, center: CGPoint) {
        let T = Astro.centuriesSinceJ2000(Astro.julianDay(date))
        for id in bodies where id != .sun {
            guard let el = BodyCatalog.info(id).elements else { continue }
            let (a0, e, _, _, _, _) = el.at(T)
            let a = el.aIsKm ? a0 / Astro.auKm : a0
            if let parent = id.parent {
                let p = mapPoint(EphemerisEngine.heliocentric(parent, date: date), center: center)
                let r = CGFloat(a) * scale
                let path = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
                ctx.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
            } else {
                let b = a * sqrt(max(0, 1 - e * e))
                let path = Path(ellipseIn: CGRect(
                    x: center.x - CGFloat(a) * scale,
                    y: center.y - CGFloat(b) * scale,
                    width: CGFloat(a) * 2 * scale,
                    height: CGFloat(b) * 2 * scale
                ))
                ctx.stroke(path, with: .color(.white.opacity(0.15)), lineWidth: 0.6)
            }
        }
    }

    private func drawBodies(ctx: GraphicsContext, center: CGPoint) {
        for id in bodies {
            let p = mapPoint(EphemerisEngine.heliocentric(id, date: date), center: center)
            let info = BodyCatalog.info(id)
            let r: CGFloat = {
                switch id {
                case .sun: return 8
                case .jupiter, .saturn: return 6
                default: return id.isMoon ? 3 : 4
                }
            }()
            let rect = CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)
            ctx.fill(Path(ellipseIn: rect), with: .color(Color(red: info.color.r, green: info.color.g, blue: info.color.b)))
            if selected == id {
                ctx.stroke(Path(ellipseIn: rect.insetBy(dx: -3, dy: -3)), with: .color(.white), lineWidth: 1.5)
            }
            if !id.isMoon || scale > 80 {
                ctx.draw(
                    Text(info.id.displayName).font(.system(size: 9)).foregroundColor(.white.opacity(0.75)),
                    at: CGPoint(x: p.x, y: p.y + r + 8),
                    anchor: .top
                )
            }
        }
    }

    private func hitTest(at point: CGPoint, center: CGPoint) -> BodyID? {
        var best: (BodyID, CGFloat)?
        for id in bodies {
            let p = mapPoint(EphemerisEngine.heliocentric(id, date: date), center: center)
            let d = hypot(p.x - point.x, p.y - point.y)
            let thresh: CGFloat = id == .sun ? 14 : 10
            if d < thresh, best.map({ d < $0.1 }) ?? true {
                best = (id, d)
            }
        }
        return best?.0
    }
}

struct ScrollWheelCatcher: NSViewRepresentable {
    var onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        let v = WheelView()
        v.onScroll = onScroll
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? WheelView)?.onScroll = onScroll
    }

    final class WheelView: NSView {
        var onScroll: ((CGFloat) -> Void)?
        override func scrollWheel(with event: NSEvent) {
            onScroll?(event.scrollingDeltaY)
        }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
}
