// The SwiftData schema for the whole app: every `@Model` type is listed
// here once, so `KeepercentApp` and any future migration plan share a
// single source of truth for what gets persisted. See docs/mvp.md §8.

import SwiftData

enum KeepercentSchema {
    /// Every persisted model type.
    static let models: [any PersistentModel.Type] = [
        StoredRivalTeam.self,
        StoredPlayer.self,
        StoredSession.self,
        StoredShot.self,
        StoredMatchParticipant.self,
        StoredOwnTeam.self,
    ]

    /// The container used by the running app. Additive schema opening and
    /// transactional historical backfill happen before seeding/UI. A store
    /// that fails either step is unrecoverable: crashing loudly at launch
    /// beats silently losing scouting data or running against a container
    /// that never actually persists.
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try MatchHistoryUpgrade.run(in: ModelContext(container))
            return container
        } catch {
            fatalError("Failed to create the SwiftData container: \(error)")
        }
    }
}
