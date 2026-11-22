import Foundation

struct JournalEntry: Codable, Identifiable, Hashable {
    let id: String
    let body: String
    let createdAt: String
    let updatedAt: String
    let authorId: String
    let authorName: String
}

struct JournalListResponse: Codable {
    let entries: [JournalEntry]
}

struct UpsertJournalRequest: Encodable {
    let body: String
}

struct OkResponse: Codable {
    let ok: Bool?
}
