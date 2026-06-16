import Foundation

// Home

@MainActor
final class ClienteHomeViewModel: ObservableObject {
    @Published var eventos: [Evento] = []
    @Published var busqueda = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Filtros
    @Published var calificacionMinima: Double = 0
    @Published var tarifaMaxima: Double = 5000
    @Published var fechaDesde: Date?
    @Published var fechaHasta: Date?
    @Published var categoriaSeleccionada: String?

    private let service = QueplanService.shared

    var categoriasDisponibles: [String] {
        Array(Set(eventos.compactMap { $0.categoria })).sorted()
    }

    var eventosFiltrados: [Evento] {
        eventos.filter { evento in
            let cumpleCalificacion = (evento.promedioCalificacion ?? 0) >= calificacionMinima
            let cumpleTarifa = (evento.precio ?? 0) <= tarifaMaxima
            let cumpleCategoria = categoriaSeleccionada == nil || evento.categoria == categoriaSeleccionada
            return cumpleCalificacion && cumpleTarifa && cumpleCategoria
        }
    }

    func cargar() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let desde = fechaDesde.map { isoDay($0) } ?? isoDay(Date())
            eventos = try await service.getEventosDisponibles(
                nombre: busqueda.isEmpty ? nil : busqueda,
                fechaDesde: desde,
                fechaHasta: fechaHasta.map { isoDay($0) }
            )
            .filter { evento in
                guard let fecha = evento.fecha else { return false }
                return fecha > Date()
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron cargar los eventos."
        }
    }

    func restablecerFiltros() {
        calificacionMinima = 0
        tarifaMaxima = 5000
        fechaDesde = nil
        fechaHasta = nil
        categoriaSeleccionada = nil
    }

    private func isoDay(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// Detalle del evento (vista cliente)

@MainActor
final class EventoDetalleViewModel: ObservableObject {
    @Published var evento: Evento
    @Published var opiniones: [Opinion] = []
    @Published var imagenes: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    init(evento: Evento) {
        self.evento = evento
        self.imagenes = evento.imagenes ?? []
    }

    func cargar() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let detalle = try await service.getEvento(id: evento.idEvento)
            self.evento = detalle
            self.imagenes = detalle.imagenes ?? imagenes
        } catch {
        }
        if imagenes.isEmpty {
            if let extra = try? await service.getImagenesEvento(idEvento: evento.idEvento) {
                imagenes = extra.compactMap { $0.url }
            }
        }
        if let idNegocio = evento.idNegocio {
            opiniones = (try? await service.getOpinionesNegocio(idNegocio: idNegocio)) ?? []
        }
        if opiniones.isEmpty {
            opiniones = (try? await service.getOpiniones(idEvento: evento.idEvento)) ?? []
        }
    }
}

// Reserva

@MainActor
final class ReservaViewModel: ObservableObject {
    @Published var cantidadPersonas = 1
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reservaCreada: Reserva?

    private let service = QueplanService.shared

    func reservar(idCliente: Int, idEvento: Int) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let reserva = try await service.crearReserva(
                idCliente: idCliente,
                idEvento: idEvento,
                cantidadPersonas: cantidadPersonas
            )
            reservaCreada = reserva
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo crear la reserva."
            return false
        }
    }
}

// Mis actividades / calendario / historial

@MainActor
final class ClienteReservasViewModel: ObservableObject {
    @Published var reservas: [Reserva] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    var proximas: [Reserva] {
        reservas
            .filter { $0.estadoEnum != .cancelada && ($0.fecha ?? .distantPast) >= Calendar.current.startOfDay(for: Date()) }
            .sorted { ($0.fecha ?? .distantFuture) < ($1.fecha ?? .distantFuture) }
    }

    var historial: [Reserva] {
        reservas.sorted { ($0.fecha ?? .distantPast) > ($1.fecha ?? .distantPast) }
    }

    func cargar(idCliente: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            reservas = try await service.getReservasCliente(idCliente: idCliente)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron cargar tus actividades."
        }
    }

    func eliminar(idReservacion: Int, idCliente: Int) async {
        do {
            try await service.eliminarReservaCliente(id: idReservacion)
            await cargar(idCliente: idCliente)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
        }
    }

    func reservasEn(_ day: Date) -> [Reserva] {
        let cal = Calendar.current
        return proximas.filter { reserva in
            guard let f = reserva.fecha else { return false }
            return cal.isDate(f, inSameDayAs: day)
        }
    }
}

// Opinión

@MainActor
final class OpinionViewModel: ObservableObject {
    @Published var calificacion = 0
    @Published var comentario = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    func enviar(idCliente: Int, idEvento: Int) async -> Bool {
        guard calificacion > 0 else {
            errorMessage = "Selecciona una calificación."
            return false
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await service.crearOpinion(
                OpinionRequest(
                    idCliente: idCliente,
                    idEvento: idEvento,
                    calificacion: calificacion,
                    comentario: comentario
                )
            )
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo enviar tu opinión."
            return false
        }
    }
}

// Perfil cliente

@MainActor
final class ClientePerfilViewModel: ObservableObject {
    @Published var telefono: String
    @Published var imagenUrl: String
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    init(cliente: Cliente) {
        self.telefono = cliente.telefono ?? ""
        self.imagenUrl = cliente.imagenUrl ?? ""
    }

    func guardar(idCliente: Int, session: SessionManager) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let actualizado = try await service.actualizarCliente(
                ClienteActualizarRequest(idCliente: idCliente, telefono: telefono, imagenUrl: imagenUrl)
            )
            session.updateCliente(actualizado)
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron guardar los cambios."
            return false
        }
    }
}
