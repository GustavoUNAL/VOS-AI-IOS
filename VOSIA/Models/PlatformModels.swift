import Foundation

struct PlatformCompany: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    let status: String?
    let plan: String?
    let membersCount: Int?
    let modules: [PlatformModuleRef]

    struct PlatformModuleRef: Codable, Hashable {
        let slug: String
        let name: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slug, status, plan, membersCount, modules
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
        status = try c.decodeIfPresent(String.self, forKey: .status)
        plan = try c.decodeIfPresent(String.self, forKey: .plan)
        membersCount = try c.decodeIfPresent(Int.self, forKey: .membersCount)
        modules = try c.decodeIfPresent([PlatformModuleRef].self, forKey: .modules) ?? []
    }

    var asCompanySummary: CompanySummary {
        CompanySummary(
            id: id,
            name: name,
            slug: slug,
            role: "platform-admin",
            modules: modules.map(\.slug),
            businessType: nil
        )
    }
}
