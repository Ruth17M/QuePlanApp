import SwiftUI

struct ClientePerfilView: View {
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        AvatarView(urlString: session.cliente?.imagenUrl, size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.cliente?.nombre ?? "Turista").font(.headline)
                            Text("@\(session.cliente?.usuario ?? "")").font(.subheadline).foregroundColor(Theme.gray)
                            Text(session.cliente?.telefono ?? "").font(.caption).foregroundColor(Theme.gray)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    NavigationLink {
                        if let cliente = session.cliente {
                            EditarClienteView(cliente: cliente)
                        }
                    } label: {
                        Label("Editar perfil", systemImage: "pencil")
                    }
                    NavigationLink { TerminosView() } label: {
                        Label("Términos y condiciones", systemImage: "doc.text")
                    }
                    NavigationLink { AyudaView() } label: {
                        Label("Ayuda", systemImage: "questionmark.circle")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        session.signOut()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
        }
    }
}

struct EditarClienteView: View {
    let cliente: Cliente
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm: ClientePerfilViewModel
    @Environment(\.dismiss) private var dismiss

    init(cliente: Cliente) {
        self.cliente = cliente
        _vm = StateObject(wrappedValue: ClientePerfilViewModel(cliente: cliente))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottom) {
                    Theme.pink.frame(height: 140).clipShape(BottomRoundedShape())
                    VStack {
                        Text("Editar perfil").font(.title2.bold()).foregroundColor(.white)
                    }.padding(.bottom, 28)
                }
                .ignoresSafeArea(edges: .top)

                AvatarView(urlString: vm.imagenUrl, size: 110)

                VStack(alignment: .leading, spacing: 14) {
                    grupo("Nombre completo") {
                        Text(cliente.nombre ?? "")
                            .foregroundColor(Theme.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 14).padding(.horizontal, 16)
                            .background(Theme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    grupo("Teléfono") {
                        QPTextField(placeholder: "Teléfono", text: $vm.telefono, keyboard: .phonePad)
                    }
                    grupo("Foto de perfil") {
                        FotoPicker(carpeta: "perfiles", maximo: 1) { url in
                            vm.imagenUrl = url
                        } label: {
                            HStack {
                                Text(vm.imagenUrl.isEmpty ? "Seleccionar foto" : "Foto seleccionada ✓")
                                    .foregroundColor(vm.imagenUrl.isEmpty ? Theme.gray : Theme.pink)
                                Spacer()
                                Image(systemName: "photo").foregroundColor(Theme.gray)
                            }
                            .padding(.vertical, 14).padding(.horizontal, 16)
                            .background(Theme.fieldBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    NavigationLink("Términos y condiciones") { TerminosView() }
                        .font(.footnote).foregroundColor(Theme.pink)
                        .frame(maxWidth: .infinity, alignment: .center)

                    InlineError(message: vm.errorMessage)

                    Button {
                        Task {
                            if await vm.guardar(idCliente: cliente.idCliente, session: session) {
                                dismiss()
                            }
                        }
                    } label: {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Text("Guardar cambios") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isLoading)

                    Button("Cancelar") { dismiss() }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(Theme.gray)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func grupo<Content: View>(_ titulo: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.subheadline.bold())
            content()
        }
    }
}
