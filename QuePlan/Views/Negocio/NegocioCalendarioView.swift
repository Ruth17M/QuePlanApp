import SwiftUI

struct NegocioCalendarioView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = NegocioEventosViewModel()
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var currentMonth: Date = Date()
    @State private var showFullCal = false
    @State private var mostrarCrear = false

    private let cal = Calendar.current
    private let weekLetters = ["D","L","M","M","J","V","S"]

    private var highlightedDays: Set<Int> {
        Set(vm.activos.compactMap { evento in
            guard let f = evento.fecha else { return nil }
            guard cal.isDate(f, equalTo: currentMonth, toGranularity: .month) else { return nil }
            return cal.component(.day, from: f)
        })
    }

    private var eventosDelDia: [Evento] {
        vm.activos.filter { evento in
            guard let f = evento.fecha else { return false }
            return cal.isDate(f, equalTo: fechaDelMes(selectedDay), toGranularity: .day)
        }
    }

    private func fechaDelMes(_ day: Int) -> Date {
        var comps = cal.dateComponents([.year, .month], from: currentMonth)
        comps.day = day
        return cal.date(from: comps) ?? Date()
    }

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

                        VStack(spacing: 12) {
                            HStack {
                                Button {
                                    withAnimation { currentMonth = cal.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.pink)
                                }
                                Spacer()
                                MonthPickerButton(monthName: nombreMes(currentMonth))
                                Spacer()
                                Button {
                                    withAnimation { currentMonth = cal.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.pink)
                                }
                            }

                            if showFullCal {
                                MonthCalendarView(
                                    selectedDay: $selectedDay,
                                    highlightedDays: highlightedDays,
                                    month: currentMonth
                                )
                            } else {
                                weekStrip
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showFullCal.toggle()
                                }
                            } label: {
                                Image(systemName: showFullCal ? "chevron.up" : "chevron.down")
                                    .foregroundColor(Theme.pink)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(selectedDay)")
                                .font(.system(size: 42, weight: .bold))
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(nombreDia(fechaDelMes(selectedDay)))
                                        .font(.system(size: 16, weight: .semibold))
                                    if cal.isDateInToday(fechaDelMes(selectedDay)) {
                                        Text("Hoy")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.gray)
                                    }
                                }
                                Text("\(eventosDelDia.count) \(eventosDelDia.count == 1 ? "actividad programada" : "actividades programadas")")
                                    .font(.caption)
                                    .foregroundColor(Theme.gray)
                            }
                        }

                        if vm.isLoading {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        } else if eventosDelDia.isEmpty {
                            EmptyStateView(icon: "calendar.badge.plus",
                                           title: "Sin actividades este día",
                                           subtitle: "Pulsa + para publicar un evento.")
                        } else {
                            ForEach(eventosDelDia) { evento in
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

    private var weekStrip: some View {
        VStack(spacing: 14) {
            HStack {
                ForEach(weekLetters, id: \.self) { letter in
                    Text(letter).font(.caption.bold()).foregroundColor(Theme.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            HStack {
                ForEach(diasDeLaSemana(), id: \.self) { fecha in
                    let dia = cal.component(.day, from: fecha)
                    let esSeleccionado = cal.isDate(fecha, inSameDayAs: fechaDelMes(selectedDay))
                    let esHoy = cal.isDateInToday(fecha)
                    let isHighlighted = highlightedDays.contains(dia)
                    VStack(spacing: 4) {
                        Group {
                            if esSeleccionado && esHoy {
                                Text("\(dia)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(Theme.pink)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.pinkLight)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Theme.pink, lineWidth: 1.5))
                            } else if esSeleccionado {
                                Text("\(dia)")
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.pink)
                                    .clipShape(Circle())
                            } else if esHoy {
                                Text("\(dia)")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.ink)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.pinkLight)
                                    .clipShape(Circle())
                            } else {
                                Text("\(dia)")
                                    .font(.subheadline)
                                    .foregroundColor(Theme.ink)
                                    .frame(width: 34, height: 34)
                            }
                        }
                        Circle()
                            .fill(isHighlighted ? Theme.pink : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture { selectedDay = dia }
                }
            }
        }
    }

    private func diasDeLaSemana() -> [Date] {
        let today = Date()
        let weekday = cal.component(.weekday, from: today)
        let startOfWeek = cal.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private func cargar() async {
        guard let id = session.negocio?.idNegocio else { return }
        await vm.cargar(idNegocio: id)
    }

    private func nombreMes(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date).capitalized
    }

    private func nombreDia(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        return f.shortWeekdaySymbols[cal.component(.weekday, from: date) - 1].capitalized
    }
}

// Fila de evento (vista negocio)

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
