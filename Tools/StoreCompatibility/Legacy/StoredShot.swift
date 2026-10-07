import Foundation
import SwiftData

// Frozen schema from 8f2c1b44b21a1cf3f1876ed656d4bbe971d592b3.
@Model
final class StoredShot {
    var date: Date
    var attackingSideCode: String
    var originX: Double?
    var originY: Double?
    var isSevenMeters: Bool
    var targetCode: String
    var outcomeCode: String
    var deliveryCode: String?
    var approachCode: String?
    var shooter: StoredPlayer?
    var facingGoalkeeper: StoredPlayer?

    init(date: Date, attackingSideCode: String, originX: Double?, originY: Double?, isSevenMeters: Bool, targetCode: String, outcomeCode: String, deliveryCode: String?, approachCode: String?, shooter: StoredPlayer?, facingGoalkeeper: StoredPlayer?) {
        self.date = date
        self.attackingSideCode = attackingSideCode
        self.originX = originX
        self.originY = originY
        self.isSevenMeters = isSevenMeters
        self.targetCode = targetCode
        self.outcomeCode = outcomeCode
        self.deliveryCode = deliveryCode
        self.approachCode = approachCode
        self.shooter = shooter
        self.facingGoalkeeper = facingGoalkeeper
    }
}
