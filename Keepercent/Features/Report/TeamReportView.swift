import SwiftUI
import KeepercentDomain

/// The container owns the SwiftData read; the card receives only domain values.
struct TeamReportView: View {
    private enum Team {
        case rival(StoredRivalTeam)
        case own(StoredOwnTeam)
    }
    private let team: Team
    let playerID: UUID
    let scope: MatchScope

    init(team: StoredRivalTeam, playerID: UUID, scope: MatchScope) {
        self.team = .rival(team)
        self.playerID = playerID
        self.scope = scope
    }

    init(ownTeam: StoredOwnTeam, playerID: UUID, scope: MatchScope) {
        self.team = .own(ownTeam)
        self.playerID = playerID
        self.scope = scope
    }

    private var player: Player? {
        switch team {
        case .rival(let team): return ScopedMatchData.player(playerID, team: team, scope: scope)
        case .own(let team): return ScopedMatchData.player(playerID, team: team, scope: scope)
        }
    }
    private var scopeLabel: String {
        switch team {
        case .rival(let team): return ScopedMatchData.label(team, scope: scope)
        case .own(let team): return ScopedMatchData.label(team, scope: scope)
        }
    }
    private var perspective: TeamReportPerspective {
        if case .own = team { return .own }
        return .rival
    }
    private var goalkeeperNumber: Int? { player?.number }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.displayScale) private var displayScale
    @State private var sharedImage: Image?
    @State private var previewHeight: CGFloat = 1
    @State private var previewScale: CGFloat = 1

    private var engine: StatsEngine {
        switch team {
        case .rival(let team): return ScopedMatchData.engine(team, scope: scope).shots(facing: playerID)
        case .own(let team): return ScopedMatchData.engine(team, scope: scope).shots(facingOwnGoalkeeper: playerID)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                GeometryReader { proxy in
                    let scale = proxy.size.width / 320
                    reportCard
                        .fixedSize(horizontal: false, vertical: true)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { previewHeight = $0 }
                        .scaleEffect(scale, anchor: .topLeading)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width / 320 } action: { previewScale = $0 }
                .frame(height: previewHeight * previewScale)

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
        .onChange(of: perspective) { renderImage() }
        .onChange(of: colorScheme) { renderImage() }
        .onChange(of: colorSchemeContrast) { renderImage() }
    }

    private var reportCard: some View {
        TeamReportCardView(goalkeeperNumber: goalkeeperNumber, engine: engine, scopeLabel: scopeLabel,
                           perspective: perspective, contrast: colorSchemeContrast)
            .dynamicTypeSize(.large)
            .environment(\.colorScheme, colorScheme)
    }

    @MainActor
    private func renderImage() {
        sharedImage = nil
        let renderer = ImageRenderer(content: reportCard)
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
