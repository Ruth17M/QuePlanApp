import SwiftUI

@main
struct QuePlanApp: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .tint(Theme.pink)
        }
    }
}


struct RootView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        Group {
            switch session.accountType {
            case .cliente:
                ClienteTabView()
            case .negocio:
                NegocioTabView()
            case .none:
                AuthFlowView()
            }
        }
        .animation(.easeInOut, value: session.accountType)
    }
}
