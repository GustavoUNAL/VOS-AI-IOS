import EventKit
import Foundation

@MainActor
final class DeviceCalendarService {
    private let store = EKEventStore()

    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await store.requestFullAccessToEvents()
        } else {
            return try await store.requestAccess(to: .event)
        }
    }

    func export(event: PersonalCalendarEvent) async throws {
        guard try await requestAccess() else {
            throw APIError.forbidden("Sin permiso para el Calendario del iPhone.")
        }
        guard let start = ISO8601DateFormatter.vos.parse(event.startsAt),
              let end = ISO8601DateFormatter.vos.parse(event.endsAt) else {
            throw APIError.badRequest("Fechas del evento inválidas.")
        }
        let ek = EKEvent(eventStore: store)
        ek.title = event.title
        ek.notes = event.notes
        ek.startDate = start
        ek.endDate = end
        ek.isAllDay = event.allDay
        ek.calendar = store.defaultCalendarForNewEvents
        try store.save(ek, span: .thisEvent)
    }
}

extension ISO8601DateFormatter {
    static let vos: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func parse(_ value: String) -> Date? {
        if let d = date(from: value) { return d }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}
