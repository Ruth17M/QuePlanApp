import SwiftUI

/// Navegación del flujo de autenticación (no autenticado).
struct AuthFlowView: View {
    var body: some View {
        NavigationStack {
            WelcomeView()
        }
    }
}

// MARK: - Bienvenida

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Theme.pink
                    .clipShape(BottomRoundedShape())
                    .ignoresSafeArea(edges: .top)
                VStack(spacing: 16) {
                    QuePlanLogo(color: .white, size: 110)
                    Text("¡QuePlan!")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 60)
            }
            .frame(height: 420)

            VStack(spacing: 14) {
                Text("Bienvenido")
                    .font(.system(size: 26, weight: .bold, design: .serif))
                Text("Vive lo Xico, disfruta a lo grande")
                    .font(.subheadline)
                    .foregroundColor(Theme.gray)

                NavigationLink {
                    LoginView()
                } label: {
                    Text("Iniciar sesión")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 18)

                NavigationLink {
                    AccountTypeView()
                } label: {
                    Text("Registrarse")
                }
                .buttonStyle(OutlineButtonStyle())
            }
            .padding(.horizontal, 32)
            .padding(.top, 10)

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

struct BottomRoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height - 70))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - 70),
            control: CGPoint(x: rect.width / 2, y: rect.height + 40)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Login

struct LoginView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = AuthViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                ZStack(alignment: .bottom) {
                    Theme.pink
                        .frame(height: 200)
                        .clipShape(BottomRoundedShape())
                    VStack(spacing: 8) {
                        QuePlanLogo(color: .white, size: 80)
                        Text("¡QuePlan!")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 36)
                }
                .ignoresSafeArea(edges: .top)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Ingresa con tu cuenta")
                        .font(.headline)

                    QPTextField(placeholder: "Usuario", text: $vm.usuario, keyboard: .emailAddress, icon: "person")
                    QPSecureField(placeholder: "Contraseña", text: $vm.password)

                    Button("¿Olvidaste tu contraseña?") {}
                        .font(.footnote)
                        .foregroundColor(Theme.gray)

                    InlineError(message: vm.errorMessage)

                    Button {
                        Task { await vm.login(preferred: nil, session: session) }
                    } label: {
                        if vm.isLoading { ProgressView().tint(.white) }
                        else { Text("Iniciar sesión") }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(vm.isLoading)
                    .padding(.top, 4)

                    HStack {
                        Text("¿No tienes una cuenta?")
                            .font(.footnote)
                            .foregroundColor(Theme.gray)
                        NavigationLink("Regístrate") { AccountTypeView() }
                            .font(.footnote.bold())
                            .foregroundColor(Theme.pink)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 28)
            }
        }
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }
}
