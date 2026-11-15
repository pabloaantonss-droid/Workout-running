import SwiftUI

enum Modo {
    case workout
    case running
}

struct CeldaDia: View {
    let fecha: Date
    let w: Int
    let r: Int
    let modo: Modo
    let esHoy: Bool

    var dia: Int { return Fecha.cal.component(.day, from: fecha) }
    var etiquetaMes: String { return dia == 1 ? Fecha.mes(fecha) : "" }
    var conSesion: Bool { return w > 0 || r > 0 }

    var body: some View {
        VStack(spacing: 3) {
            disco
            Text(etiquetaMes)
                .font(.system(size: 10))
                .foregroundStyle(Color.gray)
                .frame(height: 12)
        }
        .frame(width: 42)
    }

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
            Circle().fill(Color.tarjeta)
        }
    }

    var disco: some View {
        ZStack {
            fondo
            Text("\(dia)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(conSesion ? Color.black : Color.white)
            if esHoy {
                Circle().stroke(Color.rojo, lineWidth: 3)
            }
        }
        .frame(width: 38, height: 38)
        .overlay(alignment: .topTrailing) { insignia }
    }

    @ViewBuilder
    var insignia: some View {
        let n = (modo == .workout) ? w : r
        if n >= 2 {
            Text("\(n)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.black))
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .offset(x: 4, y: -4)
        }
    }
}

struct TiraDias: View {
    let datos: DatosApp
    let modo: Modo
    let irAHoy: Int
    var onTocar: ((String) -> Void)? = nil

    var dias: [Date] {
        let hoy = Fecha.hoy
        let ini = Fecha.sumar(Fecha.inicioSemana(hoy), dias: -7 * 15)
        let n = Fecha.cal.dateComponents([.day], from: ini, to: hoy).day ?? 0
        return (0...max(n, 0)).map { Fecha.sumar(ini, dias: $0) }
    }

    var body: some View {
        let runs = datos.carrerasPorDia
        let hoyK = Fecha.claveHoy()
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(dias, id: \.self) { d in
                        let k = Fecha.clave(d)
                        CeldaDia(
                            fecha: d,
                            w: datos.workouts[k]?.count ?? 0,
                            r: runs[k] ?? 0,
                            modo: modo,
                            esHoy: k == hoyK
                        )
                        .id(k)
                        .onTapGesture { onTocar?(k) }
                    }
                }
                .padding(.horizontal, 12)
            }
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(hoyK, anchor: .trailing)
                }
            }
            .onChange(of: irAHoy) { _, _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(hoyK, anchor: .trailing)
                }
            }
        }
        .frame(height: 64)
    }
}

struct Leyenda: View {
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle().fill(Color.oro).frame(width: 10, height: 10)
                Text("Workouts").font(.caption).foregroundStyle(Color.gray)
            }
            HStack(spacing: 6) {
                Circle().fill(Color.azul).frame(width: 10, height: 10)
                Text("Running").font(.caption).foregroundStyle(Color.gray)
            }
        }
    }
}
