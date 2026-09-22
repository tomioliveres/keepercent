// Turns a KeepercentDomain.SessionKind into a UI label, and a thrown
// SessionError into a message a scout can read on screen — the session
// equivalent of RosterErrorMessaging.swift (Features/Teams). Kept in
// exactly one place so NewSessionSheet, SessionRowView and SessionView
// never drift from each other's wording, and so `.live`/`.video` never
// leak onto screen as raw enum case names.

import Foundation
import KeepercentDomain

func sessionKindLabel(_ kind: SessionKind) -> String {
    switch kind {
    case .live:
        return "Live"
    case .video:
        return "Video"
    }
}

func sessionErrorMessage(_ error: Error) -> String {
    switch error {
    case SessionError.matchDateInFuture:
        return "The match date can't be in the future."
    default:
        return error.localizedDescription
    }
}
