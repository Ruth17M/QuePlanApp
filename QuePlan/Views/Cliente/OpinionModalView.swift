import SwiftUI

/// Modal "¿Cómo estuvo tu experiencia con ...?" para calificar al negocio.
struct OpinionModalView: View {
    let idCliente: Int
    let idEvento: Int
    let nombreNegocio: String

    @StateObject private var vm = OpinionViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var enviado = false

    var body: some View {
        VStack(spacing: 20) {
            if enviado {
                Text("¡Gracias por\ncompartir tu opinión!")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.success)
                Button("Listo") { dismiss() }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 40)
            } else {
                Text("¿Cómo estuvo tu experiencia con \(nombreNegocio)?")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)
                Text("Califica al negocio")
                    .font(.subheadline).foregroundColor(Theme.gray)

                StarRatingView(rating: Double(vm.calificacion), size: 34, interactive: true) { value in
                    vm.calificacion = value
                }

                TextField("Cuéntanos tu experiencia (opcional)", text: $vm.comentario, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(12)
                    .background(Theme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)

                InlineError(message: vm.errorMessage)

                Button {
                    Task {
                        if await vm.enviar(idCliente: idCliente, idEvento: idEvento) {
                            withAnimation { enviado = true }
                        }
                    }
                } label: {
                    if vm.isLoading { ProgressView().tint(.white) }
                    else { Text("Enviar opinión") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .disabled(vm.isLoading)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 16)
    }
}
