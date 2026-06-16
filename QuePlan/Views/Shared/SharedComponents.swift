import SwiftUI

// Logo de QuePlan

/// Logotipo "X" estilizado de QuePlan dibujado con paths
struct QuePlanLogo: View {
    var color: Color = .white
    var size: CGFloat = 90

    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                LogoStroke()
                    .stroke(color, style: StrokeStyle(lineWidth: size * 0.07, lineCap: .round))
                    .frame(width: size, height: size)
                    .scaleEffect(1 - CGFloat(i) * 0.18)
            }
        }
        .frame(width: size, height: size)
    }
}

private struct LogoStroke: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // Dos curvas cruzadas que forman la "X".
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.1))
        p.addCurve(to: CGPoint(x: w * 0.85, y: h * 0.9),
                   control1: CGPoint(x: w * 0.55, y: h * 0.35),
                   control2: CGPoint(x: w * 0.45, y: h * 0.65))
        p.move(to: CGPoint(x: w * 0.85, y: h * 0.1))
        p.addCurve(to: CGPoint(x: w * 0.15, y: h * 0.9),
                   control1: CGPoint(x: w * 0.45, y: h * 0.35),
                   control2: CGPoint(x: w * 0.55, y: h * 0.65))
        return p
    }
}

// Imagen remota con placeholder

struct RemoteImage: View {
    let urlString: String?
    var contentMode: ContentMode = .fill

    var body: some View {
        if let urlString, let url = URL(string: urlString), !urlString.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder
                case .empty:
                    ZStack { placeholder; ProgressView() }
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Theme.fieldBackground.overlay(
            Image(systemName: "photo")
                .font(.title)
                .foregroundColor(Theme.gray.opacity(0.5))
        )
    }
}

// Avatar circular

struct AvatarView: View {
    let urlString: String?
    var size: CGFloat = 44

    var body: some View {
        RemoteImage(urlString: urlString)
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .background(Circle().fill(Theme.fieldBackground))
    }
}

// Cabecera ondulada

struct WaveHeader: View {
    var height: CGFloat = 220

    var body: some View {
        WaveShape()
            .fill(Theme.pink)
            .frame(height: height)
            .ignoresSafeArea(edges: .top)
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .zero)
        p.addLine(to: CGPoint(x: rect.width, y: 0))
        p.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.78))
        p.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height * 0.78),
            control: CGPoint(x: rect.width / 2, y: rect.height * 1.15)
        )
        p.closeSubpath()
        return p
    }
}

// Mensaje de error en línea

struct InlineError: View {
    let message: String?
    var body: some View {
        if let message {
            Text(message)
                .font(.footnote)
                .foregroundColor(Theme.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// Sección con título

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Estado vacío

struct EmptyStateView: View {
    let icon: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundColor(Theme.gray.opacity(0.5))
            Text(title)
                .font(.headline)
                .foregroundColor(Theme.gray)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Theme.gray.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }
}
