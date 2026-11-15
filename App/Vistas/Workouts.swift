import SwiftUI

enum Vista: String, CaseIterable, Identifiable {
    case semana = "Semana"
    case metricas = "Métricas"
    case rutinas = "Rutinas"
    var id: String { return rawValue }
}

struct DiaSel: Identifiable {
    let id: String
}

struct WorkoutsView: View {
    @EnvironmentObject var almacen: Almacen
    @State private var vista: Vista = .semana
    @State private var rutinaAbierta: String? = nil
    @State private var irAHoy = 0
    @State private var diaPanel: DiaSel? = nil
    @State private var enCurso = false

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if rutinaAbierta == nil {
                        EncabezadoPantalla(titulo: "Workouts")
                        Picker("Vista", selection: $vista) {
                            ForEach(Vista.allCases) { v in
                                Text(v.rawValue).tag(v)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    contenido
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(item: $diaPanel) { sel in
            PanelDia(clave: sel.id)
                .environmentObject(almacen)
                .presentationDetents([.medium])
        }
        .onAppear { revisarSesion() }
        .onReceive(NotificationCenter.default.publisher(for: .sesionCambio).receive(on: DispatchQueue.main)) { _ in
            revisarSesion()
        }
    }

    @ViewBuilder
    var contenido: some View {
        switch vista {
        case .semana:
            SemanaWorkouts(irAHoy: $irAHoy, diaPanel: $diaPanel)
        case .metricas:
            MetricasView()
        case .rutinas:
            if let r = rutinaAbierta {
                RutinaDetalle(tipo: r, volver: { rutinaAbierta = nil })
            } else {
                RutinasLista(abrir: { t in rutinaAbierta = t })
            }
        }
    }

    func revisarSesion() {
        if let s = Sesion.actual() {
            enCurso = true
            vista = .rutinas
            rutinaAbierta = s.rutina
        } else if enCurso {
            enCurso = false
            if Sesion.fueTerminada {
                Sesion.fueTerminada = false
                vista = .semana
                rutinaAbierta = nil
                irAHoy += 1
            }
        }
    }
}

struct SemanaWorkouts: View {
    @EnvironmentObject var almacen: Almacen
    @Binding var irAHoy: Int
    @Binding var diaPanel: DiaSel?
    @State private var abierta: Int? = nil

    var body: some View {
        let d = almacen.datos
        VStack(alignment: .leading, spacing: 16) {
            cabecera(d)
            TiraDias(datos: d, modo: .workout, irAHoy: irAHoy, onTocar: { k in
                diaPanel = DiaSel(id: k)
            })
            .padding(.horizontal, -16)
            previas(d)
        }
    }

    func cabecera(_ d: DatosApp) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                irAHoy += 1
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(d.workoutsSemana(0))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.oro)
                    Text("esta semana")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            tabla(d)
                .padding(.trailing, 12)
        }
    }

    func tabla(_ d: DatosApp) -> some View {
        let pas = d.porTipo(1)
        let act = d.porTipo(0)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("").frame(width: 124)
                Text("Pasada").frame(width: 44, alignment: .trailing)
                Text("Actual").frame(width: 44, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(Color.gray)
            ForEach(Rutinas.tipos, id: \.self) { t in
                HStack(spacing: 8) {
                    Text(t)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 124, alignment: .leading)
                    Text("\(pas[t] ?? 0)").frame(width: 44, alignment: .trailing)
                    Text("\(act[t] ?? 0)")
                        .foregroundStyle(Color.oro)
                        .frame(width: 44, alignment: .trailing)
                }
                .font(.subheadline)
            }
        }
    }

    func previas(_ d: DatosApp) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Semanas anteriores").font(.headline)
            ForEach(1...4, id: \.self) { off in
                fila(d, off)
            }
        }
    }

    func fila(_ d: DatosApp, _ off: Int) -> some View {
        let ini = d.inicioSemana(offset: off)
        let fin = Fecha.sumar(ini, dias: 6)
        return VStack(alignment: .leading, spacing: 10) {
            Button {
                abierta = (abierta == off) ? nil : off
            } label: {
                HStack {
                    Text("\(Fecha.corta(ini)) - \(Fecha.corta(fin))")
                    Spacer()
                    Text("\(d.workoutsSemana(off))")
                        .bold()
                        .foregroundStyle(Color.oro)
                    Image(systemName: abierta == off ? "chevron.up" : "chevron.down")
                        .foregroundStyle(Color.gray)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if abierta == off {
                detalle(d, off)
            }
        }
        .padding(12)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 14))
    }

    func detalle(_ d: DatosApp, _ off: Int) -> some View {
        let ini = d.inicioSemana(offset: off)
        let runs = d.carrerasPorDia
        let tipos = d.porTipo(off)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    let dia = Fecha.sumar(ini, dias: i)
                    let k = Fecha.clave(dia)
                    CeldaDia(fecha: dia, w: d.workouts[k]?.count ?? 0, r: runs[k] ?? 0, modo: .workout, esHoy: false, ancho: 44, futuro: false)
                }
            }
            HStack(spacing: 6) {
                ForEach(Rutinas.tipos, id: \.self) { t in
                    if (tipos[t] ?? 0) > 0 {
                        Text("\(t) \(tipos[t] ?? 0)")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.35), in: Capsule())
                    }
                }
            }
        }
    }
}

struct PanelDia: View {
    @EnvironmentObject var almacen: Almacen
    @Environment(\.dismiss) private var cerrar
    let clave: String

    var body: some View {
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                Text(Fecha.largaClave(clave)).font(.headline)
                Text("Añade o quita sesiones de este día").font(.caption).foregroundStyle(Color.gray)
                ForEach(Rutinas.tipos, id: \.self) { t in
                    fila(t)
                }
                Button {
                    cerrar()
                } label: {
                    Text("Listo")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.oro, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Color.black)
                }
            }
            .padding(20)
        }
    }

    func fila(_ t: String) -> some View {
        let n = (almacen.datos.workouts[clave] ?? []).filter { $0 == t }.count
        return HStack {
            Text(t)
            Spacer()
            Button {
                almacen.quitar(t, clave)
            } label: {
                Image(systemName: "minus.circle").font(.title2)
            }
            .disabled(n == 0)
            Text("\(n)").frame(width: 30).font(.headline)
            Button {
                almacen.anadir(t, clave)
            } label: {
                Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(Color.oro)
            }
        }
    }
}
