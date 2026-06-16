import SwiftUI

enum Theme {
    static let pink = Color(hex: 0xE60C88)
    static let pinkDark = Color(hex: 0xC30B73)
    static let pinkLight = Color(hex: 0xFCE4F1)
    static let ink = Color(hex: 0x1B1B1F)
    static let gray = Color(hex: 0x8A8A8E)
    static let fieldBackground = Color(hex: 0xF4F4F6)
    static let cardBackground = Color.white
    static let success = Color(hex: 0x4CAF50)
    static let warning = Color(hex: 0xF6A609)
    static let danger = Color(hex: 0xE53935)
    static let star = Color(hex: 0xF6B100)
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// Botones reutilizables
struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(enabled ? Theme.pink : Theme.pink.opacity(0.4))
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                Capsule().stroke(Theme.gray.opacity(0.4), lineWidth: 1.2)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// Campo de texto con estilo QuePlan

struct QPTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var icon: String? = nil

    var body: some View {
        HStack(spacing: 10) {
            if let icon {
                Image(systemName: icon).foregroundColor(Theme.gray)
            }
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .sentences)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct QPSecureField: View {
    let placeholder: String
    @Binding var text: String
    @State private var visible = false

    var body: some View {
        HStack(spacing: 10) {
            Group {
                if visible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            Button { visible.toggle() } label: {
                Image(systemName: visible ? "eye.slash" : "eye")
                    .foregroundColor(Theme.pink)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(Theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// Estrellas de calificación

struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 14
    var interactive: Bool = false
    var onSelect: ((Int) -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { i in
                Image(systemName: symbol(for: i))
                    .foregroundColor(Theme.star)
                    .font(.system(size: size))
                    .onTapGesture {
                        if interactive { onSelect?(i) }
                    }
            }
        }
    }

    private func symbol(for index: Int) -> String {
        if Double(index) <= rating { return "star.fill" }
        if Double(index) - 0.5 <= rating { return "star.leadinghalf.filled" }
        return "star"
    }
}
