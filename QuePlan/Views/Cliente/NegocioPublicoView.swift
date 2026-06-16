import SwiftUI

struct NegocioPublicoView: View {
    let idNegocio: Int
    @State private var negocio: Negocio?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let ng = negocio {
                ScrollView {
                    VStack(spacing: 0) {
                        ZStack(alignment: .bottom) {
                            Theme.pink.frame(height: 150).clipShape(BottomRoundedShape())
                            AvatarView(urlString: ng.logoUrl, size: 100)
                                .padding(.bottom, -50)
                        }
                        .ignoresSafeArea(edges: .top)

                        VStack(spacing: 18) {
                            Text(ng.nombreNegocio ?? "Negocio")
                                .font(.title2.bold())
                                .padding(.top, 60)

                            if let desc = ng.descripcion, !desc.isEmpty {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(Theme.ink.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                            }

                            if let dueno = ng.nombreDueno {
                                infoRow(icon: "person", label: "Dueño", value: dueno)
                            }
                            if let tel = ng.telefono, !tel.isEmpty {
                                infoRow(icon: "phone", label: "Teléfono", value: tel, action: {
                                    guard let url = URL(string: "tel:\(tel)") else { return }
                                    UIApplication.shared.open(url)
                                })
                            }
                            if let dir = ng.direccion, !dir.isEmpty {
                                infoRow(icon: "mappin.and.ellipse", label: "Dirección", value: dir)
                            }

                            Divider()

                            Text("Redes sociales").font(.headline).frame(maxWidth: .infinity, alignment: .leading)

                            socialButton(icon: "camera", label: "Instagram", url: ng.instagram)
                            socialButton(icon: "f.square", label: "Facebook", url: ng.facebook)
                            socialButton(icon: "music.note", label: "TikTok", url: ng.tiktok)
                            socialButton(icon: "globe", label: "Sitio web", url: ng.paginaWeb)
                        }
                        .padding(24)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
            } else {
                EmptyStateView(icon: "storefront", title: "No se pudo cargar el perfil",
                               subtitle: errorMessage ?? "Intenta de nuevo más tarde.")
            }
        }
        .task { await cargar() }
    }

    private func cargar() async {
        do {
            negocio = try await QueplanService.shared.getNegocio(id: idNegocio)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "Error de conexión."
        }
        isLoading = false
    }

    private func infoRow(icon: String, label: String, value: String, action: (() -> Void)? = nil) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.pink).frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.caption).foregroundColor(Theme.gray)
                Text(value).font(.subheadline)
            }
            Spacer()
            if action != nil {
                Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.gray)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { action?() }
    }

    private func socialButton(icon: String, label: String, url: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(Theme.pink).frame(width: 22)
            Group {
                if let url, !url.isEmpty {
                    Button(label) {
                        guard let fullUrl = URL(string: url.hasPrefix("http") ? url : "https://\(url)") else { return }
                        UIApplication.shared.open(fullUrl)
                    }
                    .foregroundColor(Theme.ink)
                } else {
                    Text(label).foregroundColor(Theme.gray.opacity(0.5))
                }
            }
            .font(.subheadline)
            Spacer()
            if let url, !url.isEmpty {
                Image(systemName: "arrow.up.right").font(.caption).foregroundColor(Theme.gray)
            }
        }
        .padding(.vertical, 4)
    }
}
