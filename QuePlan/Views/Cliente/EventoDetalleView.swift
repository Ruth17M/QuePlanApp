import SwiftUI

struct EventoDetalleView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm: EventoDetalleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var mostrarReserva = false

    init(evento: Evento) {
        _vm = StateObject(wrappedValue: EventoDetalleViewModel(evento: evento))
    }

    init(reserva: Reserva) {
        let evento = Evento(
            idEvento: reserva.idEvento ?? 0,
            nombre: reserva.nombreEvento,
            ubicacion: reserva.ubicacion,
            nombreNegocio: reserva.nombreNegocio,
            logoUrl: reserva.logoUrl
        )
        _vm = StateObject(wrappedValue: EventoDetalleViewModel(evento: evento))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Imagen principal
                ZStack(alignment: .bottomLeading) {
                    RemoteImage(urlString: vm.imagenes.first ?? vm.evento.logoUrl)
                        .frame(height: 280)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    LinearGradient(colors: [.clear, .black.opacity(0.5)],
                                   startPoint: .center, endPoint: .bottom)
                        .frame(height: 280)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.evento.nombre ?? "Evento")
                            .font(.title.bold()).foregroundColor(.white)
                        HStack(spacing: 6) {
                            Text(vm.evento.nivelPrecio).foregroundColor(.white)
                            if let p = vm.evento.promedioCalificacion, p > 0 {
                                Text("·  \(String(format: "%.1f", p))").foregroundColor(.white)
                                Image(systemName: "star.fill").foregroundColor(Theme.star)
                            }
                        }
                    }
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(vm.evento.nombre ?? "Evento").font(.title2.bold())
                        Spacer()
                        if let cat = vm.evento.categoria {
                            Text(cat).font(.caption.bold())
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Theme.pinkLight)
                                .foregroundColor(Theme.pink)
                                .clipShape(Capsule())
                        }
                    }

                    if let desc = vm.evento.descripcion, !desc.isEmpty {
                        Text(desc).font(.subheadline).foregroundColor(Theme.ink.opacity(0.8))
                    }

                    // Datos
                    infoRow(icon: "mappin.circle.fill", text: vm.evento.ubicacion ?? "Ubicación por confirmar")
                    if let fecha = vm.evento.fecha {
                        infoRow(icon: "calendar", text: DateFormatters.display.string(from: fecha))
                        infoRow(icon: "clock", text: DateFormatters.hora.string(from: fecha))
                    }
                    if let precio = vm.evento.precio {
                        infoRow(icon: "creditcard", text: "$\(String(format: "%.0f", precio)) por persona")
                    }
                    if (vm.evento.tieneEstacionamiento ?? 0).asBool {
                        infoRow(icon: "car.fill", text: "Cuenta con estacionamiento")
                    }
                    if (vm.evento.requiereAnticipo ?? 0).asBool, let m = vm.evento.montoAnticipo {
                        infoRow(icon: "exclamationmark.circle", text: "Requiere anticipo de $\(String(format: "%.0f", m))")
                    }

                    // Galería
                    if vm.imagenes.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(vm.imagenes, id: \.self) { url in
                                    RemoteImage(urlString: url)
                                        .frame(width: 150, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                    }

                    Button("Quiero inscribirme") { mostrarReserva = true }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.vertical, 4)

                    // Opiniones
                    if !vm.opiniones.isEmpty {
                        Text("Opiniones").font(.title3.bold()).padding(.top, 6)
                        ForEach(vm.opiniones) { opinion in
                            OpinionRow(opinion: opinion)
                        }
                    }
                }
                .padding(20)
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.cargar() }
        .sheet(isPresented: $mostrarReserva) {
            ReservaSheet(evento: vm.evento)
                .presentationDetents([.medium, .large])
        }
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(Theme.pink)
            Text(text).font(.subheadline)
            Spacer()
        }
    }
}

// Fila de opinión

struct OpinionRow: View {
    let opinion: Opinion

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AvatarView(urlString: opinion.imagenUrl, size: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(opinion.nombreCliente ?? "Cliente").font(.subheadline.bold())
                if let nombreEvento = opinion.nombreEvento {
                    Text("fue al evento \(nombreEvento) y dice:")
                        .font(.caption).foregroundColor(Theme.gray)
                }
                Text(opinion.comentario ?? "")
                    .font(.footnote).foregroundColor(Theme.ink.opacity(0.85))
                StarRatingView(rating: Double(opinion.calificacion ?? 0), size: 11)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        Divider()
    }
}

// Hoja de reserva ("Asegura tu lugar")

struct ReservaSheet: View {
    let evento: Evento
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ReservaViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var reservaExitosa = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Asegura tu lugar")
                .font(.title2.bold())
                .foregroundColor(Theme.pink)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text("Detalles").font(.headline)

            HStack(spacing: 10) {
                Image(systemName: "calendar").foregroundColor(Theme.pink)
                VStack(alignment: .leading) {
                    Text("Fecha").font(.subheadline)
                    Text(evento.fecha.map { DateFormatters.display.string(from: $0) } ?? "Por confirmar")
                        .font(.footnote).foregroundColor(Theme.gray)
                }
            }

            HStack {
                Text("Número de personas").font(.subheadline)
                Spacer()
                Stepper(value: $vm.cantidadPersonas, in: 1...50) {
                    Text("\(vm.cantidadPersonas)")
                        .font(.headline).foregroundColor(Theme.pink)
                }
                .fixedSize()
            }

            InlineError(message: vm.errorMessage)

            Button {
                Task {
                    guard let idCliente = session.cliente?.idCliente else { return }
                    if await vm.reservar(idCliente: idCliente, idEvento: evento.idEvento) {
                        reservaExitosa = true
                    }
                }
            } label: {
                if vm.isLoading { ProgressView().tint(.white) }
                else { Text("Continuar") }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(vm.isLoading)

            Button("Cancelar") { dismiss() }
                .frame(maxWidth: .infinity)
                .foregroundColor(Theme.gray)

            Spacer(minLength: 0)
        }
        .padding(24)
        .alert("¡Reserva creada!", isPresented: $reservaExitosa) {
            Button("Listo") { dismiss() }
        } message: {
            Text("Tu lugar está \(vm.reservaCreada?.estadoDisplay.titulo.lowercased() ?? "registrado"). Revisa el estado en \"Mi experiencia\".")
        }
    }
}
