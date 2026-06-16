import Foundation

// helpers

/// Algunos campos numéricos viajan como Int (0/1) y representan booleanos.
/// Esta utilidad facilita su lectura.
extension Int {
    var asBool: Bool { self != 0 }
}

extension Bool {
    var asInt: Int { self ? 1 : 0 }
}

/// Respuesta genérica de error. La API responde 200 incluso en errores y
/// coloca el detalle en el campo `response`.
struct APIMessage: Decodable {
    let response: String?
}

//negocio

struct Negocio: Codable, Identifiable, Hashable {
    var idNegocio: Int
    var usuario: String?
    var nombreNegocio: String?
    var nombreDueno: String?
    var direccion: String?
    var telefono: String?
    var descripcion: String?
    var logoUrl: String?
    var instagram: String?
    var facebook: String?
    var tiktok: String?
    var paginaWeb: String?

    var id: Int { idNegocio }
}

struct NegocioLoginRequest: Encodable {
    let usuario: String
    let passwordHash: String
}

struct NegocioRegistroRequest: Encodable {
    var usuario: String
    var nombreNegocio: String
    var nombreDueno: String
    var direccion: String
    var telefono: String
    var descripcion: String
    var logoUrl: String
    var passwordHash: String
    var instagram: String
    var facebook: String
    var tiktok: String
    var paginaWeb: String
}

struct NegocioActualizarRequest: Encodable {
    var idNegocio: Int
    var descripcion: String
    var logoUrl: String
    var telefono: String
    var direccion: String
    var instagram: String
    var facebook: String
    var tiktok: String
    var paginaWeb: String
}

// cliente

struct Cliente: Codable, Identifiable, Hashable {
    var idCliente: Int
    var usuario: String?
    var nombre: String?
    var telefono: String?
    var imagenUrl: String?

    var id: Int { idCliente }
}

struct ClienteLoginRequest: Encodable {
    let usuario: String
    let passwordHash: String
}

struct ClienteRegistroRequest: Encodable {
    var usuario: String
    var nombre: String
    var telefono: String
    var passwordHash: String
    var imagenUrl: String
}

struct ClienteActualizarRequest: Encodable {
    var idCliente: Int
    var telefono: String
    var imagenUrl: String
}

// evento

struct Evento: Codable, Identifiable, Hashable {
    var idEvento: Int
    var idNegocio: Int?
    var nombre: String?
    var fechaHora: String?
    var ubicacion: String?
    var precio: Double?
    var descripcion: String?
    var categoria: String?
    var cupo: Int?
    var tieneEstacionamiento: Int?
    var requiereAnticipo: Int?
    var montoAnticipo: Double?
    var autoconfirmacion: Int?
    var estado: String?
    var imagenes: [String]?

    // Campos embebidos que devuelve la API en algunos endpoints.
    var nombreNegocio: String?
    var logoUrl: String?
    var promedioCalificacion: Double?
    var totalOpiniones: Int?

    var id: Int { idEvento }

    var fecha: Date? { DateFormatters.parse(fechaHora) }

    /// Representación de "$$$" según el precio, como en el diseño.
    var nivelPrecio: String {
        guard let precio else { return "$" }
        switch precio {
        case ..<200: return "$"
        case ..<500: return "$$"
        default: return "$$$"
        }
    }
}

struct EventoSaveRequest: Encodable {
    var idEvento: Int? = nil
    var idNegocio: Int
    var nombre: String
    var fechaHora: String
    var ubicacion: String
    var precio: Double
    var descripcion: String
    var categoria: String
    var cupo: Int
    var tieneEstacionamiento: Int
    var requiereAnticipo: Int
    var montoAnticipo: Double
    var autoconfirmacion: Int
    var imagenes: [String]
}

struct ReservaAfectada: Decodable, Identifiable, Hashable {
    var idReservacion: Int
    var idCliente: Int?
    var idEvento: Int?
    var cantidadPersonas: Int?
    var estado: String?
    var nombreCliente: String?
    var telefonoCliente: String?
    var nombreEvento: String?
    var fechaHora: String?

    var id: Int { idReservacion }
}

struct CancelEventoResponse: Decodable {
    var response: String?
    var afectados: [ReservaAfectada]?
}

// Reserva

struct Reserva: Codable, Identifiable, Hashable {
    var idReservacion: Int
    var idCliente: Int?
    var idEvento: Int?
    var cantidadPersonas: Int?
    var estado: String?

    // Info embebida del cliente (vista negocio).
    var nombreCliente: String?
    var telefonoCliente: String?
    var imagenUrl: String?

    // Info embebida del evento (vista cliente).
    var nombreEvento: String?
    var nombreNegocio: String?
    var logoUrl: String?
    var ubicacion: String?
    var fechaHora: String?

    var id: Int { idReservacion }

    var fecha: Date? { DateFormatters.parse(fechaHora) }

    var estadoEnum: EstadoReserva { EstadoReserva(rawValue: estado?.lowercased() ?? "") ?? .pendiente }

    var estadoDisplay: EstadoReserva {
        guard let f = fecha, f < Date() else { return estadoEnum }
        if estadoEnum == .cancelada { return .cancelada }
        return .completada
    }
}

enum EstadoReserva: String {
    case pendiente
    case confirmada
    case cancelada
    case completada

    var titulo: String {
        switch self {
        case .pendiente: return "Pendiente"
        case .confirmada: return "Confirmada"
        case .cancelada: return "Cancelada"
        case .completada: return "Completada"
        }
    }
}

struct ReservaRequest: Encodable {
    let idCliente: Int
    let idEvento: Int
    let cantidadPersonas: Int
}

// Opinión

struct Opinion: Codable, Identifiable, Hashable {
    var idOpinion: Int?
    var idCliente: Int?
    var idEvento: Int?
    var calificacion: Int?
    var comentario: String?
    var nombreCliente: String?
    var imagenUrl: String?
    var nombreEvento: String?

    var id: String {
        if let idOpinion { return "op-\(idOpinion)" }
        return "\(idCliente ?? 0)-\(idEvento ?? 0)-\(comentario ?? "")"
    }
}

struct OpinionRequest: Encodable {
    let idCliente: Int
    let idEvento: Int
    let calificacion: Int
    let comentario: String
}

// Imagen de evento

struct UploadResponse: Codable {
    var url: String?
    var response: String?
    var error: String?
}

struct EventoImagen: Codable, Identifiable, Hashable {
    var idImagen: Int?
    var idEvento: Int?
    var url: String?

    var id: Int { idImagen ?? url.hashValue }
}

struct EventoImagenRequest: Encodable {
    let idEvento: Int
    let url: String
}

// Formato de fechas

enum DateFormatters {
    /// Formato que usa la API: "YYYY-MM-DD HH:MM:SS"
    static let api: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Mexico_City")
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    static let display: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "dd/MM/yyyy"
        return f
    }()

    static let hora: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "HH:mm"
        return f
    }()

    static func parse(_ string: String?) -> Date? {
        guard var s = string, !s.isEmpty else { return nil }
        if let dot = s.firstIndex(of: ".") { s = String(s[..<dot]) }
        return api.date(from: s)
    }

    static func apiString(from date: Date) -> String {
        api.string(from: date)
    }
}
