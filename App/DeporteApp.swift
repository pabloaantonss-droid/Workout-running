import SwiftUI

@main
struct DeporteApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

final class Reloj: ObservableObject {
    @Published var ahora = Date()
    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.ahora = Date()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

struct ContentView: View {
    @ObservedObject private var almacen = Almacen.compartido
    @Environment(\.scenePhase) private var fase
    @State private var pestana = 0

    var body: some View {
        TabView(selection: $pestana) {
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell.fill") }
                .tag(0)
            RunningView()
                .tabItem { Label("Running", systemImage: "figure.run") }
                .tag(1)
        }
        .tint(Color.oro)
        .environmentObject(almacen)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .abrirPestana).receive(on: DispatchQueue.main)) { _ in
            leer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .datosCambiaron).receive(on: DispatchQueue.main)) { _ in
            almacen.recargar()
        }
        .onChange(of: fase) { _, nueva in
            if nueva == .active {
                almacen.recargar()
                leer()
            }
        }
        .onAppear { leer() }
    }

    func leer() {
        if let p = UserDefaults.standard.string(forKey: "pestana") {
            pestana = (p == "running") ? 1 : 0
            UserDefaults.standard.removeObject(forKey: "pestana")
        }
    }
}
