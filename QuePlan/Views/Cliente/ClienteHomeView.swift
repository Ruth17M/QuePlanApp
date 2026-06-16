import SwiftUI

struct ClienteHomeView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ClienteHomeViewModel()
    @State private var mostrarFiltros = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GreetingHeader(
                        nombre: session.cliente?.nombre ?? "Turista",
                        subtitulo: "Descubre, reserva y vive experiencias.",
                        imagenUrl: session.cliente?.imagenUrl
                    )

                    // Búsqueda + filtros
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(Theme.gray)
                            TextField("Buscar eventos", text: $vm.busqueda)
                                .onSubmit { Task { await vm.cargar() } }
                        }
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(Theme.fieldBackground)
                        .clipShape(Capsule())

                        Button {
                            mostrarFiltros = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Theme.pink)
                                .clipShape(Circle())
                        }
                    }

                    Text("Todos tus planes en un solo lugar")
                        .font(.headline)

                    if vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                    } else if let error = vm.errorMessage {
                        EmptyStateView(icon: "wifi.exclamationmark", title: "Algo salió mal", subtitle: error)
                    } else if vm.eventosFiltrados.isEmpty {
                        EmptyStateView(icon: "calendar.badge.exclamationmark",
                                       title: "Sin eventos disponibles",
                                       subtitle: "Vuelve más tarde o ajusta tus filtros.")
                    } else {
                        ForEach(vm.eventosFiltrados) { evento in
                            NavigationLink {
                                EventoDetalleView(evento: evento)
                            } label: {
                                EventoCard(evento: evento)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable { await vm.cargar() }
            .task { await vm.cargar() }
            .sheet(isPresented: $mostrarFiltros) {
                FiltrosView(vm: vm)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}


//tarjeta de evento
struct EventoCard: View {
    let evento: Evento

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: evento.imagenes?.first ?? evento.logoUrl)
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .center, endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(evento.nombre ?? "Evento")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(evento.nivelPrecio).foregroundColor(.white)
                    if let prom = evento.promedioCalificacion, prom > 0 {
                        Text("·").foregroundColor(.white)
                        HStack(spacing: 2) {
                            Text(String(format: "%.1f", prom)).foregroundColor(.white)
                            Image(systemName: "star.fill").foregroundColor(Theme.star)
                        }
                    }
                }
                .font(.subheadline)
            }
            .padding(14)
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

//eventos
struct FiltrosView: View {
    @ObservedObject var vm: ClienteHomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Calificación mínima").font(.subheadline.bold())
                    HStack {
                        Slider(value: $vm.calificacionMinima, in: 0...5, step: 0.5)
                            .tint(Theme.pink)
                        Text(String(format: "%.1f ★", vm.calificacionMinima))
                            .font(.footnote).foregroundColor(Theme.gray)
                            .frame(width: 50, alignment: .trailing)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Tarifa máxima").font(.subheadline.bold())
                    HStack {
                        Slider(value: $vm.tarifaMaxima, in: 0...5000, step: 50)
                            .tint(Theme.pink)
                        Text("$\(Int(vm.tarifaMaxima))")
                            .font(.footnote).foregroundColor(Theme.gray)
                            .frame(width: 60, alignment: .trailing)
                    }
                }

                if !vm.categoriasDisponibles.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Categoría").font(.subheadline.bold())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button {
                                    vm.categoriaSeleccionada = nil
                                } label: {
                                    Text("Todas")
                                        .font(.subheadline)
                                        .padding(.vertical, 6).padding(.horizontal, 14)
                                        .background(vm.categoriaSeleccionada == nil ? Theme.pink : Color.clear)
                                        .foregroundColor(vm.categoriaSeleccionada == nil ? .white : Theme.ink)
                                        .overlay(Capsule().stroke(Theme.pink, lineWidth: 1))
                                        .clipShape(Capsule())
                                }
                                ForEach(vm.categoriasDisponibles, id: \.self) { cat in
                                    Button {
                                        vm.categoriaSeleccionada = cat
                                    } label: {
                                        Text(cat)
                                            .font(.subheadline)
                                            .padding(.vertical, 6).padding(.horizontal, 14)
                                            .background(vm.categoriaSeleccionada == cat ? Theme.pink : Color.clear)
                                            .foregroundColor(vm.categoriaSeleccionada == cat ? .white : Theme.ink)
                                            .overlay(Capsule().stroke(Theme.pink, lineWidth: 1))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }

                Spacer()

                Button("Aplicar filtros") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            .padding(24)
            .navigationTitle("Filtros")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Restablecer") { vm.restablecerFiltros() }
                        .foregroundColor(Theme.pink)
                }
            }
        }
    }
}
