import SwiftUI

struct ClienteHistorialView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ClienteReservasViewModel()
    @State private var reservaParaOpinar: Reserva?
    @State private var reservaParaEliminar: Reserva?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Historial").font(.system(size: 26, weight: .bold))

                    if vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if vm.historial.isEmpty {
                        EmptyStateView(icon: "clock.arrow.circlepath",
                                       title: "Aún no tienes reservas",
                                       subtitle: "Tus actividades pasadas y futuras aparecerán aquí.")
                    } else {
                        ForEach(vm.historial) { reserva in
                            NavigationLink(destination: EventoDetalleView(reserva: reserva)) {
                                HistorialRow(
                                    reserva: reserva,
                                    onOpinar: { reservaParaOpinar = reserva },
                                    onEliminar: { reservaParaEliminar = reserva }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable { await cargar() }
            .task { await cargar() }
            .sheet(item: $reservaParaOpinar) { reserva in
                if let idCliente = session.cliente?.idCliente, let idEvento = reserva.idEvento {
                    OpinionModalView(idCliente: idCliente, idEvento: idEvento,
                                     nombreNegocio: reserva.nombreNegocio ?? reserva.nombreEvento ?? "")
                        .presentationDetents([.height(380)])
                }
            }
            .alert("¿Eliminar reserva?", isPresented: Binding(
                get: { reservaParaEliminar != nil },
                set: { if !$0 { reservaParaEliminar = nil } }
            )) {
                Button("Cancelar", role: .cancel) { reservaParaEliminar = nil }
                Button("Eliminar", role: .destructive) {
                    if let r = reservaParaEliminar, let id = session.cliente?.idCliente {
                        Task { await vm.eliminar(idReservacion: r.idReservacion, idCliente: id) }
                    }
                    reservaParaEliminar = nil
                }
            } message: {
                Text("Tu reserva pasará a estado cancelada.")
            }
        }
    }

    private func cargar() async {
        guard let id = session.cliente?.idCliente else { return }
        await vm.cargar(idCliente: id)
    }
}

struct HistorialRow: View {
    let reserva: Reserva
    let onOpinar: () -> Void
    let onEliminar: () -> Void

    private var esPasado: Bool {
        (reserva.fecha ?? .distantFuture) < Date()
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: reserva.logoUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(reserva.nombreEvento ?? reserva.nombreNegocio ?? "Evento")
                    .font(.subheadline.bold())
                if let fecha = reserva.fecha {
                    Text(DateFormatters.display.string(from: fecha))
                        .font(.caption).foregroundColor(Theme.gray)
                }
                Text("\(reserva.cantidadPersonas ?? 1) persona(s)")
                    .font(.caption2).foregroundColor(Theme.gray)
                EstadoBadge(estado: reserva.estadoDisplay)
            }
            Spacer()

            Menu {
                if esPasado && reserva.estadoEnum != .cancelada {
                    Button { onOpinar() } label: { Label("Opinar / calificar", systemImage: "star") }
                }
                if reserva.estadoEnum != .cancelada {
                    Button(role: .destructive) { onEliminar() } label: {
                        Label("Eliminar reserva", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis").foregroundColor(Theme.gray).padding(8)
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
