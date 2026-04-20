import SwiftUI

struct TrendIndicator: View {

    let trend: TrendDirection
    let percentageChange: Double
    let isPositiveGood: Bool

    private var trendColor: Color {
        switch trend {
        case .up:
            return isPositiveGood ? .green : .red
        case .down:
            return isPositiveGood ? .red : .green
        case .stable:
            return .gray
        }
    }

    private var formattedPercentage: String {
        let absValue = abs(percentageChange)
        return String(format: "%.1f%%", absValue)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.systemImage)
                .font(.caption)
                .foregroundColor(trendColor)

            Text(formattedPercentage)
                .font(.caption)
                .foregroundColor(trendColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(trendColor.opacity(0.1))
        )
    }
}

#if DEBUG
struct TrendIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            TrendIndicator(trend: .up, percentageChange: 15.5, isPositiveGood: true)
            TrendIndicator(trend: .down, percentageChange: -12.3, isPositiveGood: true)
            TrendIndicator(trend: .stable, percentageChange: 2.1, isPositiveGood: true)
        }
        .padding()
    }
}
#endif
