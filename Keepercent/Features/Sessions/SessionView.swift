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
//   2. Choose origin, target and outcome in any order. A post/miss implies
//      the outcome; incomplete entries remain pending in `ShotEntryProgress`.
//   3. Every required selection checks completeness without saving a draft.
//   4. When complete, `attemptRecord` calls `Shot.record` FIRST (typed `ShotEntryError`,
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
// it. Portrait entry fits the remaining height, with scrolling reserved for
// small windows and accessibility text sizes.
//
// The middle column's own height split between `GoalView` and `CourtView`
// is `middleColumnHeights(for:)` — see its doc comment for why it solves
// for equal rendered WIDTH rather than an arbitrary fraction.
//
// ## Shot log (T3.4)
//
// A toolbar button — `.primaryAction`, next to the title — opens
// `ShotLogView` as a sheet. That is the least disruptive entry point: it
// works identically in both `threeColumnLayout` and `portraitLayout`
// without reshaping either one, unlike adding a fourth column (there is no
// spare width on an iPad Pro 11" — see the layout note above) or a new
// section in `ShotEntryContextPanel` (already the panel that is fullest on
// iPhone, per that file's own scroll). `ShotLogView` owns its own delete
// write (see that file's header); it reports the deleted shot's identity
// through `shotWasDeleted(_:)` below so the ONE-LEVEL UNDO invariant holds
// even when the deleting action happens in a different view: if the log
// deletes the exact shot `lastShotID` names, the card drops its Undo
// (`lastShotCard`/`lastShotID` both cleared) instead of risking a stale
// Undo that would delete a different, still-live shot.

import SwiftUI
import SwiftData
import KeepercentDomain

