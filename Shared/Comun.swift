import Foundation
import SwiftUI

extension Notification.Name {
    static let sesionCambio = Notification.Name("deporte.sesionCambio")
    static let datosCambiaron = Notification.Name("deporte.datosCambiaron")
    static let abrirPestana = Notification.Name("deporte.abrirPestana")
}

enum Cfg {
    static let grupoPorDefecto = "group.com.pablo.deporte"

    static func grupoDe(_ d: [String: Any]?) -> String? {
        guard let lista = d?["ALTAppGroups"] as? [String] else { return nil }
        return lista.first
    }

    static var grupoID: String {
        if let g = grupoDe(Bundle.main.infoDictionary) { return g }
        let padre = Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Info.plist")
        if let d = NSDictionary(contentsOf: padre) as? [String: Any], let g = grupoDe(d) { return g }
        return grupoPorDefecto
    }

    static var defaults: UserDefaults {
        return UserDefaults(suiteName: grupoID) ?? UserDefaults.standard
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
    static let oro = Color(hex: 0xFFC400)
    static let oroOscuro = Color(hex: 0x6B5F2A)
    static let azul = Color(hex: 0x4CC9F0)
    static let rojo = Color(hex: 0xFF5252)
    static let tarjeta = Color(hex: 0x2B2D31)
    static let fondoApp = Color(hex: 0x111214)
}

enum Fecha {
    static var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.locale = Locale(identifier: "es_ES")
        return c
    }

    private static let fClave: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let fCorta: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "d MMM"
        return f
    }()

    private static let fMes: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "MMM"
        return f
    }()

    private static let fLarga: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "EEE d MMM"
        return f
    }()

    private static let fMesAnio: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_ES")
        f.dateFormat = "LLLL yyyy"
        return f
    }()

    static func nombreMes(_ d: Date) -> String { return fMesAnio.string(from: d).capitalized }

    static func primerDiaMes(offset: Int) -> Date {
        let c = cal
        let comps = c.dateComponents([.year, .month], from: Date())
        let ini = c.date(from: comps) ?? hoy
        return c.date(byAdding: .month, value: offset, to: ini) ?? ini
    }

    static var hoy: Date { return cal.startOfDay(for: Date()) }

    static func clave(_ d: Date) -> String { return fClave.string(from: d) }
    static func claveHoy() -> String { return clave(Date()) }
    static func fecha(_ k: String) -> Date? { return fClave.date(from: k) }

    static func inicioSemana(_ d: Date) -> Date {
        let c = cal
        let dia = c.startOfDay(for: d)
        let wd = c.component(.weekday, from: dia)
        let delta = (wd + 5) % 7
        return c.date(byAdding: .day, value: -delta, to: dia) ?? dia
    }

    static func sumar(_ d: Date, dias: Int) -> Date {
        return cal.date(byAdding: .day, value: dias, to: d) ?? d
    }

    static func corta(_ d: Date) -> String { return fCorta.string(from: d) }
    static func mes(_ d: Date) -> String { return fMes.string(from: d) }

    static func cortaClave(_ k: String) -> String {
        guard let d = fecha(k) else { return k }
        return corta(d)
    }

    static func largaClave(_ k: String) -> String {
        guard let d = fecha(k) else { return k }
        return fLarga.string(from: d)
    }

    static func textoSemana() -> String {
        let ini = inicioSemana(hoy)
        let fin = sumar(ini, dias: 6)
        let d1 = cal.component(.day, from: ini)
        let d2 = cal.component(.day, from: fin)
        if cal.component(.month, from: ini) == cal.component(.month, from: fin) {
            return "Semana del \(d1) al \(d2)"
        }
        return "Semana del \(corta(ini)) al \(corta(fin))"
    }

    static func mmss(_ x: Double) -> String {
        let n = Int(max(0, x))
        return String(format: "%d:%02d", n / 60, n % 60)
    }

    static func hms(_ seg: Int) -> String {
        let h = seg / 3600
        let m = (seg % 3600) / 60
        let s = seg % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}
