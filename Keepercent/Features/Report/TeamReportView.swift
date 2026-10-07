import SwiftUI
import KeepercentDomain

/// The container owns the SwiftData read; the card receives only domain values.
struct TeamReportView: View {
    let team: StoredRivalTeam
    let playerID: UUID
    let scope: MatchScope

    private var player: Player? { ScopedMatchData.player(playerID, team: team, scope: scope) }
    private var scopeLabel: String { ScopedMatchData.label(team, scope: scope) }
    private var goalkeeperNumber: Int? { player?.number }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.displayScale) private var displayScale
    @State private var sharedImage: Image?

    private var engine: StatsEngine {
        ScopedMatchData.engine(team, scope: scope).shots(facing: playerID)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TeamReportCardView(goalkeeperNumber: goalkeeperNumber, engine: engine, scopeLabel: scopeLabel)
                    .frame(width: 320)

                if let sharedImage {
                    ShareLink(
                        item: sharedImage,
                        subject: Text("Goalkeeper scouting report"),
                        preview: SharePreview(Text("Goalkeeper scouting report"), image: sharedImage)
                    ) {
                        // Navy on amber: white text on the light amber
                        // fill would be unreadable, in dark mode above all.
                        Label("Share Image", systemImage: "square.and.arrow.up")
                            .foregroundStyle(Palette.onBrandAmber)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Palette.brandAmber)
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
        .onChange(of: scopeLabel) { renderImage() }
        .onChange(of: goalkeeperNumber) { renderImage() }
        .onChange(of: colorScheme) { renderImage() }
    }

    @MainActor
    private func renderImage() {
        sharedImage = nil
        let card = TeamReportCardView(goalkeeperNumber: goalkeeperNumber, engine: engine, scopeLabel: scopeLabel)
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
