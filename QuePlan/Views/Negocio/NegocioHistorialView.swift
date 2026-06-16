import SwiftUI

struct NegocioHistorialView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = NegocioEventosViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Historial").font(.system(size: 26, weight: .bold))

                    if vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if vm.eventos.isEmpty {
                        EmptyStateView(icon: "calendar",
                                       title: "Aún no has publicado eventos",
                                       subtitle: "Crea tu primera actividad desde Inicio.")
                    } else {
                        ForEach(eventosOrdenados) { evento in
                            NavigationLink {
                                EventoNegocioDetalleView(evento: evento)
                            } label: {
                                HistorialEventoRow(evento: evento)
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
        }
    }

    private var eventosOrdenados: [Evento] {
        vm.eventos
            .filter { ($0.estado?.lowercased() ?? "activo") != "cancelado" }
            .sorted { ($0.fecha ?? .distantPast) > ($1.fecha ?? .distantPast) }
    }

    private func cargar() async {
        guard let id = session.negocio?.idNegocio else { return }
        await vm.cargar(idNegocio: id)
    }
}

struct HistorialEventoRow: View {
    let evento: Evento

    private var cancelado: Bool { (evento.estado?.lowercased() ?? "") == "cancelado" }
    private var completado: Bool {
        guard !cancelado, let f = evento.fecha else { return false }
        return f < Date()
    }
    private var proximo: Bool {
        guard !cancelado, let f = evento.fecha else { return false }
        return f >= Date()
    }

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(urlString: evento.imagenes?.first ?? evento.logoUrl)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(evento.nombre ?? "Evento").font(.subheadline.bold())
                Text("Cupo: \(evento.cupo ?? 0) personas")
                    .font(.caption).foregroundColor(Theme.gray)
                if let fecha = evento.fecha {
                    Text(DateFormatters.display.string(from: fecha) + " · " + DateFormatters.hora.string(from: fecha) + " hrs")
                        .font(.caption2).foregroundColor(Theme.gray)
                }
            }
            Spacer()
            Group {
                if completado {
                    Text("Completado")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.success.opacity(0.15))
                        .foregroundColor(Theme.success)
                        .clipShape(Capsule())
                } else if proximo {
                    Text("Próximo")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.pinkLight)
                        .foregroundColor(Theme.pink)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
