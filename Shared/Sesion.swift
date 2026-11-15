import Foundation
import ActivityKit
import UserNotifications

struct EjercicioAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var indice: Int
        var total: Int
        var nombre: String
        var valor: String
        var siguiente: String
        var temporizado: Bool
        var fin: Date?
        var lado: Int
        var lados: Int
        var completado: Bool
    }
    var rutina: String
}

struct SesionActiva: Codable, Equatable {
    var rutina: String
    var indice: Int = 0
    var lado: Int = 1
    var inicio: Date? = nil
    var acumulado: Double = 0
}

enum Sesion {
    static let clave = "sesion"
    static var fueTerminada = false
    static var terminadaRutina: String? = nil

    static func actual() -> SesionActiva? {
        guard let d = Cfg.defaults.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(SesionActiva.self, from: d)
    }

    static func guardar(_ s: SesionActiva?) {
        if let s = s, let d = try? JSONEncoder().encode(s) {
            Cfg.defaults.set(d, forKey: clave)
        } else {
            Cfg.defaults.removeObject(forKey: clave)
        }
        NotificationCenter.default.post(name: .sesionCambio, object: nil)
    }

    static func ejercicios(_ rutina: String) -> [Ejercicio] {
        return Almacen.cargar().rutinas[rutina] ?? []
    }

    static func transcurrido(_ s: SesionActiva, ahora: Date = Date()) -> Double {
        var t = s.acumulado
        if let i = s.inicio { t += ahora.timeIntervalSince(i) }
        return t
    }

    static func iniciar(_ rutina: String) {
        cancelarAviso()
        fueTerminada = false
        terminadaRutina = nil
        guardar(SesionActiva(rutina: rutina))
    }

    static func cancelar() {
        cancelarAviso()
        guardar(nil)
    }

    static func iniciarCrono() {
        guard var s = actual(), s.inicio == nil else { return }
        s.inicio = Date()
        guardar(s)
        programarAviso(s)
    }

    static func pararCrono() {
        guard var s = actual(), let i = s.inicio else { return }
        s.acumulado += Date().timeIntervalSince(i)
        s.inicio = nil
        guardar(s)
        cancelarAviso()
    }

    static func reiniciarCrono() {
        guard var s = actual() else { return }
        s.inicio = nil
        s.acumulado = 0
        guardar(s)
        cancelarAviso()
    }

    @discardableResult
    static func marcarHecho() -> Bool {
        guard var s = actual() else { return false }
        let lista = ejercicios(s.rutina)
        guard s.indice < lista.count else { return false }
        let e = lista[s.indice]
        cancelarAviso()
        if e.seg && e.each && s.lado == 1 {
            s.lado = 2
            s.inicio = nil
            s.acumulado = 0
            guardar(s)
            return false
        }
        s.indice += 1
        s.lado = 1
        s.inicio = nil
        s.acumulado = 0
        if s.indice >= lista.count {
            terminar(s.rutina)
            return true
        }
        guardar(s)
        return false
    }

    static func terminar(_ rutina: String) {
        var d = Almacen.cargar()
        d.workouts[Fecha.claveHoy(), default: []].append(rutina)
        Almacen.guardarDatos(d)
        terminadaRutina = rutina
        fueTerminada = true
        guardar(nil)
    }

    static func estado(_ s: SesionActiva) -> EjercicioAttributes.ContentState {
        let lista = ejercicios(s.rutina)
        let total = lista.count
        let i = min(s.indice, max(total - 1, 0))
        let e: Ejercicio = lista.isEmpty ? Ejercicio(nombre: "", seg: false, valor: 0, each: false) : lista[i]
        var fin: Date? = nil
        if e.seg, let ini = s.inicio {
            fin = ini.addingTimeInterval(Double(e.valor) - s.acumulado)
        }
        var sig = ""
        if s.indice + 1 < total && !(e.seg && e.each && s.lado == 1) {
            sig = lista[s.indice + 1].nombre
        } else if e.seg && e.each && s.lado == 1 {
            sig = "Cambio de lado"
        }
        let lados = (e.seg && e.each) ? 2 : 1
        return EjercicioAttributes.ContentState(
            indice: s.indice,
            total: total,
            nombre: e.nombre,
            valor: e.valorTxt,
            siguiente: sig,
            temporizado: e.seg,
            fin: fin,
            lado: s.lado,
            lados: lados,
            completado: false
        )
    }

    static func sincronizar() async {
        let acts = Activity<EjercicioAttributes>.activities
        guard let s = actual() else {
            for a in acts {
                if terminadaRutina != nil {
                    let fin = EjercicioAttributes.ContentState(
                        indice: 1, total: 1,
                        nombre: "Entreno completado", valor: "Añadido a hoy",
                        siguiente: "", temporizado: false, fin: nil,
                        lado: 1, lados: 1, completado: true
                    )
                    await a.end(ActivityContent(state: fin, staleDate: nil),
                                dismissalPolicy: .after(Date().addingTimeInterval(30)))
                } else {
                    await a.end(nil, dismissalPolicy: .immediate)
                }
            }
            terminadaRutina = nil
            return
        }
        let contenido = ActivityContent(state: estado(s), staleDate: nil)
        if let a = acts.first {
            await a.update(contenido)
        } else {
            _ = try? Activity<EjercicioAttributes>.request(
                attributes: EjercicioAttributes(rutina: s.rutina),
                content: contenido
            )
        }
    }

    static func programarAviso(_ s: SesionActiva) {
        let lista = ejercicios(s.rutina)
        guard s.indice < lista.count else { return }
        let e = lista[s.indice]
        guard e.seg else { return }
        let restante = Double(e.valor) - s.acumulado
        guard restante > 0 else { return }
        let c = UNMutableNotificationContent()
        c.title = e.nombre
        c.body = "Tiempo cumplido"
        c.sound = UNNotificationSound.default
        let t = UNTimeIntervalNotificationTrigger(timeInterval: restante, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "crono", content: c, trigger: t))
    }

    static func cancelarAviso() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["crono"])
    }
}
