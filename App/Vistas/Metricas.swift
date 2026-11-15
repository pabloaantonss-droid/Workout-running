import SwiftUI

struct PuntoPeso {
    let k: String
    let v: Double
}

struct MetricasView: View {
    @EnvironmentObject var almacen: Almacen

    var body: some View {
        let d = almacen.datos
        let sem = (0..<5).map { d.workoutsSemana(4 - $0) }
        let suma = sem.reduce(0, +)
        VStack(spacing: 16) {
            PesoCard()
            HStack(spacing: 12) {
                tile("Media por semana", String(format: "%.1f", Double(suma) / 5.0))
                tile("Mejor semana", "\(sem.max() ?? 0)")
            }
            barras(d, sem)
            porTipo(d)
            MesCalendario()
        }
    }

    func tile(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(t).font(.caption).foregroundStyle(Color.gray)
            Text(v).font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(Color.oro)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }

    func barras(_ d: DatosApp, _ sem: [Int]) -> some View {
        let m = max(sem.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Sesiones por semana").font(.headline)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<5, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(sem[i])").font(.caption.bold())
                        RoundedRectangle(cornerRadius: 6)
                            .fill(i == 4 ? Color.oro : Color.oroOscuro)
                            .frame(height: max(6, CGFloat(sem[i]) / CGFloat(m) * 90))
                        Text(Fecha.corta(d.inicioSemana(offset: 4 - i)))
                            .font(.system(size: 9))
                            .foregroundStyle(Color.gray)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140, alignment: .bottom)
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }

    func porTipo(_ d: DatosApp) -> some View {
        var tot: [String: Int] = [:]
        for t in Rutinas.tipos {
            var n = 0
            for off in 0..<5 { n += d.porTipo(off)[t] ?? 0 }
            tot[t] = n
        }
        let m = max(tot.values.max() ?? 1, 1)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Por tipo, últimas 5 semanas")
                .font(.subheadline)
                .foregroundStyle(Color.gray)
            ForEach(Rutinas.tipos, id: \.self) { t in
                let n = tot[t] ?? 0
                HStack(spacing: 12) {
                    Text(t)
                        .font(.subheadline)
                        .frame(width: 118, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.black.opacity(0.3))
                            Capsule()
                                .fill(Color.oro)
                                .frame(width: g.size.width * CGFloat(n) / CGFloat(m))
                        }
                    }
                    .frame(height: 8)
                    Text("\(n)")
                        .font(.subheadline.bold())
                        .frame(width: 28, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PesoCard: View {
    @EnvironmentObject var almacen: Almacen
    @State private var texto = ""
    @State private var sel: Int? = nil
    @State private var aviso = ""
    @State private var editClave: String? = nil
    @State private var claveBorrar: String? = nil
    @State private var confirmar = false

    var puntos: [PuntoPeso] {
        let claves = almacen.datos.pesos.keys.sorted()
        return claves.map { PuntoPeso(k: $0, v: almacen.datos.pesos[$0] ?? 0) }
    }

    var body: some View {
        let p = puntos
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Peso").font(.caption).foregroundStyle(Color.gray)
                    Text(p.last.map { String(format: "%.1f kg", $0.v) } ?? "- kg")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                }
                Spacer()
                comparacion(p)
            }
            grafica(p)
            if !p.isEmpty {
                filaSeleccion(p)
            }
            HStack(spacing: 10) {
                TextField(editClave == nil ? "Peso de hoy (kg)" : "Nuevo peso (kg)", text: $texto)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                Button {
                    guardar()
                } label: {
                    Text(editClave == nil ? "Guardar" : "Guardar cambio")
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.oro, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Color.black)
                }
            }
            if editClave != nil {
                Button("Cancelar edición") {
                    editClave = nil
                    texto = ""
                    aviso = ""
                }
                .font(.caption)
                .foregroundStyle(Color.gray)
            }
            if !aviso.isEmpty {
                Text(aviso).font(.caption).foregroundStyle(Color.rojo)
            }
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
        .confirmationDialog("¿Eliminar este peso?", isPresented: $confirmar, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                if let k = claveBorrar {
                    almacen.eliminarPeso(k)
                    sel = nil
                    if editClave == k {
                        editClave = nil
                        texto = ""
                    }
                }
                claveBorrar = nil
            }
            Button("Cancelar", role: .cancel) {
                claveBorrar = nil
            }
        }
    }

    func indiceSel(_ p: [PuntoPeso]) -> Int {
        return min(sel ?? (p.count - 1), p.count - 1)
    }

    func filaSeleccion(_ p: [PuntoPeso]) -> some View {
        let item = p[indiceSel(p)]
        return HStack(spacing: 14) {
            Text(Fecha.largaClave(item.k) + ": " + String(format: "%.1f kg", item.v))
                .font(.footnote)
                .foregroundStyle(Color.gray)
            Spacer()
            Button {
                editClave = item.k
                texto = String(format: "%.1f", item.v)
                aviso = ""
            } label: {
                Image(systemName: "pencil").foregroundStyle(Color.oro)
            }
            Button {
                claveBorrar = item.k
                confirmar = true
            } label: {
                Image(systemName: "trash").foregroundStyle(Color.rojo)
            }
        }
    }

    @ViewBuilder
    func comparacion(_ p: [PuntoPeso]) -> some View {
        if p.count >= 2 {
            let ult = p[p.count - 1]
            let ant = p[p.count - 2]
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%+.1f kg", ult.v - ant.v)).font(.headline)
                Text("respecto al \(Fecha.cortaClave(ant.k))")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
            }
        }
    }

    @ViewBuilder
    func grafica(_ p: [PuntoPeso]) -> some View {
        if p.isEmpty {
            Text("Guarda tu peso para ver la gráfica")
                .font(.caption)
                .foregroundStyle(Color.gray)
                .frame(maxWidth: .infinity, minHeight: 60)
        } else {
            GeometryReader { geo in
                let pts = posiciones(p, geo.size)
                let idx = min(sel ?? (p.count - 1), p.count - 1)
                ZStack(alignment: .topLeading) {
                    trazo(pts, 0, idx).stroke(Color.oro, lineWidth: 3)
                    trazo(pts, idx, pts.count - 1).stroke(Color.oroOscuro, lineWidth: 3)
                    ForEach(0..<pts.count, id: \.self) { i in
                        Circle()
                            .fill(i <= idx ? Color.oro : Color.oroOscuro)
                            .frame(width: 6, height: 6)
                            .position(pts[i])
                    }
                    Circle()
                        .fill(Color.oro)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .position(pts[idx])
                    burbuja(p[idx], pts[idx], geo.size.width)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { g in
                            sel = masCercano(g.location.x, pts)
                        }
                )
            }
            .frame(height: 150)
        }
    }

    func burbuja(_ item: PuntoPeso, _ pt: CGPoint, _ ancho: CGFloat) -> some View {
        let x = min(max(pt.x, 62), max(ancho - 62, 62))
        return Text(String(format: "%.1f kg, ", item.v) + Fecha.cortaClave(item.k))
            .font(.caption.bold())
            .foregroundStyle(Color.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.oro, in: Capsule())
            .position(x: x, y: max(pt.y - 26, 12))
    }

    func trazo(_ pts: [CGPoint], _ desde: Int, _ hasta: Int) -> Path {
        var path = Path()
        if pts.isEmpty || desde > hasta { return path }
        for i in desde...hasta {
            if i == desde {
                path.move(to: pts[i])
            } else {
                path.addLine(to: pts[i])
            }
        }
        return path
    }

    func posiciones(_ p: [PuntoPeso], _ size: CGSize) -> [CGPoint] {
        guard let primero = p.first, let ultimo = p.last,
              let d0 = Fecha.fecha(primero.k), let d1 = Fecha.fecha(ultimo.k) else { return [] }
        let total = max(Fecha.cal.dateComponents([.day], from: d0, to: d1).day ?? 1, 1)
        let vs = p.map { $0.v }
        let lo = (vs.min() ?? 0) - 0.3
        let hi = (vs.max() ?? 1) + 0.3
        let padX: CGFloat = 16
        let padY: CGFloat = 40
        var res: [CGPoint] = []
        for item in p {
            let d = Fecha.fecha(item.k) ?? d0
            let dias = Fecha.cal.dateComponents([.day], from: d0, to: d).day ?? 0
            let x = padX + (size.width - 2 * padX) * CGFloat(dias) / CGFloat(total)
            let frac = CGFloat((item.v - lo) / (hi - lo))
            let y = size.height - 12 - (size.height - 12 - padY) * frac
            res.append(CGPoint(x: x, y: y))
        }
        return res
    }

    func masCercano(_ x: CGFloat, _ pts: [CGPoint]) -> Int {
        var mejor = 0
        var dist = CGFloat.greatestFiniteMagnitude
        for (i, pt) in pts.enumerated() {
            let d = abs(pt.x - x)
            if d < dist {
                dist = d
                mejor = i
            }
        }
        return mejor
    }

    func guardar() {
        let t = texto.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)
        guard let v = Double(t), v >= 20, v <= 300 else {
            aviso = "Introduce un peso entre 20 y 300 kg"
            return
        }
        almacen.guardarPeso(v, clave: editClave ?? Fecha.claveHoy())
        texto = ""
        aviso = ""
        editClave = nil
        sel = nil
    }
}

