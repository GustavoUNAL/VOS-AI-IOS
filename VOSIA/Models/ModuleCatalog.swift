import Foundation

enum AppModule: String, CaseIterable, Identifiable, Hashable {
    case assistant
    case journal
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
        case .assistant: return "Asistente"
        case .journal: return "Diario"
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
        case .tasks: return "Tareas"
        case .projects: return "Proyectos"
        case .booking: return "Agenda"
        case .analytics: return "Finanzas"
        case .account: return "Cuenta"
        }
    }

    var systemImage: String {
        switch self {
        case .assistant: return "bubble.left.and.bubble.right"
        case .journal: return "book"
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
        case .booking: return "calendar"
        case .analytics: return "chart.xyaxis.line"
        case .account: return "person.crop.circle"
        }
    }

    var isNativeReady: Bool {
        switch self {
        case .assistant, .journal, .operations, .account:
            return true
        default:
            return false
        }
    }

    static func launcher(for user: AuthUser?) -> [AppModule] {
        let permissions = Set(user?.permissions ?? [])
        let isAdmin = user?.isPlatformAdmin == true
            || permissions.contains("platform.admin")

        func can(_ needles: String...) -> Bool {
            if isAdmin { return true }
            return needles.contains { needle in
                permissions.contains { $0 == needle || $0.hasPrefix(needle) }
            }
        }

        var apps: [AppModule] = [.assistant, .journal, .operations]
        if can("products.", "products.view") { apps.append(.products) }
        if can("inventory.", "inventory.view") {
            apps.append(contentsOf: [.recipes, .inventory])
        }
        if can("sales.", "sales.view") {
            apps.append(contentsOf: [.sales, .pos, .shop, .cashClose])
        }
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
