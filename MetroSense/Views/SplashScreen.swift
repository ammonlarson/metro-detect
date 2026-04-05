import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var isLandscape: Bool {
        verticalSizeClass == .compact
    }

    var body: some View {
        if isActive {
            ContentView()
        } else {
            Group {
                if isLandscape {
                    HStack(spacing: 24) {
                        Image("SplashIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)

                        VStack(spacing: 8) {
                            Text("MetroSense")
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)

                            Text("Copenhagen Metro Detection")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                } else {
                    VStack(spacing: 20) {
                        Image("SplashIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 480, height: 480)

                        Text("MetroSense")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)

                        Text("Copenhagen Metro Detection")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("SplashBackground"))
            .ignoresSafeArea()
            .task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeOut(duration: 0.3)) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashScreen()
}
