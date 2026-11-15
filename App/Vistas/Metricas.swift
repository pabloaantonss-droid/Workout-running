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
        VStack(alignment: .leading, spacing: 10) {
            Text("Por tipo, últimas 5 semanas").font(.headline)
            ForEach(Rutinas.tipos, id: \.self) { t in
                let cuentas = (0..<5).map { d.porTipo(4 - $0)[t] ?? 0 }
                HStack {
                    Text(t).font(.subheadline).lineLimit(1)
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(0..<5, id: \.self) { i in
                            Text("\(cuentas[i])")
                                .font(.caption.bold())
                                .frame(width: 26, height: 26)
                                .foregroundStyle(cuentas[i] > 0 ? Color.black : Color.gray)
                                .background(
                                    cuentas[i] > 0 ? Color.oro : Color.black.opacity(0.3),
                                    in: RoundedRectangle(cornerRadius: 7)
                                )
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct PesoCard: View {
    @EnvironmentObject var almacen: Almacen
    @State private var texto = ""
    @State private var sel: Int? = nil
    @State private var aviso = ""

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
            HStack(spacing: 10) {
                TextField("Peso de hoy (kg)", text: $texto)
                    .keyboardType(.decimalPad)
                    .padding(10)
                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
                Button {
                    guardar()
                } label: {
                    Text("Guardar")
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.oro, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(Color.black)
                }
            }
            if !aviso.isEmpty {
                Text(aviso).font(.caption).foregroundStyle(Color.rojo)
            }
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
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
        almacen.guardarPeso(v, clave: Fecha.claveHoy())
        texto = ""
        aviso = ""
        sel = nil
    }
}
