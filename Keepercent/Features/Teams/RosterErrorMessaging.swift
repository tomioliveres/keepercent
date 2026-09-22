// Turns a thrown KeepercentDomain error into a message a scout can read on
// screen, reading straight from that error's own payload — this task
// (T3.1) explicitly forbids hardcoding "1 to 99" or a shot count in a UI
// string when the error already carries the real numbers
// (`RosterError.numberOutOfRange`'s `allowedRange`,
// `.playerHasRecordedShots`'s `shotCount`). Both `RosterEditorView` and
// `TeamsView` funnel every domain error through this one function, so the
// wording is defined in exactly one place instead of drifting between the
// roster editor, the "+" tile sheet and the new-team sheet.

import Foundation
import KeepercentDomain

func rosterErrorMessage(_ error: Error) -> String {
    switch error {
    case let RosterError.duplicateNumber(number):
        return "#\(number) is already used by another player on this roster."
    case let RosterError.numberOutOfRange(number, allowedRange):
        return "#\(number) is outside the allowed range (\(allowedRange.lowerBound)–\(allowedRange.upperBound))."
    case let RosterError.playerHasRecordedShots(number, shotCount):
        return "#\(number) has \(shotCount) recorded shot\(shotCount == 1 ? "" : "s") and can't be removed."
    case let RosterError.playerNotFound(number):
        return "#\(number) is no longer on this roster."
    case RivalTeamError.blankName:
        return "Team name can't be empty."
    default:
        return error.localizedDescription
    }
}
