// Turns a thrown KeepercentDomain.ShotEntryError into a message a scout can
// read on screen — the shot-entry equivalent of RosterErrorMessaging.swift
// and SessionMessaging.swift's `sessionErrorMessage`. Kept in exactly one
// place so `SessionView` never has to repeat this wording.
//
// `switch` is exhaustive over `ShotEntryError`, with no `default` case: per
// `ShotEntryError`'s own header comment, typed throws exists precisely so a
// UI can switch exhaustively over every rejection reason, and a `default`
// here would silently swallow a new case instead of failing to compile.

import Foundation
import KeepercentDomain

func shotEntryErrorMessage(_ error: ShotEntryError) -> String {
    switch error {
    case .missingShooter:
        return "Select who took the shot."
    case .missingRivalGoalkeeper:
        return "Select the active rival goalkeeper first."
    case .missingOrigin:
        return "Tap the court to record where the shot was taken from."
    case .missingOutcome:
        return "Choose whether the shot was a goal or saved."
    case .outcomeContradictsTarget:
        return "That outcome doesn't match the selected target."
    }
}
