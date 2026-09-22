// SessionView is the CONTAINER for shot entry (T3.3, docs/mvp.md §6 item 3
// and §5.2). It replaces the placeholder that only confirmed which session
// was opened; this is the real end-to-end flow. It owns
// `@Environment(\.modelContext)`, the `StoredSession`/`StoredRivalTeam` it
// writes into, and every piece of entry `@State` — the presentational
// children it composes (`ShooterGridColumn`, `GoalView`, `CourtView`,
// `ShotEntryContextPanel`, `LastShotCardView`) only ever see plain
// `KeepercentDomain` values, never a stored row (CLAUDE.md's
// container/presentational rule).
//
// ## The flow, in five lines
//
//   1. Pick a shooter (rival attack) or rely on the active rival goalkeeper
//      (own attack) — `selectedShooterNumber` / `activeRivalGoalkeeperNumber`.
//   2. Tap the court -> `selectOrigin` records the raw point or the 7 m flag.
//   3. Tap the goal -> `selectTarget`; a post/miss resolves immediately,
//      an inside target waits for the Goal/Saved buttons.
//   4. `attemptRecord` calls `Shot.record` FIRST (typed `ShotEntryError`,
//      exhaustively switched by `shotEntryErrorMessage`); nothing is
//      written to SwiftData unless that succeeds.
//   5. `persist` builds exactly ONE `StoredShot`, saves, and on success
//      resets shooter/origin/target/chips while keeping the sticky
//      attacking side and the persistent active goalkeeper.
//
// ## Write path
//
// Same shape as `RosterEditorView`'s actions (see that file's header): the
// domain validates first and nothing touches `modelContext` if it throws;
// once `Shot.record` succeeds, exactly one `StoredShot` is appended to
// `session.shots` and inserted, `modelContext.save()` is tried, and a
// failure rolls back and shows the message instead of leaving a shot on
// screen next to an error that says it was not stored.
//
// ## One-level undo (docs/mvp.md §6 item 3)
//
// `lastShotID` names the one row Undo is allowed to delete. `undoLastShot`
// deletes exactly that row, then clears `lastShotID` to `nil` — so even
// though `LastShotCardView.removed` already draws no button (see that
// file's header comment for why a second tap is unreachable by
// construction), this is the second, independent guard: there is no ID left
// to act on either. Recording a new shot overwrites both `lastShotCard` and
// `lastShotID` together, so "replaces the card" and "Undo now targets the
// NEW shot" can never disagree.
//
// The `.removed` card's ~2 s auto-dismiss lives here, as `.task(id:
// lastShotCard)`: SwiftUI cancels and restarts that task whenever
// `lastShotCard` changes, so recording a new shot right after an undo
// cannot have the stale dismissal wipe out the new card.
//
// ## Layout (T3.3 decision ③)
//
// iPad landscape gets three columns (`threeColumnLayout`): shooter grid |
// goal-over-court (the vertical path, docs/mvp.md §5.2) | context panel,
// sized to fit an iPad Pro 11" (1210x834 pt) without scrolling.
// `isThreeColumnLayout(for:)` gates it on BOTH size classes being regular
// plus a landscape aspect. A Pro Max-class iPhone in landscape is regular
// wide but compact tall, so the vertical size class excludes it; iPad
// compact multitasking widths fail the horizontal one. No point floors: the
// first version required 700 pt of height, measured after the status bar,
// navigation bar and header, and an iPad Pro 11" in landscape never reached
// it. Everything else — iPhone in any orientation, iPad portrait — falls
// back to `verticalLayout` inside a `ScrollView`.
//
// The middle column's own height split between `GoalView` and `CourtView`
// is `middleColumnHeights(for:)` — see its doc comment for why it solves
// for equal rendered WIDTH rather than an arbitrary fraction.

import SwiftUI
import SwiftData
import KeepercentDomain

struct SessionView: View {
    let team: StoredRivalTeam
    let session: StoredSession

    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Sticky / persistent across shots (T3.3 decision ②).
    @State private var attackingSide: AttackingSide = .rival
    @State private var activeRivalGoalkeeperNumber: Int?

    // Reset after every successful record.
    @State private var selectedShooterNumber: Int?
    @State private var originPoint: CourtPoint?
    @State private var isSevenMeters = false
    @State private var selectedOrigin: ShotOrigin?
    @State private var selectedTarget: GoalTarget?
    @State private var delivery: ShotDelivery?
    @State private var approach: ShotApproach?

