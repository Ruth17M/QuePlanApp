import SwiftUI

/// Barra inferior del cliente: Inicio, Mi experiencia, Historial, Perfil.
struct ClienteTabView: View {
    var body: some View {
        TabView {
            ClienteHomeView()
                .tabItem { Label("Inicio", systemImage: "house") }

            ClienteCalendarioView()
                .tabItem { Label("Mi experiencia", systemImage: "heart.fill") }

            ClienteHistorialView()
                .tabItem { Label("Historial", systemImage: "list.bullet.rectangle") }

            ClientePerfilView()
                .tabItem { Label("Perfil", systemImage: "person") }
        }
        .tint(Theme.pink)
    }
}

// MARK: - Saludo reutilizable de cabecera

struct GreetingHeader: View {
    let nombre: String
    let subtitulo: String
    let imagenUrl: String?

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hola, \(nombre)")
                    .font(.system(size: 26, weight: .bold))
                Text(subtitulo)
                    .font(.footnote)
                    .foregroundColor(Theme.gray)
            }
            Spacer()
            AvatarView(urlString: imagenUrl, size: 46)
        }
    }
}
