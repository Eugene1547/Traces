//
//  ConfettiBurstView.swift
//  Traces
//

import SwiftUI

/// One confetti burst: an upward fan of small rectangles that spin, fall under gravity, and
/// fade out, all drawn in a single Canvas per frame (cheap even at dozens of particles).
/// Seeded randomness makes every burst land differently, so the celebration stays fresh on
/// the hundredth completion, while a given burst stays deterministic across redraws.
struct ConfettiBurstView: View {
    let origin: CGPoint
    let seed: UInt64

    static let duration: TimeInterval = 1.1

    private let particles: [Particle]
    private let startDate = Date()

    init(origin: CGPoint, seed: UInt64) {
        self.origin = origin
        self.seed = seed
        var rng = SplitMix64(state: seed)
        self.particles = (0..<26).map { _ in Particle(using: &rng) }
    }

    var body: some View {
        TimelineView(.animation) { context in
            Canvas { graphics, _ in
                let elapsed = context.date.timeIntervalSince(startDate)
                for particle in particles {
                    guard elapsed < particle.lifetime else { continue }
                    let t = elapsed
                    let position = CGPoint(
                        x: origin.x + particle.velocity.dx * t,
                        y: origin.y + particle.velocity.dy * t + 0.5 * Particle.gravity * t * t
                    )
                    let fadeStart = particle.lifetime * 0.55
                    let opacity = t < fadeStart ? 1 : 1 - (t - fadeStart) / (particle.lifetime - fadeStart)

                    var ctx = graphics
                    ctx.translateBy(x: position.x, y: position.y)
                    ctx.rotate(by: .degrees(particle.spin * t))
                    ctx.opacity = opacity
                    ctx.fill(
                        Path(CGRect(x: -particle.size.width / 2, y: -particle.size.height / 2,
                                    width: particle.size.width, height: particle.size.height)),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private struct Particle {
        static let gravity: CGFloat = 520

        let velocity: CGVector
        let size: CGSize
        let color: Color
        let spin: Double
        let lifetime: TimeInterval

        private static let palette: [Color] = [
            .dragAccent, .red, .orange, .yellow, .green, .pink,
        ]

        init(using rng: inout SplitMix64) {
            // Up-right fan (-45° ± 30°): the checkbox sits at the panel's left edge, so aiming
            // across the panel's width keeps the burst on stage instead of clipping at the
            // window bounds, which cut off anything aimed straight up.
            let angle = Angle.degrees(-45 + Double.random(in: -30...30, using: &rng)).radians
            let speed = Double.random(in: 120...240, using: &rng)
            velocity = CGVector(dx: Foundation.cos(angle) * speed, dy: Foundation.sin(angle) * speed)
            size = CGSize(width: .random(in: 4...6, using: &rng), height: .random(in: 2.5...3.5, using: &rng))
            color = Self.palette.randomElement(using: &rng) ?? .dragAccent
            spin = Double.random(in: -540...540, using: &rng)
            lifetime = TimeInterval.random(in: 0.7...ConfettiBurstView.duration, using: &rng)
        }
    }
}

/// Small deterministic RNG (SplitMix64) so a burst's particles are stable across Canvas redraws.
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
