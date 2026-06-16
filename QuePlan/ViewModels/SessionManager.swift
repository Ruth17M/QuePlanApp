import Foundation
import SwiftUI

enum AccountType: String {
    case cliente
    case negocio
}

@MainActor
final class SessionManager: ObservableObject {
    @Published var cliente: Cliente?
    @Published var negocio: Negocio?

    private let defaults = UserDefaults.standard

    init() {
        load()
    }

    var isLoggedIn: Bool { cliente != nil || negocio != nil }

    var accountType: AccountType? {
        if cliente != nil { return .cliente }
        if negocio != nil { return .negocio }
        return nil
    }

    func signIn(cliente: Cliente) {
        self.negocio = nil
        self.cliente = cliente
        save()
    }

    func signIn(negocio: Negocio) {
        self.cliente = nil
        self.negocio = negocio
        save()
    }

    func updateCliente(_ cliente: Cliente) {
        self.cliente = cliente
        save()
    }

    func updateNegocio(_ negocio: Negocio) {
        self.negocio = negocio
        save()
    }

    func signOut() {
        cliente = nil
        negocio = nil
        defaults.removeObject(forKey: "cliente")
        defaults.removeObject(forKey: "negocio")
    }

    private func save() {
        if let cliente {
            if let data = try? JSONEncoder().encode(cliente) {
                defaults.set(data, forKey: "cliente")
            }
            defaults.removeObject(forKey: "negocio")
        } else if let negocio {
            if let data = try? JSONEncoder().encode(negocio) {
                defaults.set(data, forKey: "negocio")
            }
            defaults.removeObject(forKey: "cliente")
        }
    }

    private func load() {
        if let data = defaults.data(forKey: "cliente"),
           let saved = try? JSONDecoder().decode(Cliente.self, from: data) {
            cliente = saved
        } else if let data = defaults.data(forKey: "negocio"),
                  let saved = try? JSONDecoder().decode(Negocio.self, from: data) {
            negocio = saved
        }
    }
}
