import SwiftUI

// Horizontal scroll of plant thumbnails. Selection persisted in UserSettings.selectedPlant.
struct PlantPicker: View {
    @Binding var selected: PlantKind

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PlantKind.allCases) { plant in
                Button { selected = plant } label: {
                    VStack(spacing: 6) {
                        PlantMascot(kind: plant, bend: 0, color: Theme.Palette.aligned)
                            .frame(width: 54, height: 54)
                        Text(plant.label)
                            .font(Theme.Font.caption(11).weight(.semibold))
                            .foregroundStyle(selected == plant ? Theme.Palette.accent : Theme.Palette.inkFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip)
                            .fill(selected == plant ? Theme.Palette.accent.opacity(0.1) : .clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip)
                            .stroke(selected == plant ? Theme.Palette.accent.opacity(0.5) : Theme.Palette.inkFaint.opacity(0.3))
                    )
                }
                .pressable()
            }
        }
    }
}
