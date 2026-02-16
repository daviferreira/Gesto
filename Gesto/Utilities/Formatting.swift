import Foundation

func formatDuration(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    let hours = total / 3600
    let mins = (total % 3600) / 60
    let secs = total % 60
    if hours > 0 {
        return String(format: "%dh %02dm", hours, mins)
    } else if mins > 0 {
        return String(format: "%dm %02ds", mins, secs)
    }
    return "\(secs)s"
}

func formatInterval(_ seconds: TimeInterval) -> String {
    let total = Int(seconds)
    if total >= 60 {
        let mins = total / 60
        let secs = total % 60
        return secs > 0 ? "\(mins)m \(secs)s" : "\(mins)m"
    }
    return "\(total)s"
}
