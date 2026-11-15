import SwiftUI

struct RunningView: View {
    @EnvironmentObject var almacen: Almacen
    @ObservedObject private var strava = Strava.compartido
    @AppStorage("stravaID") private var stravaID = ""
    @AppStorage("stravaSecret") private var stravaSecret = ""
    @State private var irAHoy = 0
    @State private var ajustesAbiertos = true

    var body: some View {
        let d = almacen.datos
        ZStack {
            Color.fondoApp.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    EncabezadoPantalla(titulo: "Running")
                    cabecera(d)
                    TiraDias(datos: d, modo: .running, irAHoy: irAHoy)
                        .padding(.horizontal, -16)
                    carreras(d)
                    controles
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
    }

    func cabecera(_ d: DatosApp) -> some View {
        HStack(alignment: .top) {
            Button {
                irAHoy += 1
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(d.runningSemana(0))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.azul)
                    Text("esta semana")
                        .font(.subheadline)
                        .foregroundStyle(Color.gray)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            HStack(spacing: 20) {
                Text("Total").foregroundStyle(Color.gray)
                Text("\(d.carreras.count)").foregroundStyle(Color.azul).bold()
            }
            .font(.footnote)
            .padding(.top, 8)
        }
    }

    func carreras(_ d: DatosApp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Últimas carreras").font(.headline)
                Spacer()
                Text("Datos de Strava").font(.caption).foregroundStyle(Color.gray)
            }
            if d.carreras.isEmpty {
                Text("Todavía no hay carreras. Conecta Strava abajo.")
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            } else {
                ForEach(Array(d.carreras.prefix(3))) { c in
                    TarjetaCarrera(c: c)
                }
            }
        }
    }

    var controles: some View {
        VStack(alignment: .leading, spacing: 10) {
            if strava.conectado {
                Button {
                    Task { await strava.actualizar() }
                } label: {
                    etiquetaBoton(strava.cargando ? "Actualizando..." : "Actualizar carreras")
                }
                .disabled(strava.cargando)
            } else {
                Button {
                    Task { await strava.conectar() }
                } label: {
                    etiquetaBoton("Conectar con Strava")
                }
            }
            if !strava.estado.isEmpty {
                Text(strava.estado).font(.caption).foregroundStyle(Color.gray)
            }
            DisclosureGroup("Ajustes de Strava", isExpanded: $ajustesAbiertos) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Client ID", text: $stravaID)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 10))
                    SecureField("Client Secret", text: $stravaSecret)
                        .padding(10)
                        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 10))
                    Text("1. Abre la página de Strava y crea una aplicación (nombre y categoría libres).\n2. En Authorization Callback Domain escribe: localhost\n3. Copia el Client ID y el Client Secret que te da Strava y pégalos aquí.")
                        .font(.caption)
                        .foregroundStyle(Color.gray)
                    if let url = URL(string: "https://www.strava.com/settings/api") {
                        Link("Abrir strava.com/settings/api", destination: url)
                            .font(.subheadline)
                    }
                    if strava.conectado {
                        Button("Volver a conectar") {
                            Task { await strava.conectar() }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .tint(Color.azul)
        }
    }

    func etiquetaBoton(_ t: String) -> some View {
        Text(t)
            .bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.azul, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Color.black)
    }
}

struct TarjetaCarrera: View {
    let c: Carrera

    var ritmo: String {
        if c.km <= 0 { return "-" }
        let s = Int((Double(c.seg) / c.km).rounded())
        return String(format: "%d:%02d /km", s / 60, s % 60)
    }

    var pulso: String {
        if let p = c.pulso { return "\(Int(p.rounded())) ppm" }
        return "-"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(Fecha.largaClave(c.fecha))
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
                Spacer()
                Text(String(format: "%.2f km", c.km))
                    .font(.title2.bold())
                    .foregroundStyle(Color.azul)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                dato("Duración", Fecha.hms(c.seg))
                dato("Ritmo", ritmo)
                dato("Desnivel", "\(Int(c.desnivel.rounded())) m")
                dato("Pulso medio", pulso)
            }
        }
        .padding(14)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
    }

    func dato(_ t: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(t).font(.caption).foregroundStyle(Color.gray)
            Text(v).font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
    }
}
