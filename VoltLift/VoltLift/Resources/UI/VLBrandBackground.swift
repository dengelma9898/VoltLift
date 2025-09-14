import SwiftUI

public struct VLBrandBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.09, blue: 0.16)
            Circle()
                .fill(DesignSystem.Gradient.bluePurple)
                .frame(width: 480, height: 480)
                .blur(radius: 160)
                .opacity(0.25)
                .offset(x: 160, y: -120)
            Circle()
                .fill(DesignSystem.Gradient.tealBlue)
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .opacity(0.20)
                .offset(x: -180, y: 240)
        }
        .ignoresSafeArea()
    }
}

public extension View {
    @ViewBuilder
    func vlBrandBackground() -> some View {
        self.background(VLBrandBackground())
    }
}
