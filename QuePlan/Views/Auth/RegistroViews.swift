import SwiftUI

// Selección de tipo de cuenta

struct AccountTypeView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            QuePlanLogo(color: Theme.pink, size: 100)
            VStack(spacing: 8) {
                Text("Bienvenido")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                Text("¿Qué tipo de cuenta deseas registrar?")
                    .font(.subheadline)
                    .foregroundColor(Theme.gray)
                    .multilineTextAlignment(.center)
            }
            Spacer()

            HStack(spacing: 60) {
                NavigationLink {
                    NegocioRegistroView()
                } label: {
                    tipoCard(icon: "storefront", titulo: "Negocio")
                }
                NavigationLink {
                    ClienteRegistroView()
                } label: {
                    tipoCard(icon: "person", titulo: "Turista")
                }
            }
            .padding(.bottom, 60)
            .padding(.horizontal, 24)
            .padding(.top, 40)
            .frame(maxWidth: .infinity)
            .background(
                Theme.pink.clipShape(TopRoundedShape()).ignoresSafeArea(edges: .bottom)
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tipoCard(icon: String, titulo: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
            Text(titulo)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

struct TopRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: 60))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: 60),
            control: CGPoint(x: rect.width / 2, y: -40)
        )
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}

// Registro de cliente

struct ClienteRegistroView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ClienteRegistroViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Crea una cuenta")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .padding(.top, 8)

                QPTextField(placeholder: "Nombre", text: $vm.nombre, icon: "person")
                QPTextField(placeholder: "Usuario", text: $vm.usuario, icon: "at")
                QPTextField(placeholder: "Teléfono", text: $vm.telefono, keyboard: .phonePad, icon: "phone")
                FotoPicker(carpeta: "perfiles", maximo: 1) { url in
                    vm.imagenUrl = url
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo").foregroundColor(Theme.gray).frame(width: 20)
                        Group {
                            if vm.imagenUrl.isEmpty {
                                Text("Foto de perfil").foregroundColor(Theme.gray)
                            } else {
                                Text("Foto seleccionada ✓").foregroundColor(Theme.pink)
                            }
                        }
                        .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 14).padding(.horizontal, 16)
                    .background(Theme.fieldBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                QPSecureField(placeholder: "Contraseña", text: $vm.password)

                Toggle(isOn: $vm.aceptaTerminos) {
                    HStack(spacing: 4) {
                        Text("Acepto los")
                            .font(.footnote).foregroundColor(Theme.gray)
                        NavigationLink("Términos y condiciones") { TerminosView() }
                            .font(.footnote.bold()).foregroundColor(Theme.pink)
                    }
                }
                .tint(Theme.pink)

                InlineError(message: vm.errorMessage)

                Button {
                    Task { await vm.registrar(session: session) }
                } label: {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text("Registrarme") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isLoading)
            }
            .padding(24)
        }
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Registro de negocio

struct NegocioRegistroView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = NegocioRegistroViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Crea una cuenta")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                    .padding(.top, 8)

                QPTextField(placeholder: "Nombre del negocio", text: $vm.nombreNegocio, icon: "storefront")
                QPTextField(placeholder: "Nombre del dueño", text: $vm.nombreDueno, icon: "person")
                QPTextField(placeholder: "Usuario", text: $vm.usuario, icon: "at")

                descripcionField
                FotoPicker(carpeta: "logos", maximo: 1) { url in
                    vm.logoUrl = url
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "photo").foregroundColor(Theme.gray).frame(width: 20)
                        Group {
                            if vm.logoUrl.isEmpty {
                                Text("Logo del negocio").foregroundColor(Theme.gray)
                            } else {
                                Text("Logo seleccionado ✓").foregroundColor(Theme.pink)
                            }
                        }
                        .font(.subheadline)
                        Spacer()
                    }
                    .padding(.vertical, 14).padding(.horizontal, 16)
                    .background(Theme.fieldBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                QPTextField(placeholder: "Ubicación", text: $vm.direccion, icon: "mappin.and.ellipse")
                QPTextField(placeholder: "Teléfono", text: $vm.telefono, keyboard: .phonePad, icon: "phone")
                QPSecureField(placeholder: "Contraseña", text: $vm.password)
                QPTextField(placeholder: "TikTok", text: $vm.tiktok, icon: "music.note")
                QPTextField(placeholder: "Instagram", text: $vm.instagram, icon: "camera")
                QPTextField(placeholder: "Facebook", text: $vm.facebook, icon: "f.square")
                QPTextField(placeholder: "Página web", text: $vm.paginaWeb, icon: "globe")

                Toggle(isOn: $vm.aceptaTerminos) {
                    HStack(spacing: 4) {
                        Text("Acepto los")
                            .font(.footnote).foregroundColor(Theme.gray)
                        NavigationLink("Términos y condiciones") { TerminosView() }
                            .font(.footnote.bold()).foregroundColor(Theme.pink)
                    }
                }
                .tint(Theme.pink)

                InlineError(message: vm.errorMessage)

                Button {
                    Task { await vm.registrar(session: session) }
                } label: {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text("Registrarme") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isLoading)
            }
            .padding(24)
        }
        .navigationTitle("Registro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var descripcionField: some View {
        ZStack(alignment: .topLeading) {
            if vm.descripcion.isEmpty {
                Text("Descripción del negocio")
                    .foregroundColor(Theme.gray)
                    .padding(.vertical, 16).padding(.horizontal, 16)
            }
            TextEditor(text: $vm.descripcion)
                .frame(height: 90)
                .scrollContentBackground(.hidden)
                .padding(.vertical, 8).padding(.horizontal, 12)
        }
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
