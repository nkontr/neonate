import SwiftUI

struct ChartLegend: View {

    let items: [LegendItem]

    var body: some View {
        HStack(spacing: 16) {
            ForEach(items) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 8, height: 8)

                    Text(item.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct LegendItem: Identifiable {
    let id = UUID()
    let label: String
    let color: Color
}

#if DEBUG
struct ChartLegend_Previews: PreviewProvider {
    static var previews: some View {
        ChartLegend(items: [
            LegendItem(label: "Грудное", color: .blue),
            LegendItem(label: "Бутылочка", color: .green),
            LegendItem(label: "Прикорм", color: .orange)
        ])
        .padding()
    }
}
#endif
