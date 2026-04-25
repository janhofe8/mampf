import Foundation

enum OpeningStatus: Equatable {
    case open, closed, unknown
}

struct OpeningInfo: Equatable {
    let status: OpeningStatus
    /// Minutes until closing if `status == .open`, else nil.
    let minutesUntilClosing: Int?
}

struct OpeningHoursParser {

    static func status(for openingHours: String, at date: Date = .now) -> OpeningStatus {
        let trimmed = openingHours.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .unknown }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        let segments = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ";\n"))
            .map { normalizeUnicode($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        for segment in segments {
            if let result = parseSegment(segment, weekday: weekday, currentMinutes: currentMinutes) {
                return result
            }
        }

        return .unknown
    }

    // MARK: - Segment Parsing

    /// Extracts the time portion if segment's day-part matches `weekday`. Returns nil if segment doesn't match today.
    /// Supports Google format ("Monday: 12:00 - 10:00 PM") and simple format ("Mon-Sun 12:00-22:30" / "Sun closed").
    private static func timePart(for segment: String, weekday: Int) -> String? {
        if let colonIdx = segment.firstIndex(of: ":") {
            let beforeColon = String(segment[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            if dayNumber(beforeColon.lowercased()) != nil {
                guard matchesDay(beforeColon, weekday: weekday) else { return nil }
                return String(segment[segment.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
            }
        }
        if let spaceIdx = segment.firstIndex(of: " ") {
            let firstWord = String(segment[..<spaceIdx])
            if firstWord.allSatisfy({ $0.isLetter || $0 == "-" }) {
                guard matchesDay(firstWord, weekday: weekday) else { return nil }
                return String(segment[segment.index(after: spaceIdx)...]).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private static func parseSegment(_ segment: String, weekday: Int, currentMinutes: Int) -> OpeningStatus? {
        guard let part = timePart(for: segment, weekday: weekday) else { return nil }
        if part.lowercased() == "closed" { return .closed }
        if let (open, close) = parseTimeRange(part) {
            return isTimeInRange(currentMinutes, open: open, close: close) ? .open : .closed
        }
        return .unknown
    }

    // MARK: - Unicode

    private static func normalizeUnicode(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{2009}", with: " ")
         .replacingOccurrences(of: "\u{202F}", with: " ")
         .replacingOccurrences(of: "\u{2013}", with: "-")
         .replacingOccurrences(of: "\u{00A0}", with: " ")
    }

    // MARK: - Day Matching

    private static func matchesDay(_ dayStr: String, weekday: Int) -> Bool {
        let lower = dayStr.lowercased().trimmingCharacters(in: .whitespaces)

        if let day = dayNumber(lower) {
            return day == weekday
        }

        let parts = lower.components(separatedBy: "-")
        if parts.count == 2,
           let start = dayNumber(parts[0].trimmingCharacters(in: .whitespaces)),
           let end = dayNumber(parts[1].trimmingCharacters(in: .whitespaces)) {
            if start <= end {
                return weekday >= start && weekday <= end
            } else {
                return weekday >= start || weekday <= end
            }
        }

        return false
    }

    private static func dayNumber(_ s: String) -> Int? {
        switch s {
        case "sunday", "sun": 1
        case "monday", "mon": 2
        case "tuesday", "tue", "tues": 3
        case "wednesday", "wed": 4
        case "thursday", "thu", "thur", "thurs": 5
        case "friday", "fri": 6
        case "saturday", "sat": 7
        default: nil
        }
    }

    // MARK: - Time Parsing

    private static func parseTimeRange(_ s: String) -> (Int, Int)? {
        let parts = s.components(separatedBy: "-").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return nil }

        let closePM = parts[1].lowercased().contains("pm")
        guard let open = parseTime(parts[0], hintPM: closePM),
              let close = parseTime(parts[1]) else { return nil }

        return (open, close)
    }

    private static func parseTime(_ s: String, hintPM: Bool = false) -> Int? {
        let lower = s.lowercased().trimmingCharacters(in: .whitespaces)
        let isPM = lower.hasSuffix("pm")
        let isAM = lower.hasSuffix("am")

        let timeStr = lower
            .replacingOccurrences(of: "am", with: "")
            .replacingOccurrences(of: "pm", with: "")
            .trimmingCharacters(in: .whitespaces)

        let components = timeStr.components(separatedBy: ":")
        guard components.count == 2,
              var hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }

        if isPM {
            if hour != 12 { hour += 12 }
        } else if isAM {
            if hour == 12 { hour = 0 }
        } else if hintPM && hour < 12 {
            hour += 12
        }

        if hour >= 24 { hour -= 24 }

        return hour * 60 + minute
    }

    private static func isTimeInRange(_ current: Int, open: Int, close: Int) -> Bool {
        if close > open {
            return current >= open && current < close
        } else {
            return current >= open || current < close
        }
    }

    /// Single-pass parse that returns both status and minutes-until-closing.
    /// Use this on hot paths (list rows, cards) to avoid parsing the same string 2-3x per render.
    static func openingInfo(for openingHours: String, at date: Date = .now) -> OpeningInfo {
        let trimmed = openingHours.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return OpeningInfo(status: .unknown, minutesUntilClosing: nil) }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        let segments = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ";\n"))
            .map { normalizeUnicode($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        var status: OpeningStatus = .unknown
        var minutesLeft: Int? = nil

        for segment in segments {
            guard let part = timePart(for: segment, weekday: weekday) else { continue }
            if part.lowercased() == "closed" {
                status = .closed
                break
            }
            if let (open, close) = parseTimeRange(part) {
                if isTimeInRange(currentMinutes, open: open, close: close) {
                    status = .open
                    if close > currentMinutes {
                        minutesLeft = close - currentMinutes
                    } else if close < currentMinutes {
                        minutesLeft = (24 * 60 - currentMinutes) + close
                    }
                    break
                } else {
                    status = .closed
                    // keep scanning — another segment for today may put us inside its range
                }
            }
        }
        return OpeningInfo(status: status, minutesUntilClosing: minutesLeft)
    }

    /// Returns minutes until closing for the current day segment, or nil if unknown/closed.
    static func minutesUntilClosing(for openingHours: String, at date: Date = .now) -> Int? {
        let trimmed = openingHours.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentMinutes = hour * 60 + minute

        let segments = trimmed
            .components(separatedBy: CharacterSet(charactersIn: ";\n"))
            .map { normalizeUnicode($0.trimmingCharacters(in: .whitespaces)) }
            .filter { !$0.isEmpty }

        for segment in segments {
            if let close = parseSegmentClosingTime(segment, weekday: weekday, currentMinutes: currentMinutes) {
                if close > currentMinutes {
                    return close - currentMinutes
                } else if close < currentMinutes {
                    // Wraps past midnight
                    return (24 * 60 - currentMinutes) + close
                }
            }
        }
        return nil
    }

    /// Returns the closing time (in minutes) if the segment matches today and we're currently open.
    private static func parseSegmentClosingTime(_ segment: String, weekday: Int, currentMinutes: Int) -> Int? {
        guard let part = timePart(for: segment, weekday: weekday),
              let (open, close) = parseTimeRange(part),
              isTimeInRange(currentMinutes, open: open, close: close) else { return nil }
        return close
    }
}

// MARK: - Restaurant Extension

extension Restaurant {
    /// Single-pass status + minutes-until-closing. Prefer this over reading
    /// `openingStatus`/`minutesUntilClosing`/`closingSoon` separately on hot paths.
    var openingInfo: OpeningInfo {
        if isClosed { return OpeningInfo(status: .closed, minutesUntilClosing: nil) }
        return OpeningHoursParser.openingInfo(for: openingHours)
    }

    var openingStatus: OpeningStatus {
        if isClosed { return .closed }
        return OpeningHoursParser.status(for: openingHours)
    }

    var isOpenNow: Bool? {
        switch openingStatus {
        case .open: true
        case .closed: false
        case .unknown: nil
        }
    }

    /// Minutes until closing, or nil if closed/unknown.
    var minutesUntilClosing: Int? {
        guard !isClosed else { return nil }
        return OpeningHoursParser.minutesUntilClosing(for: openingHours)
    }

    /// True if open and closing within 30 minutes.
    var closingSoon: Bool {
        guard let minutes = minutesUntilClosing else { return false }
        return minutes > 0 && minutes <= 30
    }
}
