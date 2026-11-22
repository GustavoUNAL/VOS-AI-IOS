import Foundation

struct CompanySummary: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let slug: String
    let role: String
    let modules: [String]
    let businessType: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, role, modules, businessType
    }

    init(
        id: String,
        name: String,
        slug: String,
        role: String = "",
        modules: [String] = [],
        businessType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.role = role
        self.modules = modules
        self.businessType = businessType
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
        role = try c.decodeIfPresent(String.self, forKey: .role) ?? ""
        modules = try c.decodeIfPresent([String].self, forKey: .modules) ?? []
        businessType = try c.decodeIfPresent(String.self, forKey: .businessType)
    }
}

struct AuthUser: Codable, Hashable {
    let sub: String
    let email: String
    let name: String
    let role: String
    let companyId: String
    let companyName: String
    let companySlug: String
    let isPlatformAdmin: Bool?
    let platformView: Bool?
    let permissions: [String]?
    let companies: [CompanySummary]
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case sub, email, name, role, companyId, companyName, companySlug
        case isPlatformAdmin, platformView, permissions, companies, avatarUrl
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        sub = try c.decode(String.self, forKey: .sub)
        email = try c.decode(String.self, forKey: .email)
        name = try c.decode(String.self, forKey: .name)
        role = try c.decodeIfPresent(String.self, forKey: .role) ?? ""
        companyId = try c.decodeIfPresent(String.self, forKey: .companyId) ?? ""
        companyName = try c.decodeIfPresent(String.self, forKey: .companyName) ?? ""
        companySlug = try c.decodeIfPresent(String.self, forKey: .companySlug) ?? ""
        isPlatformAdmin = try c.decodeIfPresent(Bool.self, forKey: .isPlatformAdmin)
        platformView = try c.decodeIfPresent(Bool.self, forKey: .platformView)
        permissions = try c.decodeIfPresent([String].self, forKey: .permissions)
        companies = try c.decodeIfPresent([CompanySummary].self, forKey: .companies) ?? []
        avatarUrl = try c.decodeIfPresent(String.self, forKey: .avatarUrl)
    }

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var activeCompanyId: String? {
        let trimmed = companyId.trimmingCharacters(in: .whitespacesAndNewlines)
        if isPlatformAdmin == true, platformView == true { return nil }
        return trimmed.isEmpty ? nil : trimmed
    }

    var needsCompanySelection: Bool {
        activeCompanyId == nil && !companies.isEmpty
    }
}

struct LoginResponse: Codable {
    let accessToken: String
    let user: AuthUser
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
    let companyId: String?
}

struct SwitchCompanyRequest: Encodable {
    let companyId: String
}
