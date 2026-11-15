import Foundation
import AppIntents

struct TickIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Hecho"

    init() {}

    func perform() async throws -> some IntentResult {
        Sesion.marcarHecho()
        await Sesion.sincronizar()
        return .result()
    }
}

struct PlayIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Iniciar cuenta atras"

    init() {}

    func perform() async throws -> some IntentResult {
        Sesion.iniciarCrono()
        await Sesion.sincronizar()
        return .result()
    }
}

struct AbrirPestanaIntent: AppIntent {
    static var title: LocalizedStringResource = "Abrir Deporte"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Pestana")
    var pestana: String

    init() {}
    init(pestana: String) { self.pestana = pestana }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(pestana, forKey: "pestana")
        NotificationCenter.default.post(name: .abrirPestana, object: nil)
        return .result()
    }
}
