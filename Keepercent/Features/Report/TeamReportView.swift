import SwiftUI
import KeepercentDomain

/// The container owns the SwiftData read; the card receives only domain values.
struct TeamReportView: View {
    let team: StoredRivalTeam
    let goalkeeperNumber: Int

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var sharedImage: Image?

    private var engine: StatsEngine {
        let shots = team.sessions.flatMap { $0.shots.compactMap(\.domainShot) }
        return StatsEngine(shots: shots).shots(facing: goalkeeperNumber)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TeamReportCardView(goalkeeperNumber: goalkeeperNumber, engine: engine)
                    .frame(width: 320)

                if let sharedImage {
                    ShareLink(
                        item: sharedImage,
                        subject: Text("Goalkeeper scouting report"),
                        preview: SharePreview("Goalkeeper #\(goalkeeperNumber) report", image: sharedImage)
                    ) {
                        Label("Share Image", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Prepare Image", action: renderImage)
                        .buttonStyle(.bordered)
                    Text("Image unavailable until the card is rendered.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Team Report")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: renderImage)
        .onChange(of: engine.shots) { renderImage() }
        .onChange(of: colorScheme) { renderImage() }
    }

    @MainActor
    private func renderImage() {
        sharedImage = nil
        let card = TeamReportCardView(goalkeeperNumber: goalkeeperNumber, engine: engine)
            .frame(width: 320)
            .environment(\.colorScheme, colorScheme)
        let renderer = ImageRenderer(content: card)
        renderer.scale = displayScale
        if let image = renderer.uiImage {
            sharedImage = Image(uiImage: image)
        }
    }
}

#Preview("Demo report") {
    NavigationStack {
        TeamReportCardView(
            goalkeeperNumber: DemoData.goalkeeperMarcPuig.number,
            engine: StatsEngine(shots: DemoData.shots).shots(facing: DemoData.goalkeeperMarcPuig.number)
        )
        .frame(width: 320)
    }
}
