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

struct EntradaContador: TimelineEntry {
    let date: Date
    let workouts: Int
    let running: Int
}

struct ProveedorContador: TimelineProvider {
    func contar(_ fecha: Date) -> EntradaContador {
        let d = Almacen.cargar()
        return EntradaContador(date: fecha, workouts: d.workoutsSemana(0), running: d.runningSemana(0))
    }

    func placeholder(in context: Context) -> EntradaContador {
        return EntradaContador(date: Date(), workouts: 3, running: 2)
    }

    func getSnapshot(in context: Context, completion: @escaping (EntradaContador) -> Void) {
        completion(contar(Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EntradaContador>) -> Void) {
        let ahora = Date()
        let siguiente = ahora.addingTimeInterval(3600)
        completion(Timeline(entries: [contar(ahora)], policy: .after(siguiente)))
    }
}

struct FilaContador: View {
    let icono: String
    let nombre: String
    let n: Int
    let color: Color
    let pestana: String

    var body: some View {
        Button(intent: AbrirPestanaIntent(pestana: pestana)) {
            HStack(spacing: 6) {
                Image(systemName: icono)
                    .font(.system(size: 15, weight: .bold))
                Text(nombre)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text("\(n)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
            }
            .foregroundStyle(Color.black)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct VistaContador: View {
    let e: EntradaContador

    var body: some View {
        VStack(spacing: 8) {
            FilaContador(icono: "dumbbell.fill", nombre: "Workout", n: e.workouts, color: Color.oro, pestana: "workout")
            FilaContador(icono: "figure.run", nombre: "Running", n: e.running, color: Color.azul, pestana: "running")
        }
    }
}

struct ContadorWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Contador", provider: ProveedorContador()) { entrada in
            VistaContador(e: entrada)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(hex: 0x3A1C71), Color(hex: 0x1B2A6B)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Deporte")
        .description("Sesiones de esta semana")
        .supportedFamilies([.systemSmall])
    }
}

struct VistaBloqueo: View {
    let st: EjercicioAttributes.ContentState
    let rutina: String

    var body: some View {
        if st.completado {
            completado
        } else {
            normal
        }
    }

    var completado: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.oro)
            VStack(alignment: .leading, spacing: 2) {
                Text("Entreno completado").font(.headline)
                Text("Añadido a hoy").font(.caption).foregroundStyle(Color.gray)
            }
            Spacer()
        }
        .padding()
    }

    var normal: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "dumbbell.fill").foregroundStyle(Color.oro)
                Text(rutina).font(.caption.bold())
                Spacer()
                Text("\(min(st.indice + 1, st.total)) de \(st.total)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(st.nombre).font(.headline).lineLimit(2)
                    valorVista
                }
                Spacer()
                if st.temporizado && st.fin == nil {
                    Button(intent: PlayIntent()) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.white)
                            .frame(width: 44, height: 44)
                            .background(Color.azul.opacity(0.35), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                Button(intent: TickIntent()) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                        .frame(width: 48, height: 48)
                        .background(Color.oro, in: Circle())
                }
                .buttonStyle(.plain)
            }
            ProgressView(value: Double(st.indice), total: Double(max(st.total, 1)))
                .tint(Color.oro)
            if !st.siguiente.isEmpty {
                Text("Siguiente: \(st.siguiente)")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .lineLimit(1)
            }
        }
        .padding()
    }

    @ViewBuilder
    var valorVista: some View {
        let ahora = Date.now
        if st.temporizado, let fin = st.fin {
            Text(timerInterval: ahora...max(fin, ahora), pauseTime: nil, countsDown: true, showsHours: false)
                .font(.title3.monospacedDigit())
                .foregroundStyle(Color.oro)
        } else {
            let lado = st.lados > 1 ? "  (lado \(st.lado) de \(st.lados))" : ""
            Text(st.valor + lado)
                .font(.subheadline)
                .foregroundStyle(Color.oro)
        }
    }
}

struct EjercicioLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EjercicioAttributes.self) { context in
            VistaBloqueo(st: context.state, rutina: context.attributes.rutina)
                .activityBackgroundTint(Color(hex: 0x1E1F26))
                .foregroundStyle(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.nombre).font(.headline).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.state.completado {
                        Button(intent: TickIntent()) {
                            Image(systemName: "checkmark.circle.fill").font(.title)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
            } compactTrailing: {
                Text("\(min(context.state.indice + 1, context.state.total))/\(context.state.total)")
            } minimal: {
                Image(systemName: "dumbbell.fill")
            }
        }
    }
}
