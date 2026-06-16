import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var usuario = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    /// Inicia sesión probando primero como cliente y luego como negocio,
    /// salvo que ya se conozca el tipo de cuenta.
    func login(preferred: AccountType?, session: SessionManager) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch preferred {
        case .cliente:
            await loginCliente(session: session)
        case .negocio:
            await loginNegocio(session: session)
        case .none:
            // Intento dual: primero cliente, si falla, negocio.
            if await tryLoginCliente(session: session) { return }
            if await tryLoginNegocio(session: session) { return }
            errorMessage = "Usuario o contraseña incorrectos."
        }
    }

    private func loginCliente(session: SessionManager) async {
        if !(await tryLoginCliente(session: session)) {
            errorMessage = errorMessage ?? "Usuario o contraseña incorrectos."
        }
    }

    private func loginNegocio(session: SessionManager) async {
        if !(await tryLoginNegocio(session: session)) {
            errorMessage = errorMessage ?? "Usuario o contraseña incorrectos."
        }
    }

    private func tryLoginCliente(session: SessionManager) async -> Bool {
        do {
            let cliente = try await service.loginCliente(usuario: usuario, password: password)
            session.signIn(cliente: cliente)
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
            return false
        }
    }

    private func tryLoginNegocio(session: SessionManager) async -> Bool {
        do {
            let negocio = try await service.loginNegocio(usuario: usuario, password: password)
            session.signIn(negocio: negocio)
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
            return false
        }
    }

    private func validate() -> Bool {
        if usuario.trimmingCharacters(in: .whitespaces).isEmpty || password.isEmpty {
            errorMessage = "Ingresa tu usuario y contraseña."
            return false
        }
        if password.count < 5 {
            errorMessage = "La contraseña debe tener al menos 5 caracteres."
            return false
        }
        return true
    }
}

@MainActor
final class ClienteRegistroViewModel: ObservableObject {
    @Published var usuario = ""
    @Published var nombre = ""
    @Published var telefono = ""
    @Published var password = ""
    @Published var imagenUrl = ""
    @Published var aceptaTerminos = false

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    func registrar(session: SessionManager) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let data = ClienteRegistroRequest(
            usuario: usuario.isEmpty ? nombre.lowercased().replacingOccurrences(of: " ", with: "_") : usuario,
            nombre: nombre,
            telefono: telefono,
            passwordHash: password,
            imagenUrl: imagenUrl.isEmpty ? "https://placehold.co/200x200?text=\(nombre.prefix(1))" : imagenUrl
        )
        do {
            let cliente = try await service.registrarCliente(data)
            session.signIn(cliente: cliente)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo crear la cuenta."
        }
    }

    private func validate() -> Bool {
        if nombre.isEmpty || telefono.isEmpty || password.isEmpty {
            errorMessage = "Completa nombre, teléfono y contraseña."
            return false
        }
        if password.count < 5 {
            errorMessage = "La contraseña debe tener al menos 5 caracteres."
            return false
        }
        let digitos = CharacterSet.decimalDigits
        if telefono.count != 10 || telefono.rangeOfCharacter(from: digitos.inverted) != nil {
            errorMessage = "Ingresa un teléfono válido de 10 dígitos."
            return false
        }
        if !aceptaTerminos {
            errorMessage = "Debes aceptar los términos y condiciones."
            return false
        }
        return true
    }
}

@MainActor
final class NegocioRegistroViewModel: ObservableObject {
    @Published var usuario = ""
    @Published var nombreNegocio = ""
    @Published var nombreDueno = ""
    @Published var descripcion = ""
    @Published var logoUrl = ""
    @Published var direccion = ""
    @Published var telefono = ""
    @Published var password = ""
    @Published var tiktok = ""
    @Published var instagram = ""
    @Published var facebook = ""
    @Published var paginaWeb = ""
    @Published var aceptaTerminos = false

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    func registrar(session: SessionManager) async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let data = NegocioRegistroRequest(
            usuario: usuario.isEmpty ? nombreNegocio.lowercased().replacingOccurrences(of: " ", with: "_") : usuario,
            nombreNegocio: nombreNegocio,
            nombreDueno: nombreDueno,
            direccion: direccion,
            telefono: telefono,
            descripcion: descripcion,
            logoUrl: logoUrl.isEmpty ? "https://placehold.co/400x400?text=Logo" : logoUrl,
            passwordHash: password,
            instagram: instagram,
            facebook: facebook,
            tiktok: tiktok,
            paginaWeb: paginaWeb
        )
        do {
            let negocio = try await service.registrarNegocio(data)
            session.signIn(negocio: negocio)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo crear la cuenta."
        }
    }

    private func validate() -> Bool {
        if nombreNegocio.isEmpty || nombreDueno.isEmpty || password.isEmpty {
            errorMessage = "Completa nombre del negocio, dueño y contraseña."
            return false
        }
        if password.count < 5 {
            errorMessage = "La contraseña debe tener al menos 5 caracteres."
            return false
        }
        if !telefono.isEmpty {
            let digitos = CharacterSet.decimalDigits
            if telefono.count != 10 || telefono.rangeOfCharacter(from: digitos.inverted) != nil {
                errorMessage = "Ingresa un teléfono válido de 10 dígitos."
                return false
            }
        }
        if nombreDueno.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Ingresa el nombre del dueño."
            return false
        }
        if !aceptaTerminos {
            errorMessage = "Debes aceptar los términos y condiciones."
            return false
        }
        return true
    }
}
