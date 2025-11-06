import SwiftUI

struct PeriodPicker: View {

    @Binding var selectedPeriod: AnalyticsPeriod

    var body: some View {
        Picker("Период", selection: $selectedPeriod) {
            ForEach(AnalyticsPeriod.allCases, id: \.self) { period in
                Text(period.rawValue)
                    .tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

#if DEBUG
struct PeriodPicker_Previews: PreviewProvider {
    static var previews: some View {
        PeriodPicker(selectedPeriod: .constant(.week))
            .padding()
    }
}
#endif
