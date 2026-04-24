import SwiftUI

/// Cycles through example query strings every 4 seconds while the field is empty and unfocused.
/// Pauses when the user types or focuses the field so the current hint stays stable.
@Observable
final class RotatingPlaceholder {
    private(set) var current: String
    private let examples: [String]
    private var index = 0
    private var task: Task<Void, Never>?

    init(examples: [String]) {
        self.examples = examples.isEmpty ? ["Search"] : examples
        self.current = self.examples[0]
    }

    func start() {
        guard task == nil else { return }
        task = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                if Task.isCancelled { return }
                self.index = (self.index + 1) % self.examples.count
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.current = self.examples[self.index]
                }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
