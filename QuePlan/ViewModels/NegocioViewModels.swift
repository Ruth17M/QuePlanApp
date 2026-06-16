import Foundation

// Eventos del negocio (calendario / historial)

@MainActor
final class NegocioEventosViewModel: ObservableObject {
    @Published var eventos: [Evento] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    var activos: [Evento] {
        eventos
            .filter { ($0.estado?.lowercased() ?? "activo") != "cancelado" }
            .sorted { ($0.fecha ?? .distantPast) > ($1.fecha ?? .distantPast) }
    }

    func cargar(idNegocio: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let raw = try await service.getEventosNegocio(idNegocio: idNegocio)
            eventos = try await withThrowingTaskGroup(of: Evento.self) { group in
                for ev in raw {
                    guard ev.imagenes == nil || ev.imagenes!.isEmpty else {
                        group.addTask { ev }
                        continue
                    }
                    group.addTask {
                        (try? await self.service.getEvento(id: ev.idEvento)) ?? ev
                    }
                }
                var result: [Evento] = []
                for try await ev in group {
                    result.append(ev)
                }
                return result
            }
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron cargar tus eventos."
        }
    }

    func eventosEn(_ day: Date) -> [Evento] {
        let cal = Calendar.current
        return activos.filter { evento in
            guard let f = evento.fecha else { return false }
            return cal.isDate(f, inSameDayAs: day)
        }
    }
}

// Crear / editar / repetir evento

@MainActor
final class EventoFormViewModel: ObservableObject {
    @Published var nombre = ""
    @Published var descripcion = ""
    @Published var ubicacion = ""
    @Published var categoria = "Cultural"
    @Published var fecha = Date()
    @Published var hora = Date()
    @Published var precio = ""
    @Published var cupo = 1
    @Published var tieneEstacionamiento = false
    @Published var requiereAnticipo = false
    @Published var montoAnticipo = ""
    @Published var autoconfirmacion = false
    @Published var imagenesTexto = ""   // URLs separadas por línea

    @Published var isLoading = false
    @Published var errorMessage: String?


    private var idEvento: Int?

    private let service = QueplanService.shared

    init() {}

    func precargar(desde evento: Evento, repetir: Bool) {
        idEvento = repetir ? nil : evento.idEvento
        nombre = evento.nombre ?? ""
        descripcion = evento.descripcion ?? ""
        ubicacion = evento.ubicacion ?? ""
        categoria = evento.categoria ?? "Cultural"
        if let f = evento.fecha {
            fecha = f
            hora = f
        }
        precio = evento.precio.map { String(format: "%.0f", $0) } ?? ""
        cupo = evento.cupo ?? 1
        tieneEstacionamiento = (evento.tieneEstacionamiento ?? 0).asBool
        requiereAnticipo = (evento.requiereAnticipo ?? 0).asBool
        montoAnticipo = evento.montoAnticipo.map { String(format: "%.0f", $0) } ?? ""
        autoconfirmacion = (evento.autoconfirmacion ?? 0).asBool
        imagenesTexto = (evento.imagenes ?? []).joined(separator: "\n")
    }

    var esEdicion: Bool { idEvento != nil }

    func agregarImagen(_ url: String) {
        if imagenesTexto.isEmpty {
            imagenesTexto = url
        } else {
            imagenesTexto += "\n" + url
        }
    }

    func guardar(idNegocio: Int) async -> Bool {
        guard validate() else { return false }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: hora)
        let fechaFinal = cal.date(
            bySettingHour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            second: 0,
            of: fecha
        ) ?? fecha

