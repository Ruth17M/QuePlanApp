import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDay: Int
    var highlightedDays: Set<Int> = []
    var month: Date = Date()

    private let weekLetters = ["D","L","M","M","J","V","S"]

    private var daysInMonth: [Int?] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: month)
        guard let firstDay = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        var result: [Int?] = Array(repeating: nil, count: weekday)
        for d in range { result.append(d) }
        return result
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(weekLetters, id: \.self) { letter in
                    Text(letter)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, day in
                    if let d = day {
                        let isHighlighted = highlightedDays.contains(d)
                        let isSelected = d == selectedDay && isHighlighted
                        Button {
                            if highlightedDays.contains(d) { selectedDay = d }
                        } label: {
                            Text("\(d)")
                                .font(.system(size: 13, weight: isHighlighted ? .bold : .regular))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(
                                        isSelected ? Theme.pink :
                                        isHighlighted ? Theme.pink : Color.clear
                                    )
                                )
                                .foregroundColor(
                                    isSelected || isHighlighted ? .white : Theme.ink
                                )
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }

            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.pink)
                .frame(width: 40, height: 3)
        }
    }
}
