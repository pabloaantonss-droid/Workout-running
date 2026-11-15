import Foundation
import ActivityKit
import AppIntents

struct EjercicioAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var indice: Int
        var total: Int
        var nombre: String
    }
    var rutina: String
}

let ejerciciosPrueba = ["Burpees x10", "Flexiones x15", "Plancha 30s", "Sentadillas x14"]

struct TickIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Hecho"

    init() {}

    func perform() async throws -> some IntentResult {
        for act in Activity<EjercicioAttributes>.activities {
            let s = act.content.state
            let siguiente = s.indice + 1
            if siguiente >= s.total {
                let fin = EjercicioAttributes.ContentState(indice: s.total, total: s.total, nombre: "Entreno completado")
                await act.end(ActivityContent(state: fin, staleDate: nil), dismissalPolicy: .default)
            } else {
                let nuevo = EjercicioAttributes.ContentState(indice: siguiente, total: s.total, nombre: ejerciciosPrueba[siguiente])
                await act.update(ActivityContent(state: nuevo, staleDate: nil))
            }
        }
        return .result()
    }
}

struct AbrirAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir Deporte"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Pestana")
    var pestana: String

    init() {}
    init(pestana: String) { self.pestana = pestana }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(pestana, forKey: "pestana")
        return .result()
    }
}
