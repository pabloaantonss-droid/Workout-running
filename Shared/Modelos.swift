import Foundation
import SwiftUI
import WidgetKit

struct Ejercicio: Codable, Identifiable, Hashable {
    var id: UUID = UUID()
    var nombre: String
    var seg: Bool
    var valor: Int
    var each: Bool

    var valorTxt: String {
        let base = seg ? "\(valor)s" : "x\(valor)"
        return each ? base + " (each)" : base
    }
}

struct Carrera: Codable, Identifiable, Hashable {
    var id: Int
    var fecha: String
    var nombre: String
    var km: Double
    var seg: Int
    var desnivel: Double
    var pulso: Double?
}

enum Rutinas {
    static let tipos = ["Brazo", "Pecho", "Abdominales", "Pierna", "Hombro & Espalda"]

    static func r(_ n: String, _ v: Int, each: Bool = false) -> Ejercicio {
        return Ejercicio(nombre: n, seg: false, valor: v, each: each)
    }

    static func s(_ n: String, _ v: Int, each: Bool = false) -> Ejercicio {
        return Ejercicio(nombre: n, seg: true, valor: v, each: each)
    }

    static func porDefecto() -> [String: [Ejercicio]] {
        let brazo: [Ejercicio] = [
            s("Círculos con los brazos", 30), s("Saltos sin cuerda", 30), r("Flexión armario", 16, each: true),
            r("Burpees", 16), r("Flexión suelo", 14), r("Puente tríceps", 18), r("Antebrazo", 25),
            s("Puñetazos", 30), r("Fondos militares", 14), r("A volar hombro", 16), r("Puente tríceps", 24),
            r("Antebrazo", 25), s("Puñetazos", 30), r("Burpees", 16), r("Flexión suelo", 12, each: true),
            r("Fondos militares", 12), r("A volar hombro", 16), r("Ventana", 8), s("Plancha-flexión", 30),
            s("Rezo", 18), r("Flexión y rotación", 12)
        ]
        let pecho: [Ejercicio] = [
            s("Saltos de tijera", 30), r("Rotaciones de brazos", 20), s("Estiramiento de hombros", 30),
            r("Burpees", 10), r("Flexiones escalonadas", 16), r("Flexiones hindúes", 15),
            r("Flexión y rotación", 12), r("Flexiones en diamante", 15), r("Flexiones en caja", 12),
            r("Flexiones hindúes", 12), r("Flexiones Spiderman", 20), r("Flexiones pies elevados", 12),
            r("Burpees", 10)
        ]
        let abs: [Ejercicio] = [
            s("Salto tijera", 30), r("Abdominales", 30), r("Puente lateral", 20, each: true),
            r("Crunch abdominales", 30), r("Crunch bicicleta", 24), s("Planchas laterales", 20, each: true),
            r("Elevación en V", 18), r("Flexión y rotación", 24), r("Twist ruso", 48),
            r("Crunch abdominales", 28), r("Butt bridge", 30), r("Toque al talón", 34),
            r("Escaladores", 30), r("Abdominal cruzado", 24), r("Elevación en V", 16), s("Plancha", 60)
        ]
        var pierna: [Ejercicio] = [r("Burpees", 10)]
        for _ in 0..<3 { pierna.append(r("Sentadillas", 14)) }
        for _ in 0..<3 {
            pierna.append(r("Levantamiento pierna izquierda", 12))
            pierna.append(r("Levantamiento pierna derecha", 12))
        }
        for _ in 0..<3 { pierna.append(r("Zancada trasera cruzada", 14)) }
        for _ in 0..<3 {
            pierna.append(r("Círculos pierna izquierda", 12))
            pierna.append(r("Círculos pierna derecha", 12))
        }
        for _ in 0..<3 { pierna.append(r("Sentadillas con salto", 14)) }
        for _ in 0..<3 {
            pierna.append(r("Elevación trasera tiesa izquierda", 12))
            pierna.append(r("Elevación trasera tiesa derecha", 12))
        }
        pierna.append(s("Sentadilla en pared", 40))
        for _ in 0..<3 {
            pierna.append(r("Levantamiento pantorrilla izquierda contra pared", 32))
            pierna.append(r("Levantamiento pantorrilla derecha contra pared", 32))
        }
        let hombro: [Ejercicio] = [
            s("Salto de tijera", 30), r("Hiperextensión", 14), r("Flexiones en pica", 14),
            r("Flexiones inversas", 12), r("Inchworms", 16), s("Estiramiento sobre cada costado", 30, each: true),
            r("Hiperextensión", 12), r("Flexiones en pica", 12), r("Flexiones inversas", 10),
            r("Inchworms", 14), s("Postura gato vaca", 30), r("Flexión supina", 14),
            r("Elevación de Y", 14), r("Flexión supina", 12), r("Ángel de nieve invertido", 12),
            s("Postura del bebé", 30)
        ]
        return [
            "Brazo": brazo,
            "Pecho": pecho,
            "Abdominales": abs,
            "Pierna": pierna,
            "Hombro & Espalda": hombro
        ]
    }
}

