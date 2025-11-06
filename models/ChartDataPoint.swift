import Foundation

struct ChartDataPoint: Identifiable, Hashable {
    let id = UUID()

    let date: Date

    let value: Double

    let category: String?

    let label: String?

    init(date: Date, value: Double, category: String? = nil, label: String? = nil) {
        self.date = date
        self.value = value
        self.category = category
        self.label = label
    }
}

struct DailyChartData: Identifiable {
    let id = UUID()

    let day: Date

    let dataPoints: [ChartDataPoint]

    var totalValue: Double {
        dataPoints.reduce(0) { $0 + $1.value }
    }

    var averageValue: Double {
        guard !dataPoints.isEmpty else { return 0 }
        return totalValue / Double(dataPoints.count)
    }

    var eventCount: Int {
        dataPoints.count
    }
}

struct PieChartDataPoint: Identifiable {
    let id = UUID()

    let category: String

    let value: Double

    let color: String

    var percentage: Double = 0
}
