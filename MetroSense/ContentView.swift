import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MetroViewModel()

    var body: some View {
        MapContentView(viewModel: viewModel) { newSettings in
            if newSettings.isValid {
                newSettings.save()
                viewModel.settings = newSettings
            }
        }
        .onAppear {
            viewModel.start()
        }
    }
}

#Preview {
    ContentView()
}
