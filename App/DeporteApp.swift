import SwiftUI
import ActivityKit

@main
struct DeporteApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @Environment(\.scenePhase) private var fase
    @State private var pestana = "(ninguna)"
    @State private var mensaje = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Deporte - prueba").font(.title.bold())
            Text("Ultima pestana pedida desde el widget: \(pestana)")
                .multilineTextAlignment(.center)
            Button("Iniciar ejercicio de prueba") { iniciar() }
                .buttonStyle(.borderedProminent)
            Text(mensaje).font(.footnote).foregroundStyle(.secondary)
        }
        .padding()
        .onChange(of: fase) { _, nueva in
            if nueva == .active { leer() }
        }
        .onAppear { leer() }
    }

    func leer() {
        pestana = UserDefaults.standard.string(forKey: "pestana") ?? "(ninguna)"
    }

    func iniciar() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            mensaje = "Las Actividades en directo estan desactivadas en Ajustes"
            return
        }
        let attrs = EjercicioAttributes(rutina: "Pecho (prueba)")
        let estado = EjercicioAttributes.ContentState(indice: 0, total: ejerciciosPrueba.count, nombre: ejerciciosPrueba[0])
        do {
            _ = try Activity.request(attributes: attrs, content: ActivityContent(state: estado, staleDate: nil))
            mensaje = "Iniciado. Bloquea el iPhone para verlo."
        } catch {
            mensaje = "Error: \(error.localizedDescription)"
        }
    }
}
