import Foundation

enum APIError: LocalizedError {
    case server(String)
    case decoding
    case network

    var errorDescription: String? {
        switch self {
        case .server(let message): return message
        case .decoding: return "No se pudo leer la respuesta del servidor."
        case .network: return "Sin conexión con el servidor."
        }
    }
}

/// Capa de acceso a la API de QuePlan.
final class QueplanService {

    static let shared = QueplanService()

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()


    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            throw APIError.network
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.network
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            if let message = try? decoder.decode(APIMessage.self, from: data),
               let text = message.response {
                throw APIError.server(text)
            }
            throw APIError.decoding
        }
    }

    @discardableResult
    private func requestMessage(
        _ path: String,
        method: String,
        body: Encodable? = nil
    ) async throws -> String? {
        guard let url = URL(string: "\(APIConfig.baseURL)\(path)") else {
            throw APIError.network
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        let data: Data
        do {
            (data, _) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.network
        }
        return (try? decoder.decode(APIMessage.self, from: data))?.response
    }

    //Health

    func health() async throws -> String? {
        try await requestMessage("/health", method: "GET")
    }

    //Negocio

    func loginNegocio(usuario: String, password: String) async throws -> Negocio {
        let body = NegocioLoginRequest(usuario: usuario, passwordHash: password)
        return try await request("/negocio/login", method: "POST", body: body)
    }

    func registrarNegocio(_ data: NegocioRegistroRequest) async throws -> Negocio {
        try await request("/negocio/registro", method: "POST", body: data)
    }

    func getNegocio(id: Int) async throws -> Negocio {
        try await request("/negocio/get/\(id)")
    }

    func actualizarNegocio(_ data: NegocioActualizarRequest) async throws -> Negocio {
        try await request("/negocio/actualizar", method: "PUT", body: data)
    }

    // Cliente

    func loginCliente(usuario: String, password: String) async throws -> Cliente {
        let body = ClienteLoginRequest(usuario: usuario, passwordHash: password)
        return try await request("/cliente/login", method: "POST", body: body)
    }

    func registrarCliente(_ data: ClienteRegistroRequest) async throws -> Cliente {
        try await request("/cliente/registro", method: "POST", body: data)
    }

    func getCliente(id: Int) async throws -> Cliente {
        try await request("/cliente/get/\(id)")
    }

    func actualizarCliente(_ data: ClienteActualizarRequest) async throws -> Cliente {
        try await request("/cliente/actualizar", method: "PUT", body: data)
    }

    // Eventos

    func getEventosNegocio(idNegocio: Int) async throws -> [Evento] {
        try await request("/evento/getAll/\(idNegocio)")
    }

    func getEventosDisponibles(
        nombre: String? = nil,
        fechaDesde: String? = nil,
        fechaHasta: String? = nil
    ) async throws -> [Evento] {
        var params: [String] = []
        if let nombre, !nombre.isEmpty {
            let v = nombre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? nombre
            params.append("nombre=\(v)")
        }
        if let fechaDesde { params.append("fechaDesde=\(fechaDesde)") }
        if let fechaHasta { params.append("fechaHasta=\(fechaHasta)") }
        let query = params.isEmpty ? "" : "?" + params.joined(separator: "&")
        return try await request("/evento/getDisponibles\(query)")
    }

    func getEvento(id: Int) async throws -> Evento {
        try await request("/evento/get/\(id)")
    }

    func crearEvento(_ data: EventoSaveRequest) async throws -> Evento {
        try await request("/evento/save", method: "POST", body: data)
    }

    func cancelarEvento(id: Int) async throws -> CancelEventoResponse {
        try await request("/evento/delete/\(id)", method: "DELETE")
    }

    // Reservas

    func getReservasNegocioEvento(idEvento: Int) async throws -> [Reserva] {
        try await request("/reserva/getAllByEvento/\(idEvento)")
    }

    func getReservasCliente(idCliente: Int) async throws -> [Reserva] {
        try await request("/reserva/getAll/\(idCliente)")
    }

    func crearReserva(idCliente: Int, idEvento: Int, cantidadPersonas: Int) async throws -> Reserva {
        let body = ReservaRequest(idCliente: idCliente, idEvento: idEvento, cantidadPersonas: cantidadPersonas)
        return try await request("/reserva/save", method: "POST", body: body)
    }

    func confirmarReserva(id: Int) async throws {
        try await requestMessage("/reserva/confirmar/\(id)", method: "PUT")
    }

    func cancelarReservaNegocio(id: Int) async throws {
        try await requestMessage("/reserva/cancelar/\(id)", method: "PUT")
    }

    func eliminarReservaCliente(id: Int) async throws {
        try await requestMessage("/reserva/delete/\(id)", method: "DELETE")
    }

    // Opiniones

    func getOpiniones(idEvento: Int) async throws -> [Opinion] {
        try await request("/opinion/getByEvento/\(idEvento)")
    }

    func getOpinionesNegocio(idNegocio: Int) async throws -> [Opinion] {
        try await request("/opinion/getByNegocio/\(idNegocio)")
    }

    func crearOpinion(_ data: OpinionRequest) async throws {
        try await requestMessage("/opinion/save", method: "POST", body: data)
    }

    // Imágenes de evento

    func getImagenesEvento(idEvento: Int) async throws -> [EventoImagen] {
        try await request("/eventoImagen/getByEvento/\(idEvento)")
    }

    func agregarImagenEvento(idEvento: Int, url: String) async throws {
        let body = EventoImagenRequest(idEvento: idEvento, url: url)
        try await requestMessage("/eventoImagen/save", method: "POST", body: body)
    }

    func eliminarImagenEvento(idImagen: Int) async throws {
        try await requestMessage("/eventoImagen/delete/\(idImagen)", method: "DELETE")
    }
}