        let imagenes = imagenesTexto
            .split(whereSeparator: { $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let oldId = idEvento

        let data = EventoSaveRequest(
            idEvento: idEvento,
            idNegocio: idNegocio,
            nombre: nombre,
            fechaHora: DateFormatters.apiString(from: fechaFinal),
            ubicacion: ubicacion,
            precio: Double(precio) ?? 0,
            descripcion: descripcion,
            categoria: categoria,
            cupo: cupo,
            tieneEstacionamiento: tieneEstacionamiento.asInt,
            requiereAnticipo: requiereAnticipo.asInt,
            montoAnticipo: Double(montoAnticipo) ?? 0,
            autoconfirmacion: autoconfirmacion.asInt,
            imagenes: imagenes
        )
        do {
            _ = try await service.crearEvento(data)
            if let oldId {
                _ = try? await service.cancelarEvento(id: oldId)
            }
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo guardar el evento."
            return false
        }
    }

    private func validate() -> Bool {
        if nombre.isEmpty || ubicacion.isEmpty || cupo <= 0 {
            errorMessage = "Completa nombre, ubicación y cupo."
            return false
        }
        if !precio.isEmpty && Double(precio) == nil {
            errorMessage = "Precio inválido."
            return false
        }
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: hora)
        let fechaFinal = cal.date(
            bySettingHour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            second: 0,
            of: fecha
        ) ?? fecha
        if fechaFinal <= Date() {
            errorMessage = "La fecha y hora del evento debe ser futura."
            return false
        }
        return true
    }
}

// Reservas de un evento ("Personas interesadas")

@MainActor
final class ReservasEventoViewModel: ObservableObject {
    @Published var reservas: [Reserva] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    func cargar(idEvento: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            reservas = try await service.getReservasNegocioEvento(idEvento: idEvento)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron cargar las reservas."
        }
    }

    func confirmar(_ reserva: Reserva, idEvento: Int) async {
        do {
            try await service.confirmarReserva(id: reserva.idReservacion)
            await cargar(idEvento: idEvento)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
        }
    }

    func cancelar(_ reserva: Reserva, idEvento: Int) async {
        do {
            try await service.cancelarReservaNegocio(id: reserva.idReservacion)
            await cargar(idEvento: idEvento)
        } catch {
            errorMessage = (error as? APIError)?.errorDescription
        }
    }
}

// Detalle / administración de un evento del negocio

@MainActor
final class EventoNegocioDetalleViewModel: ObservableObject {
    @Published var evento: Evento
    @Published var reservas: [Reserva] = []
    @Published var afectados: [ReservaAfectada] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cancelado = false

    private let service = QueplanService.shared

    init(evento: Evento) {
        self.evento = evento
    }

    func cargar() async {
        isLoading = true
        defer { isLoading = false }
        if let detalle = try? await service.getEvento(id: evento.idEvento) {
            evento = detalle
        }
        reservas = (try? await service.getReservasNegocioEvento(idEvento: evento.idEvento)) ?? []
    }

    func confirmar(_ reserva: Reserva) async {
        try? await service.confirmarReserva(id: reserva.idReservacion)
        await cargar()
    }

    func cancelarReserva(_ reserva: Reserva) async {
        try? await service.cancelarReservaNegocio(id: reserva.idReservacion)
        await cargar()
    }

    func cancelarEvento() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let resp = try await service.cancelarEvento(id: evento.idEvento)
            afectados = resp.afectados ?? []
            cancelado = true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudo cancelar el evento."
        }
    }
}

// Perfil del negocio

@MainActor
final class NegocioPerfilViewModel: ObservableObject {
    @Published var descripcion: String
    @Published var logoUrl: String
    @Published var telefono: String
    @Published var direccion: String
    @Published var instagram: String
    @Published var facebook: String
    @Published var tiktok: String
    @Published var paginaWeb: String

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = QueplanService.shared

    init(negocio: Negocio) {
        self.descripcion = negocio.descripcion ?? ""
        self.logoUrl = negocio.logoUrl ?? ""
        self.telefono = negocio.telefono ?? ""
        self.direccion = negocio.direccion ?? ""
        self.instagram = negocio.instagram ?? ""
        self.facebook = negocio.facebook ?? ""
        self.tiktok = negocio.tiktok ?? ""
        self.paginaWeb = negocio.paginaWeb ?? ""
    }

    func guardar(idNegocio: Int, session: SessionManager) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let actualizado = try await service.actualizarNegocio(
                NegocioActualizarRequest(
                    idNegocio: idNegocio,
                    descripcion: descripcion,
                    logoUrl: logoUrl,
                    telefono: telefono,
                    direccion: direccion,
                    instagram: instagram,
                    facebook: facebook,
                    tiktok: tiktok,
                    paginaWeb: paginaWeb
                )
            )
            session.updateNegocio(actualizado)
            return true
        } catch {
            errorMessage = (error as? APIError)?.errorDescription ?? "No se pudieron guardar los cambios."
            return false
        }
    }
}
