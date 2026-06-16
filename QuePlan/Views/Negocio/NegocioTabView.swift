import SwiftUI

/// Barra inferior del negocio: Inicio (calendario), Historial, Perfil.
struct NegocioTabView: View {
    var body: some View {
        TabView {
            NegocioCalendarioView()
                .tabItem { Label("Inicio", systemImage: "house") }

            NegocioHistorialView()
                .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }

            NegocioPerfilView()
                .tabItem { Label("Perfil", systemImage: "person") }
        }
        .tint(Theme.pink)
    }
}
