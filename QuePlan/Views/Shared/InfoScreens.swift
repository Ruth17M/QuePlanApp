import SwiftUI

/// Pestaña de términos y condiciones
struct TerminosView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Términos y condiciones")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 4)

                grupo("1. Aceptación de los Términos",
                      "Al descargar, acceder o utilizar la aplicación QuePlan (\"la App\"), usted (\"el Usuario\") acepta cumplir con estos Términos y Condiciones, así como con nuestra Política de Privacidad. Si no está de acuerdo, no debe utilizar la App.")
                grupo("2. Licencia de Uso",
                      "QuePlan otorga al usuario una licencia limitada, no exclusiva, intransferible y revocable para descargar, instalar y utilizar la App para uso personal y no comercial.")
                grupo("3. Conducta del Usuario y Restricciones",
                      "El Usuario se compromete a no:\n• Utilizar la App con fines ilegales.\n• Copiar, modificar, descompilar o realizar ingeniería inversa en la App.\n• Enviar virus, spam o contenido malicioso.\n• Suplantar la identidad de otra persona o empresa.")
                grupo("4. Propiedad Intelectual",
                      "Todo el contenido de la App, incluyendo textos, gráficos, logotipos, iconos y software, es propiedad exclusiva de QuePlan y está protegido por las leyes de propiedad intelectual.")
                grupo("5. Cuentas de Usuario",
                      "El usuario es responsable de mantener la confidencialidad de sus credenciales y de todas las actividades que ocurran bajo su cuenta.")
                grupo("6. Pago y Reservaciones",
                      "El pago se realiza directamente con el negocio al asistir al evento. QuePlan no procesa pagos ni se hace responsable de transacciones entre las partes.")
            }
            .padding(20)
        }
        .navigationTitle("Términos y condiciones")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func grupo(_ titulo: String, _ cuerpo: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(titulo).font(.subheadline.bold())
            Text(cuerpo).font(.footnote).foregroundColor(Theme.ink.opacity(0.8))
        }
    }
}

/// Pestaña de ayuda.
struct AyudaView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ayuda("¿Cómo reservo un evento?",
                      "Entra al evento que te interese, pulsa \"Quiero inscribirme\", elige el horario y el número de personas, y confirma. Recibirás el estado de tu reserva en \"Mi experiencia\".")
                ayuda("¿Cómo califico un evento?",
                      "Después de asistir, ve al evento desde tu historial y comparte tu opinión con estrellas y un comentario.")
                ayuda("¿Cómo publico un evento? (Negocios)",
                      "Desde tu calendario pulsa el botón \"+\", completa la información de la actividad y publícala. Podrás repetirla o cancelarla cuando quieras.")
                ayuda("¿Necesito pagar en la App?",
                      "No. El pago es directo con el negocio. La App solo coordina la reserva y la comunicación.")
            }
            .padding(20)
        }
        .navigationTitle("Ayuda")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func ayuda(_ q: String, _ a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(q, systemImage: "questionmark.circle.fill")
                .font(.subheadline.bold())
                .foregroundColor(Theme.pink)
            Text(a).font(.footnote).foregroundColor(Theme.ink.opacity(0.8))
        }
    }
}

// Diálogos tipo tarjeta

struct CardDialog<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) { content }
                .padding(24)
                .frame(maxWidth: 300)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 20)
                .padding(40)
        }
    }
}

/// Diálogo de confirmación con icono (info / éxito / error).
struct ConfirmDialog: View {
    enum Style { case info, success, danger }
    let style: Style
    let title: String
    var message: String? = nil
    var confirmTitle: String = "Sí"
    var cancelTitle: String = "No"
    var showsButtons: Bool = true
    var onConfirm: () -> Void = {}
    var onCancel: () -> Void = {}

    var body: some View {
        CardDialog {
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Image(systemName: icon)
                .font(.system(size: 54))
                .foregroundColor(color)

            if let message {
                Text(message)
                    .font(.footnote)
                    .foregroundColor(Theme.gray)
                    .multilineTextAlignment(.center)
            }

            if showsButtons {
                HStack(spacing: 0) {
                    Button(confirmTitle, action: onConfirm)
                        .frame(maxWidth: .infinity)
                    if !cancelTitle.isEmpty {
                        Divider().frame(height: 20)
                        Button(cancelTitle, action: onCancel)
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Theme.gray)
                    }
                }
                .font(.subheadline.bold())
                .padding(.top, 4)
            }
        }
    }

    private var icon: String {
        switch style {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .danger: return "xmark.circle"
        }
    }
    private var color: Color {
        switch style {
        case .info: return Theme.warning
        case .success: return Theme.success
        case .danger: return Theme.danger
        }
    }
}