    @State private var errorMessage: String?
    @State private var lastShotCard: LastShotCardState?
    @State private var lastShotID: PersistentIdentifier?
    @State private var saveHapticTrigger = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            GeometryReader { geo in
                Group {
                    if isThreeColumnLayout(for: geo.size) {
                        threeColumnLayout(availableHeight: geo.size.height)
                    } else {
                        ScrollView {
                            verticalLayout
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding()
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: saveHapticTrigger)
        .task(id: lastShotCard) {
            guard case .removed = lastShotCard else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            lastShotCard = nil
        }
        .onChange(of: attackingSide) { _, newValue in
            // Own-team shots carry no shooter (`Shot.record` would drop one
            // anyway); clearing it here keeps the shooter grid's own
            // selection highlight from pointing at a stale choice.
            if newValue == .own { selectedShooterNumber = nil }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(team.name)
                .font(.title3.bold())
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var headerSubtitle: String {
        let kindText = session.kind.map(sessionKindLabel) ?? "Unknown kind"
        let dateText = session.date.formatted(date: .abbreviated, time: .omitted)
        let count = session.shots.count
        return "\(kindText) · \(dateText) · \(count) shot\(count == 1 ? "" : "s") recorded"
    }

    // MARK: - Layout

    /// See this file's header comment for the full reasoning behind every
    /// term of this condition.
    private func isThreeColumnLayout(for size: CGSize) -> Bool {
        horizontalSizeClass == .regular
            && verticalSizeClass == .regular
            && size.width > size.height
    }

    private func threeColumnLayout(availableHeight: CGFloat) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Shooter").font(.headline)
                shooterContent
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            middleColumn(availableHeight: availableHeight)
                .frame(maxWidth: .infinity, alignment: .top)

            contextPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Portrait iPad and any iPhone orientation: everything in one
    /// scrollable column. The order mirrors the landscape layout's
    /// left-to-right reading order turned top-to-bottom — shooter, then the
    /// vertical goal/court path (§5.2), then the context panel, which ends
    /// with the last-shot card: the outcome of the flow reads last here
    /// too, not just visually to the right.
    private var verticalLayout: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shooter").font(.headline)
                shooterContent
            }

            GoalView(selection: selectedTarget, onTargetTapped: selectTarget)
            CourtView(selection: selectedOrigin, onOriginTapped: selectOrigin)

            contextPanel
        }
        .padding(.bottom, 24)
    }

    @ViewBuilder
    private var shooterContent: some View {
        if attackingSide == .rival {
            ShooterGridColumn(
                players: team.players.map(\.domainPlayer).sorted { $0.number < $1.number },
                selectedNumber: selectedShooterNumber,
                onSelect: { selectedShooterNumber = $0 }
            )
        } else {
            Text("No shooter needed for an own-team attack — the active rival goalkeeper above is who this shot is recorded against.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    /// The ratio `GoalView` really draws with (mouth + frame and out bands),
    /// read from the view itself so the split below cannot drift from it.
    private var goalOverallAspectRatio: Double {
        GoalView(onTargetTapped: { _ in }).overallAspectRatio
    }
    private let middleColumnSpacing: CGFloat = 12

    /// Splits the available height between `GoalView` and `CourtView` so
    /// BOTH end up the same rendered WIDTH. Each view sizes itself from its
    /// own `.aspectRatio(_, contentMode: .fit)`, so handing it height `h`
    /// makes its width come out to `h * aspectRatio` — solving
    /// `goalHeight * goalAspect == courtHeight * courtAspect` for a fixed
    /// total is what keeps the stacked "goal on top, court below" path
    /// (docs/mvp.md §5.2) reading as one column instead of two
    /// differently-sized rectangles side by side in the middle.
    private func middleColumnHeights(for totalHeight: CGFloat) -> (goal: CGFloat, court: CGFloat) {
        let available = max(totalHeight - middleColumnSpacing, 0)
        let courtAspect = CourtGeometry.standard.aspectRatio
        let ratio = goalOverallAspectRatio / courtAspect
        let goalHeight = available / (1 + ratio)
        return (goal: goalHeight, court: available - goalHeight)
    }

    private func middleColumn(availableHeight: CGFloat) -> some View {
        let heights = middleColumnHeights(for: availableHeight)
        return VStack(spacing: middleColumnSpacing) {
            GoalView(selection: selectedTarget, onTargetTapped: selectTarget)
                .frame(height: heights.goal)
            CourtView(selection: selectedOrigin, onOriginTapped: selectOrigin)
                .frame(height: heights.court)
        }
    }

    private var contextPanel: some View {
        ShotEntryContextPanel(
            attackingSide: attackingSide,
            onSelectAttackingSide: { attackingSide = $0 },
            goalkeepers: team.players.filter(\.isGoalkeeper).map(\.domainPlayer).sorted { $0.number < $1.number },
            activeGoalkeeperNumber: activeRivalGoalkeeperNumber,
            onSelectGoalkeeper: { activeRivalGoalkeeperNumber = $0 },
            delivery: delivery,
            onToggleDelivery: toggleDelivery,
            approach: approach,
            onToggleApproach: toggleApproach,
            showsOutcomeQuestion: selectedTarget != nil && selectedTarget?.impliedOutcome == nil,
            onChooseOutcome: { attemptRecord(outcome: $0) },
            errorMessage: errorMessage,
            lastShotCard: lastShotCard,
            onUndo: undoLastShot
        )
    }

    // MARK: - Entry state

    private var selectedShooter: Player? {
        guard let number = selectedShooterNumber else { return nil }
        return team.players.first { $0.number == number }?.domainPlayer
    }

    private var activeRivalGoalkeeper: Player? {
        guard let number = activeRivalGoalkeeperNumber else { return nil }
        return team.players.first { $0.number == number }?.domainPlayer
    }

    private func selectOrigin(_ origin: ShotOrigin, _ point: CourtPoint?) {
        errorMessage = nil
        selectedOrigin = origin
        switch origin {
        case .sevenMeters:
            isSevenMeters = true
            originPoint = nil
        case .zone:
            isSevenMeters = false
            originPoint = point
        }
    }

    private func selectTarget(_ target: GoalTarget) {
        errorMessage = nil
        selectedTarget = target
        // A post or a miss fully resolves the outcome in one tap
        // (`GoalTarget.impliedOutcome`); only an inside target waits for
        // the Goal/Saved buttons in `ShotEntryContextPanel`.
        if let implied = target.impliedOutcome {
            attemptRecord(outcome: implied)
        }
    }

    /// Tap-again-to-clear (T3.3 decision): the container owns the
    /// comparison, the chip only reports which value was tapped.
    private func toggleDelivery(_ value: ShotDelivery) {
        delivery = (delivery == value) ? nil : value
    }

    private func toggleApproach(_ value: ShotApproach) {
        approach = (approach == value) ? nil : value
    }

    // MARK: - Write path

    private func attemptRecord(outcome: ShotOutcome) {
        guard let target = selectedTarget else { return }
        errorMessage = nil

        let shot: Shot
        do {
            shot = try Shot.record(
                attackingSide: attackingSide,
                shooter: selectedShooter,
                activeRivalGoalkeeper: activeRivalGoalkeeper,
                originPoint: originPoint,
                isSevenMeters: isSevenMeters,
                target: target,
                outcome: outcome,
                delivery: delivery,
                approach: approach,
                date: .now
            )
        } catch {
            errorMessage = shotEntryErrorMessage(error)
            return
        }

        persist(shot)
    }

    /// Builds exactly ONE `StoredShot` and touches exactly one row — see
    /// this file's header comment.
    private func persist(_ shot: Shot) {
        let shooterStored = shot.shooter.flatMap { shooter in
            team.players.first { $0.number == shooter.number }
        }
        let goalkeeperStored = shot.facingGoalkeeper.flatMap { goalkeeper in
            team.players.first { $0.number == goalkeeper.number }
        }
        let stored = StoredShot(shot, shooter: shooterStored, facingGoalkeeper: goalkeeperStored)
        session.shots.append(stored)
        modelContext.insert(stored)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn't save this shot (\(error.localizedDescription))."
            return
        }

        lastShotCard = .recorded(text: ShotSummary(shot: shot).text)
        lastShotID = stored.persistentModelID
        saveHapticTrigger.toggle()
        resetEntryState()
    }

    /// Clears everything the flow builds up per shot, keeping the sticky
    /// attacking side and the persistent active goalkeeper (T3.3 decision
    /// ②) untouched.
    private func resetEntryState() {
        selectedShooterNumber = nil
        originPoint = nil
        isSevenMeters = false
        selectedOrigin = nil
        selectedTarget = nil
        delivery = nil
        approach = nil
    }

    // MARK: - Undo

    private func undoLastShot() {
        guard let lastShotID,
              let stored = session.shots.first(where: { $0.persistentModelID == lastShotID })
        else { return }

        // `delete` alone leaves the deleted row in the in-memory
        // `session.shots` array, so the header kept counting it (found by
        // running it: 41 shots shown after undoing the 41st). Leave the
        // relationship first; a failed save rolls both back.
        session.shots.removeAll { $0.persistentModelID == lastShotID }
        modelContext.delete(stored)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn't undo this shot (\(error.localizedDescription))."
            return
        }

        // Cleared BEFORE the card flips to `.removed`, which itself draws
        // no button — see this file's header comment on the two
        // independent guards against a second delete.
        self.lastShotID = nil
        lastShotCard = .removed
    }
}

#Preview("SessionView") {
    let schema = Schema(KeepercentSchema.models)
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: [configuration])
    let team = StoredRivalTeam(name: "CB Handbol Test")
    let session = StoredSession(date: .now, kindCode: SessionKind.live.rawValue, rivalTeam: team)
    team.sessions = [session]
    team.players = [
        StoredPlayer(Player(number: 1, name: "Marta", isGoalkeeper: true, handedness: .left)),
        StoredPlayer(Player(number: 4, name: "Ana", isGoalkeeper: false, handedness: .right)),
        StoredPlayer(Player(number: 7)),
        StoredPlayer(Player(number: 12, name: "Sofía", isGoalkeeper: true, handedness: .right)),
    ]
    container.mainContext.insert(team)

    return NavigationStack {
        SessionView(team: team, session: session)
    }
    .modelContainer(container)
}
