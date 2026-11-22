import Foundation

enum AppModule: String, CaseIterable, Identifiable, Hashable {
    case aura
    case journal
    case ideas
    case financePersonal = "finance-personal"
    case time
    case calendarPersonal = "calendar-personal"
    case wellness
    case operations
    case products
    case recipes
    case inventory
    case sales
    case pos
    case shop
    case purchases
    case cashClose = "cash-close"
    case staff
    case tasks
    case projects
    case booking
    case analytics
    case account

    var id: String { rawValue }

    var title: String {
        switch self {
        case .aura: return "Aura"
        case .journal: return "Notas"
        case .ideas: return "Ideas"
        case .financePersonal: return "Dinero"
        case .time: return "Pendientes"
        case .calendarPersonal: return "Agenda"
        case .wellness: return "Bienestar"
        case .operations: return "Operación"
        case .products: return "Catálogo"
        case .recipes: return "Recetas"
        case .inventory: return "Stock"
        case .sales: return "Ventas"
        case .pos: return "Punto de venta"
        case .shop: return "Tienda"
        case .purchases: return "Compras"
        case .cashClose: return "Cierre del día"
        case .staff: return "Personal"
        case .tasks: return "Pendientes"
        case .projects: return "Proyectos"
        case .booking: return "Agenda"
        case .analytics: return "Dinero"
        case .account: return "Cuenta"
        }
    }

    var subtitle: String {
        switch self {
        case .aura: return "Tu agente · habla cuando vos quieras"
        case .journal: return "Escribí y se guarda solo"
        case .ideas: return "Vault de ideas"
        case .financePersonal: return "Movimientos y presupuestos"
        case .time: return "Lo de hoy"
        case .calendarPersonal: return "Citas y eventos"
        case .wellness: return "Ánimo, salud y vínculos"
        case .projects: return "Obras y seguimiento"
        case .tasks: return "Pendientes del equipo"
        case .operations: return "Pulso del día"
        case .analytics: return "Cobros y números"
        case .booking: return "Citas y visitas"
        case .staff: return "Equipo"
        default: return ""
        }
    }

    var systemImage: String {
        switch self {
        case .aura: return "sparkles"
        case .journal: return "note.text"
        case .ideas: return "lightbulb.max"
        case .financePersonal: return "banknote"
        case .time: return "checklist"
        case .calendarPersonal: return "calendar"
        case .wellness: return "heart.circle"
        case .operations: return "chart.bar"
        case .products: return "square.grid.2x2"
        case .recipes: return "list.bullet.clipboard"
        case .inventory: return "shippingbox"
        case .sales: return "cart"
        case .pos: return "storefront"
        case .shop: return "bag"
        case .purchases: return "tray.and.arrow.down"
        case .cashClose: return "moon.stars"
        case .staff: return "person.2"
        case .tasks: return "checklist"
        case .projects: return "folder"
        case .booking: return "calendar.badge.clock"
        case .analytics: return "chart.xyaxis.line"
        case .account: return "person.crop.circle"
        }
    }

    var isNativeReady: Bool {
        switch self {
        case .aura, .journal, .ideas, .financePersonal, .time, .calendarPersonal,
             .wellness, .operations, .account, .tasks, .projects, .analytics:
            return true
        default:
            return false
        }
    }

    static func activeBusinessType(_ user: AuthUser?) -> String? {
        user?.companies
            .first(where: { $0.id == user?.companyId })?
            .businessType?
            .lowercased()
    }

    static func isPersonalCompany(_ user: AuthUser?) -> Bool {
        let businessType = activeBusinessType(user)
        return businessType == "personal"
            || user?.companyId == "seed-main"
            || (user?.companySlug.lowercased() == "main")
            || (user?.companyName.lowercased() == "main")
    }

    /// El electricista y negocios de servicios/energía.
    static func isServiceCompany(_ user: AuthUser?) -> Bool {
        let businessType = activeBusinessType(user)
        let slug = user?.companySlug.lowercased() ?? ""
        let name = user?.companyName.lowercased() ?? ""
        return businessType == "services"
            || businessType == "energy"
            || user?.companyId == "seed-el-electricista"
            || slug.contains("electricista")
            || name.contains("electricista")
    }

    /// Secuencia Main alineada a la web: 01 Aura → 06 Dinero.
    static func personalSequence() -> [AppModule] {
        [
            .aura,
            .journal,
            .time,
            .calendarPersonal,
            .projects,
            .financePersonal,
        ]
    }

    static func launcher(for user: AuthUser?) -> [AppModule] {
        if isPersonalCompany(user) {
            return personalSequence()
        }

        let permissions = Set(user?.permissions ?? [])
        let companyModules = Set(
            user?.companies.first(where: { $0.id == user?.companyId })?.modules ?? []
        )
        let isAdmin = user?.isPlatformAdmin == true || permissions.contains("platform.admin")
        func can(_ needles: String...) -> Bool {
            if isAdmin { return true }
            return needles.contains { needle in
                permissions.contains { $0 == needle || $0.hasPrefix(needle) }
            }
        }
        func hasModule(_ slug: String) -> Bool {
            companyModules.isEmpty || companyModules.contains(slug) || isAdmin
        }

        if isServiceCompany(user) {
            var apps: [AppModule] = []
            if hasModule("projects"), can("projects.", "projects.view") { apps.append(.projects) }
            if hasModule("tasks"), can("tasks.", "tasks.view") { apps.append(.tasks) }
            apps.append(.operations)
            if hasModule("finance"), can("finance.", "finance.view") { apps.append(.analytics) }
            if hasModule("booking"), can("booking.", "booking.view") { apps.append(.booking) }
            if hasModule("staff"), can("staff.", "staff.view") { apps.append(.staff) }
            apps.append(contentsOf: [.journal, .account])
            return apps
        }

        var apps: [AppModule] = [.journal, .operations]
        if can("products.", "products.view") { apps.append(.products) }
        if can("inventory.", "inventory.view") { apps.append(contentsOf: [.recipes, .inventory]) }
        if can("sales.", "sales.view") { apps.append(contentsOf: [.sales, .pos, .shop, .cashClose]) }
        if can("purchases.", "purchases.view") { apps.append(.purchases) }
        if can("staff.", "staff.view") { apps.append(.staff) }
        if can("tasks.", "tasks.view") { apps.append(.tasks) }
        if can("projects.", "projects.view") { apps.append(.projects) }
        if can("booking.", "booking.view") { apps.append(.booking) }
        if can("finance.", "finance.view") { apps.append(.analytics) }
        apps.append(.account)
        return apps
    }
}
