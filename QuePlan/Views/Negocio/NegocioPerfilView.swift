import SwiftUI

/// "Mi perfil" del negocio con acceso a editar, términos, ayuda y cerrar sesión.
struct NegocioPerfilView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var mostrarCerrarSesion = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        Theme.pink.frame(height: 150).clipShape(BottomRoundedShape())
                        Text("Mi perfil").font(.title2.bold()).foregroundColor(.white)
                            .padding(.bottom, 30)
                    }
                    .ignoresSafeArea(edges: .top)

                    AvatarView(urlString: session.negocio?.logoUrl, size: 110)
                        .padding(.top, -55)

                    VStack(alignment: .leading, spacing: 18) {
                        info("Nombre del negocio", session.negocio?.nombreNegocio ?? "")
                        info("Dueño", session.negocio?.nombreDueno ?? "")
                        info("Teléfono", session.negocio?.telefono ?? "")
                        info("Dirección", session.negocio?.direccion ?? "")

                        if let logo = session.negocio?.logoUrl, !logo.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Logo").font(.subheadline.bold())
                                RemoteImage(urlString: logo)
                                    .frame(height: 130).frame(maxWidth: .infinity).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }

                        NavigationLink {
                            if let negocio = session.negocio {
                                EditarNegocioView(negocio: negocio)
                            }
                        } label: {
                            Label("Editar vista previa de negocio", systemImage: "pencil")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(OutlineButtonStyle())

                        VStack(spacing: 12) {
                            NavigationLink { TerminosView() } label: {
                                filaLink("Términos y condiciones", "doc.text")
                            }
                            NavigationLink { AyudaView() } label: {
                                filaLink("Ayuda", "questionmark.circle")
                            }
                        }
                        .padding(.top, 4)

                        Button(role: .destructive) {
                            mostrarCerrarSesion = true
                        } label: {
                            Text("¿Deseas cerrar sesión?")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.danger)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .alert("Cerrar sesión", isPresented: $mostrarCerrarSesion) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) { session.signOut() }
            } message: {
                Text("¿Seguro que deseas salir de tu cuenta?")
            }
        }
    }

    private func info(_ titulo: String, _ valor: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titulo).font(.subheadline.bold())
            Text(valor.isEmpty ? "—" : valor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12).padding(.horizontal, 14)
                .background(Theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private func filaLink(_ texto: String, _ icon: String) -> some View {
        HStack {
            Label(texto, systemImage: icon).foregroundColor(Theme.ink)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(Theme.gray)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Editar perfil del negocio

struct EditarNegocioView: View {
    let negocio: Negocio
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm: NegocioPerfilViewModel
    @Environment(\.dismiss) private var dismiss

    init(negocio: Negocio) {
        self.negocio = negocio
        _vm = StateObject(wrappedValue: NegocioPerfilViewModel(negocio: negocio))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ZStack(alignment: .bottom) {
                    Theme.pink.frame(height: 130).clipShape(BottomRoundedShape())
                    Text("Editar perfil").font(.title2.bold()).foregroundColor(.white)
                        .padding(.bottom, 26)
                }
                .ignoresSafeArea(edges: .top)

                AvatarView(urlString: vm.logoUrl, size: 100)

                VStack(alignment: .leading, spacing: 14) {
                    campo("Nombre del negocio") {
                        Text(negocio.nombreNegocio ?? "")
                            .foregroundColor(Theme.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14).padding(.horizontal, 16)
                            .background(Theme.fieldBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    campo("Teléfono") { QPTextField(placeholder: "Teléfono", text: $vm.telefono, keyboard: .phonePad) }
                    campo("Dirección") { QPTextField(placeholder: "Dirección", text: $vm.direccion) }
                    campo("Descripción") {
                        TextEditor(text: $vm.descripcion)
                            .frame(height: 80).scrollContentBackground(.hidden)
                            .padding(8).background(Theme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    campo("Logo (URL)") { QPTextField(placeholder: "URL del logo", text: $vm.logoUrl) }
                    campo("Instagram") { QPTextField(placeholder: "Instagram", text: $vm.instagram) }
                    campo("Facebook") { QPTextField(placeholder: "Facebook", text: $vm.facebook) }
                    campo("TikTok") { QPTextField(placeholder: "TikTok", text: $vm.tiktok) }
                    campo("Página web") { QPTextField(placeholder: "Página web", text: $vm.paginaWeb) }

                    InlineError(message: vm.errorMessage)

                    Button {
                        Task {
                            if await vm.guardar(idNegocio: negocio.idNegocio, session: session) {
                                dismiss()
                            }
                        }
                    } label: {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Text("Guardar cambios") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isLoading)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func campo<Content: View>(_ titulo: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.subheadline.bold())
            content()
        }
    }
}
