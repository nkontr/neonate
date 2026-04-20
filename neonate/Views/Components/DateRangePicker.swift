import SwiftUI

struct DateRangePicker: View {

    enum DateRange: String, CaseIterable {
        case today = "Сегодня"
        case week = "Неделя"
        case month = "Месяц"
        case all = "Все"
    }

    @Binding var selectedRange: DateRange

    var body: some View {
        Picker("Период", selection: $selectedRange) {
            ForEach(DateRange.allCases, id: \.self) { range in
                Text(range.rawValue)
                    .tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("Выбор периода времени")
    }

    func getDates() -> (startDate: Date, endDate: Date) {
        let calendar = Calendar.current
        let endDate = Date()

        switch selectedRange {
        case .today:
            let startDate = calendar.startOfDay(for: endDate)
            return (startDate, endDate)

        case .week:
            let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
            return (startDate, endDate)

        case .month:
            let startDate = calendar.date(byAdding: .month, value: -1, to: endDate) ?? endDate
            return (startDate, endDate)

        case .all:

            let startDate = calendar.date(byAdding: .year, value: -10, to: endDate) ?? endDate
            return (startDate, endDate)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedRange: DateRangePicker.DateRange = .today

        var body: some View {
            VStack(spacing: 20) {
                DateRangePicker(selectedRange: $selectedRange)
                    .padding()

                Text("Выбран период: \(selectedRange.rawValue)")
                    .font(.headline)
            }
        }
    }

    return PreviewWrapper()
}
