import SwiftUI

struct ClienteCalendarioView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = ClienteReservasViewModel()
    @State private var selectedDay = Calendar.current.component(.day, from: Date())
    @State private var currentMonth: Date = Date()
    @State private var showFullCal = false

    private let cal = Calendar.current
    private let weekLetters = ["D","L","M","M","J","V","S"]

    private var reservasDelDia: [Reserva] {
        vm.proximas.filter { reserva in
            guard let f = reserva.fecha else { return false }
            return cal.isDate(f, equalTo: fechaDelMes(selectedDay), toGranularity: .day)
        }
    }

    private func fechaDelMes(_ day: Int) -> Date {
        var comps = cal.dateComponents([.year, .month], from: currentMonth)
        comps.day = day
        return cal.date(from: comps) ?? Date()
    }

    private func diasConReservas(en mes: Date) -> Set<Int> {
        Set(vm.proximas.compactMap { reserva in
            guard let f = reserva.fecha else { return nil }
            guard cal.isDate(f, equalTo: mes, toGranularity: .month) else { return nil }
            return cal.component(.day, from: f)
        })
    }

    private var highlightedDays: Set<Int> {
        diasConReservas(en: currentMonth)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    GreetingHeader(
                        nombre: session.cliente?.nombre ?? "Turista",
                        subtitulo: "Vive lo Xico, disfruta a lo grande",
                        imagenUrl: session.cliente?.imagenUrl
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
                            Text("\(reservasDelDia.count) \(reservasDelDia.count == 1 ? "actividad" : "actividades")")
                                .font(.caption)
                                .foregroundColor(Theme.gray)
                        }
                    }

                    Text("Mis actividades")
                        .font(.headline)

                    if vm.isLoading {
                        ProgressView().frame(maxWidth: .infinity).padding()
                    } else if reservasDelDia.isEmpty {
                        Text(vm.proximas.isEmpty ? "No tienes reservas activas" : "Sin actividades para este día")
                            .foregroundColor(Theme.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(reservasDelDia) { reserva in
                            NavigationLink(destination: EventoDetalleView(reserva: reserva)) {
                                ReservaActivityCard(reserva: reserva)
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
                    let esHoy = cal.isDate(fecha, inSameDayAs: fechaDelMes(selectedDay))
                    let isHighlighted = highlightedDays.contains(dia)
                    VStack(spacing: 4) {
                        Text("\(dia)")
                            .font(.subheadline)
                            .foregroundColor(esHoy ? .white : Theme.ink)
                            .frame(width: 34, height: 34)
                            .background(esHoy ? Theme.pink : Color.clear)
                            .clipShape(Circle())
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
        guard let id = session.cliente?.idCliente else { return }
        await vm.cargar(idCliente: id)
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

// MARK: - Tira semanal con selector de mes

struct WeekCalendarView: View {
    @Binding var diaSeleccionado: Date
    var diasConEventos: Set<Int> = []

    private let cal = Calendar.current
    private let dias = ["D", "L", "M", "M", "J", "V", "S"]

    var body: some View {
        VStack(spacing: 14) {
            // Encabezado días
            HStack {
                ForEach(dias.indices, id: \.self) { i in
                    Text(dias[i]).font(.caption.bold()).foregroundColor(Theme.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Semana del día seleccionado
            HStack {
                ForEach(diasDeLaSemana(), id: \.self) { fecha in
                    let dia = cal.component(.day, from: fecha)
                    let esHoy = cal.isDate(fecha, inSameDayAs: diaSeleccionado)
                    VStack(spacing: 4) {
                        Text("\(dia)")
                            .font(.subheadline)
                            .foregroundColor(esHoy ? .white : Theme.ink)
                            .frame(width: 34, height: 34)
                            .background(esHoy ? Theme.pink : Color.clear)
                            .clipShape(Circle())
                        Circle()
                            .fill(diasConEventos.contains(dia) ? Theme.pink : .clear)
                            .frame(width: 5, height: 5)
                    }
                    .frame(maxWidth: .infinity)
                    .onTapGesture { diaSeleccionado = fecha }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func diasDeLaSemana() -> [Date] {
        guard let interval = cal.dateInterval(of: .weekOfMonth, for: diaSeleccionado) else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: interval.start) }
    }

}

// MARK: - Tarjeta de actividad (reserva del cliente)

struct ReservaActivityCard: View {
    let reserva: Reserva

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(urlString: reserva.logoUrl)
                .frame(height: 150).frame(maxWidth: .infinity).clipped()
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reserva.nombreEvento ?? reserva.nombreNegocio ?? "Evento")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    EstadoBadge(estado: reserva.estadoDisplay)
                }
                if let fecha = reserva.fecha {
                    Text("\(DateFormatters.display.string(from: fecha)) · \(DateFormatters.hora.string(from: fecha))")
                        .font(.caption).foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(14)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct EstadoBadge: View {
    let estado: EstadoReserva
    var body: some View {
        Text(estado.titulo)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.9))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    private var color: Color {
        switch estado {
        case .pendiente: return Theme.warning
        case .confirmada: return Theme.success
        case .cancelada: return Theme.danger
        case .completada: return Theme.success
        }
    }
}