struct SessionView: View {
    let team: StoredRivalTeam
    let session: StoredSession

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StoredOwnTeam.createdAt) private var ownTeams: [StoredOwnTeam]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // Sticky / persistent across shots (T3.3 decision ②).
    @State private var attackingSide: AttackingSide = .rival
    @State private var activeRivalGoalkeeperNumber: Int?
    @State private var selectedOwnShooterID: UUID?
    @State private var activeOwnGoalkeeperID: UUID?

    // Reset after every successful record.
    @State private var selectedShooterNumber: Int?
    @State private var originPoint: CourtPoint?
    @State private var isSevenMeters = false
    @State private var selectedOrigin: ShotOrigin?
    @State private var selectedTarget: GoalTarget?
    @State private var selectedOutcome: ShotOutcome?
    @State private var delivery: ShotDelivery?
    @State private var approach: ShotApproach?

    @State private var errorMessage: String?
    @State private var lastShotCard: LastShotCardState?
    @State private var lastShotID: PersistentIdentifier?
    @State private var saveHapticTrigger = false
    @State private var undoHapticTrigger = false
    @State private var isShowingHistoryInfo = false
    @State private var isPresentingShotLog = false
    @State private var isPresentingMatchRoster = false
    @State private var rosterDraft: [Player] = []
    @State private var ownRosterDraft: [Player] = []
    @State private var includeOwnTeam = false
    @State private var rosterError: String?

    private var matchPlayers: [Player] {
        session.participants.map(\.domainPlayer).sorted { $0.number < $1.number }
    }

    private var ownMatchPlayers: [Player] {
        session.ownParticipants.map(\.domainPlayer).sorted { $0.number < $1.number }
    }

    private var availableOwnTeam: StoredOwnTeam? { session.ownTeam ?? ownTeams.first }

    var body: some View {
        GeometryReader { geo in
            Group {
                if isThreeColumnLayout(for: geo.size) {
                    threeColumnLayout(availableHeight: geo.size.height)
                } else {
                    portraitLayout
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(12)
        .navigationTitle(team.name)
        .navigationSubtitle(horizontalSizeClass == .compact ? "" : headerSubtitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if horizontalSizeClass == .compact {
                // The system subtitle truncates on a phone ("En directo · 20 sept 20…"),
                // hiding the year and the live shot count; this one may wrap.
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text(team.name).font(.headline).lineLimit(1)
                        Text(headerSubtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    // The navigation bar has a fixed height: keep the header at the default size.
                    .dynamicTypeSize(...DynamicTypeSize.large)
                    .accessibilityElement(children: .combine)
                }
            }
            if session.historyWasBackfilled == true {
                ToolbarItem(placement: .secondaryAction) {
                    Button("Historical roster", systemImage: "info.circle") { isShowingHistoryInfo = true }
                        .popover(isPresented: $isShowingHistoryInfo) {
                            Text("Historical roster uses the player details available when this store was upgraded.")
                                .padding()
                        }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    rosterDraft = matchPlayers
                    ownRosterDraft = ownMatchPlayers
                    includeOwnTeam = session.ownTeam != nil
                    rosterError = nil
                    isPresentingMatchRoster = true
                } label: { Label("Match roster", systemImage: "person.3") }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingShotLog = true
                } label: {
                    Label("Shot Log", systemImage: "list.bullet.rectangle")
                }
            }
        }
        .sheet(isPresented: $isPresentingShotLog) {
            ShotLogView(session: session, onDeletedShot: shotWasDeleted)
        }
        .sheet(isPresented: $isPresentingMatchRoster) {
            MatchRosterSheet(available: team.players.filter { $0.archivedAt == nil }.map(\.domainPlayer),
                             players: $rosterDraft, lockedIDs: Set(matchPlayers.compactMap(\.id)),
                              errorMessage: rosterError, onSave: saveMatchRoster,
                              ownTeamName: availableOwnTeam?.name,
                              ownAvailable: availableOwnTeam?.players.filter { $0.archivedAt == nil }.map(\.domainPlayer) ?? [],
                              includeOwn: $includeOwnTeam, ownPlayers: $ownRosterDraft,
                              ownLockedIDs: Set(ownMatchPlayers.compactMap(\.id)), ownIsAttached: session.ownTeam != nil)
        }
        .sensoryFeedback(.success, trigger: saveHapticTrigger)
        .sensoryFeedback(.error, trigger: errorMessage)
        .sensoryFeedback(.impact(weight: .light), trigger: undoHapticTrigger)
        .task(id: lastShotCard) {
            guard case .removed = lastShotCard else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            lastShotCard = nil
        }
        .onChange(of: attackingSide) { _, newValue in
            // Entry requirements change with the side; the previous error is stale.
            errorMessage = nil
            // Own-team shots carry no shooter (`Shot.record` would drop one
            // anyway); clearing it here keeps the shooter grid's own
            // selection highlight from pointing at a stale choice.
            if newValue == .own { selectedShooterNumber = nil }
            selectedOwnShooterID = nil
            activeOwnGoalkeeperID = nil
            attemptRecord()
        }
    }

    // MARK: - Header

    private var headerSubtitle: String {
        let kindText = session.kind.map(sessionKindLabel) ?? String(localized: "Unknown kind")
        let dateText = session.date.formatted(date: horizontalSizeClass == .compact ? .numeric : .abbreviated, time: .omitted)
        let count = session.shots.count
        return String(localized: "\(kindText) · \(dateText) · \(count) shots recorded")
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
                SectionTitle("Shooter")
                shooterContent(compact: false)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            middleColumn(availableHeight: availableHeight)
                .frame(maxWidth: .infinity, alignment: .top)

            contextPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Fit the drawings to the space left by participants, two player rows
    /// and the constant bottom inset. Only constrained windows/text sizes scroll.
    private var portraitLayout: some View {
        GeometryReader { proxy in
            let drawingHeight = proxy.size.height - 44 - 94 - 16
            if drawingHeight >= 220 && !dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 8) {
                    contextPanel.participants
                    shooterContent(compact: true)
                    middleColumn(availableHeight: drawingHeight)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        contextPanel.participants
                        shooterContent(compact: true)
                        middleColumn(availableHeight: max(300, proxy.size.width / goalOverallAspectRatio
                            + proxy.size.width / CourtGeometry.standard.aspectRatio + middleColumnSpacing))
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 8) { contextPanel.feedback }
    }

    @ViewBuilder
    private func shooterContent(compact: Bool) -> some View {
        if attackingSide == .rival {
            ShooterGridColumn(
                players: matchPlayers,
                selectedNumber: selectedShooterNumber,
                onSelect: {
                    beginEntry()
                    selectedShooterNumber = $0
                    attemptRecord()
                },
                isCompact: compact
            )
            .accessibilityLabel("Shooter")
        } else {
            ShooterGridColumn(players: ownMatchPlayers,
                selectedNumber: ownMatchPlayers.first { $0.id == selectedOwnShooterID }?.number,
                onSelect: { number in
                    beginEntry()
                    let id = ownMatchPlayers.first { $0.number == number }?.id
                    selectedOwnShooterID = selectedOwnShooterID == id ? nil : id
                }, isCompact: compact)
                .accessibilityLabel("Own Shooter (optional)")
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
            GoalView(selection: selectedTarget, showsPostControl: false, selectionColor: Palette.brandAmber,
                     onTargetTapped: selectTarget)
                .frame(height: heights.goal)
            CourtView(selection: selectedOrigin, selectionColor: Palette.brandAmber, onOriginTapped: selectOrigin)
                .frame(height: heights.court)
        }
    }

    private var contextPanel: ShotEntryContextPanel {
        ShotEntryContextPanel(
            attackingSide: attackingSide,
            onSelectAttackingSide: { beginEntry(); attackingSide = $0 },
            goalkeepers: matchPlayers.filter(\.isGoalkeeper),
            activeGoalkeeperNumber: activeRivalGoalkeeperNumber,
            onSelectGoalkeeper: {
                beginEntry()
                activeRivalGoalkeeperNumber = $0
                attemptRecord()
            },
            delivery: delivery,
            onToggleDelivery: toggleDelivery,
            approach: approach,
            onToggleApproach: toggleApproach,
            progress: entryProgress,
            selectedOutcome: selectedOutcome,
            target: selectedTarget,
            onChooseOutcome: {
                beginEntry()
                selectedOutcome = $0
                attemptRecord()
            },
            errorMessage: errorMessage,
            lastShotCard: lastShotCard,
            onUndo: undoLastShot,
            ownGoalkeepers: ownMatchPlayers.filter(\.isGoalkeeper),
            ownGoalkeeperID: activeOwnGoalkeeperID,
            onSelectOwnGoalkeeper: { beginEntry(); activeOwnGoalkeeperID = $0 }
        )
    }

    // MARK: - Entry state

    private var selectedShooter: Player? {
        guard let number = selectedShooterNumber else { return nil }
        return matchPlayers.first { $0.number == number }
    }

    private var activeRivalGoalkeeper: Player? {
        guard let number = activeRivalGoalkeeperNumber else { return nil }
        return matchPlayers.first { $0.number == number }
    }

    private var entryProgress: ShotEntryProgress {
        ShotEntryProgress(attackingSide: attackingSide, shooter: selectedShooter,
            activeRivalGoalkeeper: activeRivalGoalkeeper, originPoint: originPoint,
            isSevenMeters: isSevenMeters, target: selectedTarget, outcome: selectedOutcome)
    }

    private func selectOrigin(_ origin: ShotOrigin, _ point: CourtPoint?) {
        beginEntry()
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
        attemptRecord()
    }

    private func selectTarget(_ target: GoalTarget) {
        beginEntry()
        errorMessage = nil
        selectedTarget = target
        // Implied outcomes belong to the target, never to a stale explicit
        // Goal/Saved choice when the user changes a pending target.
        if target.impliedOutcome != nil { selectedOutcome = nil }
        attemptRecord()
    }

    /// Tap-again-to-clear (T3.3 decision): the container owns the
    /// comparison, the chip only reports which value was tapped.
    private func toggleDelivery(_ value: ShotDelivery) {
        beginEntry()
        delivery = (delivery == value) ? nil : value
    }

    private func toggleApproach(_ value: ShotApproach) {
        beginEntry()
        approach = (approach == value) ? nil : value
    }

    // MARK: - Write path

    private func beginEntry() {
        errorMessage = nil
        lastShotCard = nil
        lastShotID = nil
    }

    private func attemptRecord() {
        let progress = entryProgress
        guard progress.isComplete, let target = selectedTarget,
              let outcome = progress.resolvedOutcome else {
            errorMessage = progress.missingSteps == [.rivalGoalkeeper]
                ? shotEntryErrorMessage(ShotEntryError.missingRivalGoalkeeper) : nil
            return
        }
        errorMessage = nil

        let shot: Shot
        do {
            shot = try Shot.record(
                attackingSide: attackingSide,
                shooter: selectedShooter,
                activeRivalGoalkeeper: activeRivalGoalkeeper,
                ownShooter: ownMatchPlayers.first { $0.id == selectedOwnShooterID },
                ownGoalkeeper: ownMatchPlayers.first { $0.id == activeOwnGoalkeeperID },
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
            team.players.first { $0.personID == shooter.id }
        }
        let goalkeeperStored = shot.facingGoalkeeper.flatMap { goalkeeper in
            team.players.first { $0.personID == goalkeeper.id }
        }
        let ownShooterStored = shot.ownShooter.flatMap { player in session.ownTeam?.players.first { $0.personID == player.id } }
        let ownKeeperStored = shot.ownGoalkeeper.flatMap { player in session.ownTeam?.players.first { $0.personID == player.id } }
        let stored = StoredShot(shot, shooter: shooterStored, facingGoalkeeper: goalkeeperStored,
                                ownShooter: ownShooterStored, ownGoalkeeper: ownKeeperStored)
        stored.shooterSnapshot = session.participants.first { $0.personID == shot.shooter?.id }
        stored.goalkeeperSnapshot = session.participants.first { $0.personID == shot.facingGoalkeeper?.id }
        stored.ownShooterSnapshot = session.ownParticipants.first { $0.personID == shot.ownShooter?.id }
        stored.ownGoalkeeperSnapshot = session.ownParticipants.first { $0.personID == shot.ownGoalkeeper?.id }
        session.shots.append(stored)
        modelContext.insert(stored)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            errorMessage = String(localized: "Couldn't save this shot (\(error.localizedDescription)).")
            return
        }

        lastShotCard = .recorded(text: ShotSummary(shot: shot).text)
        AccessibilityNotification.Announcement(String(localized: "Shot recorded") + ". " + ShotSummary(shot: shot).text).post()
        lastShotID = stored.persistentModelID
        saveHapticTrigger.toggle()
        resetEntryState()
    }

    /// Clears everything the flow builds up per shot, keeping the sticky
    /// attacking side and the persistent active goalkeeper (T3.3 decision
    /// ②) untouched.
    private func resetEntryState() {
        selectedShooterNumber = nil
        selectedOwnShooterID = nil
        originPoint = nil
        isSevenMeters = false
        selectedOrigin = nil
        selectedTarget = nil
        selectedOutcome = nil
        delivery = nil
        approach = nil
    }

    // MARK: - Undo

    private func saveMatchRoster() {
        do {
            let validated = try MatchRoster(players: rosterDraft)
            // Validate each side before either graph is mutated. Opposing teams
            // may use the same number; duplicates within either side reject.
            let ownValidated = try MatchRoster(players: includeOwnTeam ? ownRosterDraft : [])
            for player in validated.players where !session.participants.contains(where: { $0.personID == player.id }) {
                let snapshot = StoredMatchParticipant(player)
                modelContext.insert(snapshot)
                session.participants.append(snapshot)
            }
            if includeOwnTeam, let ownTeam = availableOwnTeam {
                session.ownTeam = ownTeam
                for player in ownValidated.players where !session.ownParticipants.contains(where: { $0.personID == player.id }) {
                    let snapshot = StoredMatchParticipant(player)
                    modelContext.insert(snapshot)
                    session.ownParticipants.append(snapshot)
                }
            }
            try modelContext.save()
            selectedShooterNumber = nil
            selectedOwnShooterID = nil
            activeOwnGoalkeeperID = nil
            isPresentingMatchRoster = false
        } catch {
            modelContext.rollback()
            rosterError = rosterErrorMessage(error)
        }
    }

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
            errorMessage = String(localized: "Couldn't undo this shot (\(error.localizedDescription)).")
            return
        }

        // Cleared BEFORE the card flips to `.removed`, which itself draws
        // no button — see this file's header comment on the two
        // independent guards against a second delete.
        self.lastShotID = nil
        lastShotCard = .removed
        undoHapticTrigger.toggle()
        AccessibilityNotification.Announcement(String(localized: "Shot removed")).post()
    }

    /// Called by `ShotLogView` after it deletes a shot (see this file's
    /// header, "Shot log (T3.4)"). Identity-safe by construction: it only
    /// clears the card when `deletedID` is the exact id the card echoes —
    /// deleting any OTHER shot from the log leaves `lastShotID` and
    /// `lastShotCard` untouched, so Undo keeps pointing at the same still-
    /// live shot it always did.
    private func shotWasDeleted(_ deletedID: PersistentIdentifier) {
        guard deletedID == lastShotID else { return }
        lastShotID = nil
        lastShotCard = nil
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
    session.participants = team.players.map { StoredMatchParticipant($0.domainPlayer) }
    container.mainContext.insert(team)

    return NavigationStack {
        SessionView(team: team, session: session)
    }
    .modelContainer(container)
}
