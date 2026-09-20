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
    ]

    /// The container used by the running app. A hackathon MVP has no
    /// migration story yet, so a store that fails to open (corrupt file,
    /// incompatible schema) is unrecoverable: crashing loudly at launch
    /// beats silently losing scouting data or running against a container
    /// that never actually persists.
    static func makeContainer() -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create the SwiftData container: \(error)")
        }
    }
}
