import Foundation

enum DeviceID {
    nonisolated private static let key = "finestfinder_device_id"

    nonisolated static var current: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    /// Reset the device ID (generates a new one on next access)
    nonisolated static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
