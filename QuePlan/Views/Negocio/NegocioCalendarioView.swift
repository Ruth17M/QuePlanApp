import SwiftUI

struct NegocioCalendarioView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = NegocioEventosViewModel()
    @State private var diaSeleccionado = Date()
    @State private var mostrarCrear = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        GreetingHeader(
                            nombre: session.negocio?.nombreNegocio ?? "Negocio",
                            subtitulo: "Vive lo Xico, disfruta a lo grande",
                            imagenUrl: session.negocio?.logoUrl
                        )

                        WeekCalendarView(diaSeleccionado: $diaSeleccionado,
                                         diasConEventos: diasConEventos)

                        let eventosDia = vm.eventosEn(diaSeleccionado)
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(Calendar.current.component(.day, from: diaSeleccionado))")
                                .font(.system(size: 30, weight: .bold))
                            Text(esHoy ? "Hoy" : diaSemana(diaSeleccionado))
                                .font(.subheadline).foregroundColor(Theme.gray)
                            Spacer()
                            Text("\(eventosDia.count) actividades programadas")
                                .font(.caption).foregroundColor(Theme.gray)
                        }

                        if vm.isLoading {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        } else if eventosDia.isEmpty {
                            EmptyStateView(icon: "calendar.badge.plus",
                                           title: "Sin actividades este día",
                                           subtitle: "Pulsa + para publicar un evento.")
                        } else {
                            ForEach(eventosDia) { evento in
                                NavigationLink {
                                    EventoNegocioDetalleView(evento: evento)
                                } label: {
                                    EventoNegocioRow(evento: evento)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())

                // Botón flotante para crear evento
                Button {
                    mostrarCrear = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 58, height: 58)
                        .background(Theme.pink)
                        .clipShape(Circle())
                        .shadow(radius: 6)
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .refreshable { await cargar() }
            .task { await cargar() }
            .sheet(isPresented: $mostrarCrear, onDismiss: { Task { await cargar() } }) {
                NavigationStack {
                    EventoFormView(modo: .crear)
                }
            }
        }
    }

    private var esHoy: Bool { Calendar.current.isDateInToday(diaSeleccionado) }

    private var diasConEventos: Set<Int> {
        let cal = Calendar.current
        return Set(vm.activos.compactMap { $0.fecha.map { cal.component(.day, from: $0) } })
    }

    private func cargar() async {
        guard let id = session.negocio?.idNegocio else { return }
        await vm.cargar(idNegocio: id)
    }

    private func diaSemana(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "EEEE"
        return f.string(from: date).capitalized
    }
}

// MARK: - Fila de evento (vista negocio)

struct EventoNegocioRow: View {
    let evento: Evento

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.pink)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(evento.nombre ?? "Evento").font(.subheadline.bold())
                Text("Cupo: \(evento.cupo ?? 0) personas")
                    .font(.caption).foregroundColor(Theme.gray)
                if let fecha = evento.fecha {
                    Label(DateFormatters.hora.string(from: fecha) + " hrs",
                          systemImage: "clock")
                        .font(.caption2).foregroundColor(Theme.gray)
                }
            }
            Spacer()
            Image(systemName: "ellipsis").foregroundColor(Theme.gray)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
