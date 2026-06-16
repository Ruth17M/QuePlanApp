import SwiftUI

struct EventoNegocioDetalleView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm: EventoNegocioDetalleViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mostrarConfirmCancel = false
    @State private var mostrarEditar = false
    @State private var mostrarRepetir = false

    init(evento: Evento) {
        _vm = StateObject(wrappedValue: EventoNegocioDetalleViewModel(evento: evento))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    RemoteImage(urlString: vm.evento.imagenes?.first ?? vm.evento.logoUrl)
                        .frame(height: 220).frame(maxWidth: .infinity).clipped()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(vm.evento.nombre ?? "Evento").font(.title2.bold())
                            Spacer()
                            Button { mostrarEditar = true } label: {
                                Image(systemName: "square.and.pencil").foregroundColor(Theme.pink)
                            }
                        }

                        if let desc = vm.evento.descripcion {
                            Text(desc).font(.subheadline).foregroundColor(Theme.ink.opacity(0.8))
                        }

                        info("person.2", "Cupo: \(vm.evento.cupo ?? 0) personas")
                        info("mappin.circle.fill", vm.evento.ubicacion ?? "")
                        if let fecha = vm.evento.fecha {
                            info("calendar", DateFormatters.display.string(from: fecha))
                            info("clock", DateFormatters.hora.string(from: fecha) + " hrs")
                        }
                        if let p = vm.evento.precio {
                            info("creditcard", "$\(String(format: "%.0f", p)) por persona")
                        }

                        // Acciones
                        HStack(spacing: 12) {
                            Button { mostrarRepetir = true } label: {
                                Label("Repetir evento", systemImage: "arrow.clockwise")
                                    .font(.subheadline)
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                        .padding(.top, 4)

                        Button(role: .destructive) {
                            mostrarConfirmCancel = true
                        } label: {
                            Text("Cancelar actividad")
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.danger)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Divider()

                        // Personas interesadas / registradas
                        Text("Personas interesadas").font(.title3.bold())
                        if vm.reservas.isEmpty {
                            EmptyStateView(icon: "person.crop.circle.badge.questionmark",
                                           title: "Sin reservas todavía")
                        } else {
                            ForEach(vm.reservas) { reserva in
                                ReservaNegocioRow(
                                    reserva: reserva,
                                    onConfirmar: { Task { await vm.confirmar(reserva) } },
                                    onCancelar: { Task { await vm.cancelarReserva(reserva) } }
                                )
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .ignoresSafeArea(edges: .top)

            // Diálogos de cancelación de evento
            if mostrarConfirmCancel {
                ConfirmDialog(
                    style: .info,
                    title: "¿Deseas cancelar esta actividad?",
                    confirmTitle: "Sí",
                    cancelTitle: "No",
                    onConfirm: {
                        mostrarConfirmCancel = false
                        Task { await vm.cancelarEvento() }
                    },
                    onCancel: { mostrarConfirmCancel = false }
                )
            }
            if vm.cancelado {
                ConfirmDialog(
                    style: .danger,
                    title: "¡Cancelada!",
                    message: afectadosTexto,
                    confirmTitle: "Listo",
                    cancelTitle: "",
                    showsButtons: true,
                    onConfirm: { dismiss() }
                )
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.cargar() }
        .sheet(isPresented: $mostrarEditar, onDismiss: { Task { await vm.cargar() } }) {
            NavigationStack { EventoFormView(modo: .editar(vm.evento)) }
        }
        .sheet(isPresented: $mostrarRepetir, onDismiss: { Task { await vm.cargar() } }) {
            NavigationStack { EventoFormView(modo: .repetir(vm.evento)) }
        }
    }

    private var afectadosTexto: String {
        if vm.afectados.isEmpty { return "Actividad cancelada con éxito" }
        return "Actividad cancelada. Se notificó a \(vm.afectados.count) cliente(s)."
    }

    private func info(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.pink)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}

// MARK: - Fila de reserva (vista negocio) con confirmar / cancelar

struct ReservaNegocioRow: View {
    let reserva: Reserva
    let onConfirmar: () -> Void
    let onCancelar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(urlString: reserva.imagenUrl, size: 42)
            VStack(alignment: .leading, spacing: 3) {
                Text(reserva.nombreCliente ?? "Cliente").font(.subheadline.bold())
                Text("Lugares: \(reserva.cantidadPersonas ?? 1) personas")
                    .font(.caption).foregroundColor(Theme.gray)
                EstadoBadge(estado: reserva.estadoEnum)
            }
            Spacer()
            if reserva.estadoEnum == .pendiente {
                Button(action: onConfirmar) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .padding(10).background(Theme.success).clipShape(Circle())
                }
                Button(action: onCancelar) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .padding(10).background(Theme.danger).clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.fieldBackground, lineWidth: 1))
    }
}