struct DiscoMes: View {
    let dia: Int
    let w: Int
    let r: Int
    let esHoy: Bool

    var conSesion: Bool { return w > 0 || r > 0 }

    @ViewBuilder
    var fondo: some View {
        if w > 0 && r > 0 {
            Circle().fill(
                LinearGradient(
                    stops: [
                        Gradient.Stop(color: Color.oro, location: 0.5),
                        Gradient.Stop(color: Color.azul, location: 0.5)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else if w > 0 {
            Circle().fill(Color.oro)
        } else if r > 0 {
            Circle().fill(Color.azul)
        } else {
            Circle().fill(Color.black.opacity(0.3))
        }
    }

    var body: some View {
        ZStack {
            fondo
            Text("\(dia)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(conSesion ? Color.black : Color.white)
            if esHoy {
                Circle().strokeBorder(Color.rojo, lineWidth: 3)
            }
        }
        .frame(width: 36, height: 36)
        .frame(maxWidth: .infinity)
    }
}

struct MesGrid: View {
    let primero: Date
    let datos: DatosApp

    static let letras = ["L", "M", "X", "J", "V", "S", "D"]

    var body: some View {
        let cal = Fecha.cal
        let nDias = cal.range(of: .day, in: .month, for: primero)?.count ?? 30
        let wd = cal.component(.weekday, from: primero)
        let hueco = (wd + 5) % 7
        let runs = datos.carrerasPorDia
        let hoyK = Fecha.claveHoy()
        let columnas = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Text(MesGrid.letras[i])
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: columnas, spacing: 6) {
                ForEach(0..<(hueco + nDias), id: \.self) { i in
                    if i < hueco {
                        Color.clear.frame(height: 36)
                    } else {
                        let dia = i - hueco + 1
                        let fecha = cal.date(byAdding: .day, value: dia - 1, to: primero) ?? primero
                        let k = Fecha.clave(fecha)
                        DiscoMes(dia: dia, w: datos.workouts[k]?.count ?? 0, r: runs[k] ?? 0, esHoy: k == hoyK)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

struct MesCalendario: View {
    @EnvironmentObject var almacen: Almacen
    @State private var pagina = 0

    var body: some View {
        let d = almacen.datos
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Fecha.nombreMes(Fecha.primerDiaMes(offset: pagina)))
                    .font(.headline)
                Spacer()
                Leyenda()
            }
            TabView(selection: $pagina) {
                ForEach(-24...0, id: \.self) { off in
                    MesGrid(primero: Fecha.primerDiaMes(offset: off), datos: d)
                        .tag(off)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 300)
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }
}
