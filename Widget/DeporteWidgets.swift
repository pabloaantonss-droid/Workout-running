import WidgetKit
import SwiftUI
import ActivityKit
import AppIntents

@main
struct DeporteWidgets: WidgetBundle {
    var body: some Widget {
        ContadorWidget()
        EjercicioLiveActivity()
    }
}

struct Entrada: TimelineEntry { let date: Date }

struct Proveedor: TimelineProvider {
    func placeholder(in context: Context) -> Entrada { Entrada(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entrada) -> Void) { completion(Entrada(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entrada>) -> Void) {
        completion(Timeline(entries: [Entrada(date: .now)], policy: .never))
    }
}

struct VistaContador: View {
    var body: some View {
        VStack(spacing: 8) {
            fila(icono: "dumbbell.fill", nombre: "Workout", n: "3", pestana: "workout")
            fila(icono: "figure.run", nombre: "Running", n: "2", pestana: "running")
        }
    }

    func fila(icono: String, nombre: String, n: String, pestana: String) -> some View {
        Button(intent: AbrirAppIntent(pestana: pestana)) {
            HStack {
                Image(systemName: icono)
                Text(nombre).font(.caption.bold())
                Spacer()
                Text(n).font(.title3.bold())
            }
            .padding(.horizontal, 8)
            .frame(maxHeight: .infinity)
            .background(Color(red: 0.22, green: 0.23, blue: 0.25), in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct ContadorWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Contador", provider: Proveedor()) { _ in
            VistaContador()
                .foregroundStyle(.white)
                .containerBackground(Color(red: 0.17, green: 0.18, blue: 0.19), for: .widget)
        }
        .configurationDisplayName("Deporte")
        .description("Sesiones de la semana")
        .supportedFamilies([.systemSmall])
    }
}

struct VistaBloqueo: View {
    let estado: EjercicioAttributes.ContentState
    let rutina: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(rutina) - \(min(estado.indice + 1, estado.total)) de \(estado.total)")
                    .font(.caption)
                Text(estado.nombre).font(.headline)
                ProgressView(value: Double(estado.indice), total: Double(estado.total))
                    .tint(Color(red: 1, green: 0.77, blue: 0))
            }
            Spacer()
            if estado.indice < estado.total {
                Button(intent: TickIntent()) {
                    Image(systemName: "checkmark")
                        .font(.title2.bold())
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 48)
                        .background(Color(red: 1, green: 0.77, blue: 0), in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

struct EjercicioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EjercicioAttributes.self) { context in
            VistaBloqueo(estado: context.state, rutina: context.attributes.rutina)
                .activityBackgroundTint(Color(red: 0.17, green: 0.18, blue: 0.19))
                .foregroundStyle(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.nombre).font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.indice < context.state.total {
                        Button(intent: TickIntent()) {
                            Image(systemName: "checkmark.circle.fill").font(.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(context.state.indice)/\(context.state.total)")
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}
