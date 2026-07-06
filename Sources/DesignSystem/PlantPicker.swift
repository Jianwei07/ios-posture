import SwiftUI

// Grid of potted plant cards (design board section 04): name + region
// caption, sage tint + check badge on the selected card. Selection persisted
// in UserSettings.selectedPlant.
struct PlantPicker: View {
    @Binding var selected: PlantKind

    private let columns = [GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12),
                           GridItem(.flexible(), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(PlantKind.allCases) { plant in
                card(for: plant)
            }
        }
    }

    private func card(for plant: PlantKind) -> some View {
        let isSelected = selected == plant
        return Button { selected = plant } label: {
            VStack(spacing: 6) {
                PlantMascot(kind: plant, bend: 0, color: Theme.Palette.aligned)
                    .frame(width: 54, height: 66)
                Text(plant.label)
                    .font(Theme.Font.caption(11).weight(.semibold))
                    .foregroundStyle(isSelected ? Theme.Palette.accent : Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(plant == .sunflower ? "Your default" : (plant.region ?? " "))
                    .font(Theme.Font.caption(10))
                    .foregroundStyle(Theme.Palette.inkFaint)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .fill(isSelected ? Theme.Palette.aligned.opacity(0.12) : Theme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.chip)
                    .stroke(isSelected ? Theme.Palette.aligned.opacity(0.6) : Theme.Palette.inkFaint.opacity(0.3),
                            lineWidth: isSelected ? 1.5 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.white, Theme.Palette.aligned)
                        .padding(6)
                }
            }
        }
        .pressable()
    }
}
