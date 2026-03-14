import SwiftUI

struct SplashScreen: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            ContentView()
        } else {
            VStack(spacing: 20) {
                Image("AppIconImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))

                Text("MetroDetect")
                    .font(.largeTitle.bold())

                Text("Copenhagen Metro Detection")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isActive = true
                    }
                }
            }
        }
    }
}
