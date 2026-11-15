import SwiftUI
import UserNotifications

struct RutinasLista: View {
    @EnvironmentObject var almacen: Almacen
    let abrir: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Rutinas.tipos, id: \.self) { t in
                Button {
                    abrir(t)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t).font(.headline).foregroundStyle(Color.white)
                            Text("\((almacen.datos.rutinas[t] ?? []).count) ejercicios")
                                .font(.caption)
                                .foregroundStyle(Color.gray)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(Color.gray)
                    }
                    .padding(16)
                    .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum EstadoFila {
    case normal
    case hecho
    case activo
    case pendiente
}

struct RutinaDetalle: View {
    @EnvironmentObject var almacen: Almacen
    @StateObject private var reloj = Reloj()
    let tipo: String
    let volver: () -> Void
    @State private var sesion: SesionActiva? = nil
    @State private var editando = false
    @State private var edit: [Ejercicio] = []

    var lista: [Ejercicio] { return almacen.datos.rutinas[tipo] ?? [] }
    var enSesion: Bool { return sesion != nil && sesion?.rutina == tipo }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            cabecera
            if editando {
                edicion
            } else {
                listado
            }
        }
        .onAppear { sesion = Sesion.actual() }
        .onReceive(NotificationCenter.default.publisher(for: .sesionCambio).receive(on: DispatchQueue.main)) { _ in
            sesion = Sesion.actual()
        }
        .onChange(of: reloj.ahora) { _, _ in
            comprobarCrono()
        }
    }

    var cabecera: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if !enSesion {
                    Button {
                        volver()
                    } label: {
                        Label("Rutinas", systemImage: "chevron.left")
                    }
                    .foregroundStyle(Color.oro)
                }
                Spacer()
                if !enSesion && !editando {
                    Button {
                        edit = lista
                        editando = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.oro)
                            .frame(width: 36, height: 36)
                            .background(Color.tarjeta, in: Circle())
                    }
                }
                if editando {
                    Button {
                        terminarEdicion()
                    } label: {
                        Text("Listo")
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.oro, in: Capsule())
                            .foregroundStyle(Color.black)
                    }
                }
            }
            Text(tipo).font(.largeTitle.bold())
            Text("\(editando ? edit.count : lista.count) ejercicios")
                .foregroundStyle(Color.gray)
            if enSesion {
                HStack {
                    Text("\(sesion?.indice ?? 0) de \(lista.count) hechos")
                        .font(.headline)
                        .foregroundStyle(Color.oro)
                    Spacer()
                    Button("Cancelar") {
                        cancelar()
                    }
                    .foregroundStyle(Color.rojo)
                }
            } else if !editando {
                Button {
                    iniciar()
                } label: {
                    Text("Iniciar ejercicio")
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.oro, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color.black)
                }
            }
        }
    }

    var listado: some View {
        VStack(spacing: 8) {
            ForEach(Array(lista.enumerated()), id: \.element.id) { item in
                fila(item.offset, item.element)
            }
        }
    }

    func estadoFila(_ i: Int) -> EstadoFila {
        guard enSesion, let s = sesion else { return .normal }
        if i < s.indice { return .hecho }
        if i == s.indice { return .activo }
        return .pendiente
    }

    func fila(_ i: Int, _ e: Ejercicio) -> some View {
        let estado = estadoFila(i)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(i + 1)")
                    .font(.caption.bold())
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.black.opacity(0.35)))
                    .foregroundStyle(Color.gray)
                Text(e.nombre)
                    .strikethrough(estado == .hecho)
                    .foregroundStyle(estado == .hecho ? Color.gray : Color.white)
                Spacer()
                Text(e.valorTxt)
                    .font(.subheadline)
                    .foregroundStyle(estado == .hecho ? Color.gray : Color.oro)
            }
            if estado == .activo && e.seg {
                cronometro(e)
            }
        }
        .padding(12)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(estado == .activo ? Color.rojo : Color.clear, lineWidth: 2)
        )
        .opacity(estado == .pendiente ? 0.45 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            if estado == .activo && !e.seg {
                marcar()
            }
        }
    }

    func cronometro(_ e: Ejercicio) -> some View {
        let s = sesion ?? SesionActiva(rutina: tipo)
        let t = Sesion.transcurrido(s, ahora: reloj.ahora)
        let objetivo = Double(max(e.valor, 1))
        let prog = min(t / objetivo, 1.0)
        let corriendo = s.inicio != nil
        let pausado = s.inicio == nil && s.acumulado > 0
        return VStack(alignment: .leading, spacing: 8) {
            if e.each {
                Text(s.lado == 1 ? "Lado 1 de 2" : "Lado 2 de 2. Cambia de lado")
                    .font(.caption)
                    .foregroundStyle(Color.oro)
            }
            Text("\(Fecha.mmss(t)) / \(Fecha.mmss(objetivo))")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
            ProgressView(value: prog).tint(Color.oro)
            HStack(spacing: 10) {
                if corriendo {
                    botonCrono("Parar") { Sesion.pararCrono() }
                } else {
                    botonCrono(pausado ? "Reanudar" : "Iniciar") { Sesion.iniciarCrono() }
                }
                if corriendo || pausado {
                    botonCrono("Reiniciar") { Sesion.reiniciarCrono() }
                }
            }
        }
    }

    func botonCrono(_ t: String, _ f: @escaping () -> Void) -> some View {
        Button {
            f()
            Task { await Sesion.sincronizar() }
        } label: {
            Text(t)
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.oro, in: Capsule())
                .foregroundStyle(Color.black)
        }
    }

    var edicion: some View {
        VStack(spacing: 10) {
            ForEach($edit) { $e in
                FilaEdicion(
                    e: $e,
                    subir: { mover(e.id, -1) },
                    bajar: { mover(e.id, 1) },
                    borrar: { edit.removeAll { $0.id == e.id } }
                )
            }
            Button {
                edit.append(Ejercicio(nombre: "", seg: false, valor: 10, each: false))
            } label: {
                Label("Añadir ejercicio", systemImage: "plus")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.oro)
            }
        }
    }

    func mover(_ id: UUID, _ delta: Int) {
        guard let i = edit.firstIndex(where: { $0.id == id }) else { return }
        let j = i + delta
        guard j >= 0, j < edit.count else { return }
        edit.swapAt(i, j)
    }

    func terminarEdicion() {
        let limpia = edit.filter { !$0.nombre.trimmingCharacters(in: .whitespaces).isEmpty }
        almacen.guardarEjercicios(tipo, limpia)
        editando = false
    }

    func iniciar() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        Sesion.iniciar(tipo)
        Task { await Sesion.sincronizar() }
    }

    func cancelar() {
        Sesion.cancelar()
        Task { await Sesion.sincronizar() }
    }

    func marcar() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Sesion.marcarHecho()
        Task { await Sesion.sincronizar() }
    }

    func comprobarCrono() {
        guard let s = Sesion.actual(), s.inicio != nil, s.rutina == tipo else { return }
        let l = almacen.datos.rutinas[tipo] ?? []
        guard s.indice < l.count else { return }
        let e = l[s.indice]
        guard e.seg, Sesion.transcurrido(s) >= Double(e.valor) else { return }
        marcar()
    }
}

struct FilaEdicion: View {
    @Binding var e: Ejercicio
    let subir: () -> Void
    let bajar: () -> Void
    let borrar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Nombre", text: $e.nombre)
                    .padding(10)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                Button(action: borrar) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.rojo)
                }
            }
            HStack(spacing: 10) {
                Picker("Tipo", selection: $e.seg) {
                    Text("Reps").tag(false)
                    Text("Seg").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                TextField("0", value: $e.valor, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .padding(8)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                Button {
                    e.each.toggle()
                } label: {
                    Label("each", systemImage: e.each ? "checkmark.square.fill" : "square")
                        .font(.caption)
                        .foregroundStyle(e.each ? Color.oro : Color.gray)
                }
                Spacer()
                Button(action: subir) {
                    Image(systemName: "chevron.up").foregroundStyle(Color.oro)
                }
                Button(action: bajar) {
                    Image(systemName: "chevron.down").foregroundStyle(Color.oro)
                }
            }
        }
        .padding(12)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 12))
    }
}
