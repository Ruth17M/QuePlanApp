import SwiftUI

struct EventoFormView: View {
    enum Modo {
        case crear
        case editar(Evento)
        case repetir(Evento)

        var titulo: String {
            switch self {
            case .crear: return "Nueva actividad"
            case .editar: return "Editar actividad"
            case .repetir: return "Repetir actividad"
            }
        }
    }

    let modo: Modo
    @EnvironmentObject private var session: SessionManager
    @StateObject private var vm = EventoFormViewModel()
    @Environment(\.dismiss) private var dismiss

    private let categorias = ["Cultural", "Gastronómico", "Recreativo", "Educativo", "Musical", "Deportivo"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InlineError(message: vm.errorMessage)

                // Imagen / cambiar imagen
                ZStack {
                    RemoteImage(urlString: vm.imagenesTexto.split(whereSeparator: \.isNewline).first.map(String.init))
                        .frame(height: 160).frame(maxWidth: .infinity).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("Cambiar imagen")
                        .font(.subheadline.bold()).foregroundColor(.white)
                        .padding(8).background(.black.opacity(0.35)).clipShape(Capsule())
                }

                campo("Nombre de la actividad") {
                    QPTextField(placeholder: "Nombre", text: $vm.nombre)
                }
                campo("Descripción de la actividad") {
                    descripcionEditor
                }
                campo("Categoría") {
                    Menu {
                        ForEach(categorias, id: \.self) { c in Button(c) { vm.categoria = c } }
                    } label: {
                        HStack {
                            Text(vm.categoria).foregroundColor(Theme.ink)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(Theme.pink)
                        }
                        .padding(.vertical, 14).padding(.horizontal, 16)
                        .background(Theme.fieldBackground).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                campo("Cupo de la actividad") {
                    QPTextField(placeholder: "Cupo", text: $vm.cupo, keyboard: .numberPad)
                }
                campo("Dirección de la actividad") {
                    QPTextField(placeholder: "Dirección", text: $vm.ubicacion)
                }

                campo("Fecha y horario de la actividad") {
                    VStack(spacing: 10) {
                        DatePicker("Fecha", selection: $vm.fecha, displayedComponents: .date)
                        DatePicker("Hora", selection: $vm.hora, displayedComponents: .hourAndMinute)
                    }
                    .padding(.horizontal, 4)
                }

                campo("Precio por persona") {
                    QPTextField(placeholder: "Precio", text: $vm.precio, keyboard: .decimalPad)
                }

                Toggle("Tiene estacionamiento", isOn: $vm.tieneEstacionamiento).tint(Theme.pink)
                Toggle("Requiere anticipo", isOn: $vm.requiereAnticipo).tint(Theme.pink)
                if vm.requiereAnticipo {
                    QPTextField(placeholder: "Monto de anticipo", text: $vm.montoAnticipo, keyboard: .decimalPad)
                }
                Toggle("Autoconfirmación de reservas", isOn: $vm.autoconfirmacion).tint(Theme.pink)

                campo("Imágenes (una URL por línea)") {
                    descripcionImagenes
                }

                Button {
                    Task {
                        guard let id = session.negocio?.idNegocio else { return }
                        if await vm.guardar(idNegocio: id) { dismiss() }
                    }
                } label: {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text(vm.esEdicion ? "Guardar cambios" : "Publicar actividad") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(vm.isLoading)
            }
            .padding(20)
        }
        .navigationTitle(modo.titulo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cerrar") { dismiss() }
            }
        }
        .onAppear {
            switch modo {
            case .crear: break
            case .editar(let e): vm.precargar(desde: e, repetir: false)
            case .repetir(let e): vm.precargar(desde: e, repetir: true)
            }
        }
    }

    private func campo<Content: View>(_ titulo: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.subheadline.bold())
            content()
        }
    }

    private var descripcionEditor: some View {
        TextEditor(text: $vm.descripcion)
            .frame(height: 80)
            .scrollContentBackground(.hidden)
            .padding(8)
            .background(Theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var descripcionImagenes: some View {
        TextEditor(text: $vm.imagenesTexto)
            .frame(height: 70)
            .scrollContentBackground(.hidden)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(8)
            .background(Theme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
