import SwiftUI

struct MonthPickerButton: View {
    var monthName: String = "Marzo"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(Theme.pink)
                .font(.system(size: 16))
            Text(monthName)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.white)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.pink, lineWidth: 1.5))
    }
}
