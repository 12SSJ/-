import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appState.isAuthenticated {
                CalculatorView()
            } else {
                AuthView()
            }
        }
        .onChange(of: scenePhase) { phase in
            appState.handleScenePhase(phase)
        }
    }
}