struct DatosApp: Codable {
    var rutinas: [String: [Ejercicio]]
    var workouts: [String: [String]]
    var pesos: [String: Double]
    var carreras: [Carrera]

    init() {
        rutinas = Rutinas.porDefecto()
        workouts = [:]
        pesos = [:]
        carreras = []
    }

    enum CodingKeys: String, CodingKey {
        case rutinas, workouts, pesos, carreras
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rutinas = (try? c.decode([String: [Ejercicio]].self, forKey: .rutinas)) ?? Rutinas.porDefecto()
        workouts = (try? c.decode([String: [String]].self, forKey: .workouts)) ?? [:]
        pesos = (try? c.decode([String: Double].self, forKey: .pesos)) ?? [:]
        carreras = (try? c.decode([Carrera].self, forKey: .carreras)) ?? []
    }
}

extension DatosApp {
    var carrerasPorDia: [String: Int] {
        var d: [String: Int] = [:]
        for c in carreras { d[c.fecha, default: 0] += 1 }
        return d
    }

    func inicioSemana(offset: Int) -> Date {
        return Fecha.sumar(Fecha.inicioSemana(Fecha.hoy), dias: -7 * offset)
    }

    func claves(offset: Int) -> [String] {
        let ini = inicioSemana(offset: offset)
        return (0..<7).map { Fecha.clave(Fecha.sumar(ini, dias: $0)) }
    }

    func workoutsSemana(_ offset: Int) -> Int {
        var n = 0
        for k in claves(offset: offset) { n += workouts[k]?.count ?? 0 }
        return n
    }

    func runningSemana(_ offset: Int) -> Int {
        let p = carrerasPorDia
        var n = 0
        for k in claves(offset: offset) { n += p[k] ?? 0 }
        return n
    }

    func porTipo(_ offset: Int) -> [String: Int] {
        var res: [String: Int] = [:]
        for k in claves(offset: offset) {
            for t in workouts[k] ?? [] { res[t, default: 0] += 1 }
        }
        return res
    }
}

final class Almacen: ObservableObject {
    static let compartido = Almacen()

    @Published var datos: DatosApp

    private init() {
        datos = Almacen.cargar()
    }

    static func cargar() -> DatosApp {
        if let d = Cfg.defaults.data(forKey: "datos"),
           let x = try? JSONDecoder().decode(DatosApp.self, from: d) {
            return x
        }
        return DatosApp()
    }

    static func guardarDatos(_ d: DatosApp) {
        if let x = try? JSONEncoder().encode(d) {
            Cfg.defaults.set(x, forKey: "datos")
        }
        WidgetCenter.shared.reloadAllTimelines()
        NotificationCenter.default.post(name: .datosCambiaron, object: nil)
    }

    func guardar() {
        Almacen.guardarDatos(datos)
    }

    func recargar() {
        datos = Almacen.cargar()
    }

    func anadir(_ tipo: String, _ clave: String) {
        datos.workouts[clave, default: []].append(tipo)
        guardar()
    }

    func quitar(_ tipo: String, _ clave: String) {
        guard var l = datos.workouts[clave], let i = l.lastIndex(of: tipo) else { return }
        l.remove(at: i)
        if l.isEmpty {
            datos.workouts[clave] = nil
        } else {
            datos.workouts[clave] = l
        }
        guardar()
    }

    func guardarPeso(_ kg: Double, clave: String) {
        datos.pesos[clave] = kg
        guardar()
    }

    func eliminarPeso(_ clave: String) {
        datos.pesos[clave] = nil
        guardar()
    }

    func guardarEjercicios(_ tipo: String, _ lista: [Ejercicio]) {
        datos.rutinas[tipo] = lista
        guardar()
    }
}
