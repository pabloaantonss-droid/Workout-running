import SwiftUI
import PhotosUI

enum FotosDiario {
    static var carpeta: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let base = docs.appendingPathComponent("fotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func guardar(_ data: Data) -> String? {
        guard let img = UIImage(data: data) else { return nil }
        let reducida = reducir(img, limite: 1600)
        guard let jpg = reducida.jpegData(compressionQuality: 0.8) else { return nil }
        let nombre = UUID().uuidString + ".jpg"
        do {
            try jpg.write(to: carpeta.appendingPathComponent(nombre))
            return nombre
        } catch {
            return nil
        }
    }

    static func cargar(_ nombre: String) -> UIImage? {
        return UIImage(contentsOfFile: carpeta.appendingPathComponent(nombre).path)
    }

    static func borrar(_ nombre: String) {
        try? FileManager.default.removeItem(at: carpeta.appendingPathComponent(nombre))
    }

    static func reducir(_ img: UIImage, limite: CGFloat) -> UIImage {
        let m = max(img.size.width, img.size.height)
        if m <= limite { return img }
        let esc = limite / m
        let nuevo = CGSize(width: img.size.width * esc, height: img.size.height * esc)
        return UIGraphicsImageRenderer(size: nuevo).image { _ in
            img.draw(in: CGRect(origin: .zero, size: nuevo))
        }
    }
}

struct FotoSel: Identifiable {
    let id: String
}

struct RunningView: View {
    @EnvironmentObject var almacen: Almacen
    @State private var irAHoy = 0
    @State private var mostrarForm = false
    @State private var carreraEdit: Carrera? = nil

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
                    Button {
                        carreraEdit = nil
                        mostrarForm = true
                    } label: {
                        Label("Registrar carrera", systemImage: "plus")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.azul, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(Color.black)
                    }
                    diario(d)
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $mostrarForm) {
            FormularioCarrera(original: carreraEdit)
                .environmentObject(almacen)
        }
    }

    func cabecera(_ d: DatosApp) -> some View {
        var km = 0.0
        for c in d.carreras { km += c.km }
        return HStack(alignment: .top) {
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
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 20) {
                    Text("Total").foregroundStyle(Color.gray)
                    Text("\(d.carreras.count)").foregroundStyle(Color.azul).bold()
                }
                HStack(spacing: 20) {
                    Text("Km").foregroundStyle(Color.gray)
                    Text(String(format: "%.1f", km)).foregroundStyle(Color.azul).bold()
                }
            }
            .font(.subheadline)
            .padding(.top, 8)
        }
    }

    func diario(_ d: DatosApp) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Diario de carreras").font(.headline)
            if d.carreras.isEmpty {
                Text("Todavía no hay carreras. Pulsa Registrar carrera para añadir la primera.")
                    .font(.subheadline)
                    .foregroundStyle(Color.gray)
            } else {
                ForEach(d.carreras) { c in
                    TarjetaCarrera(c: c)
                        .onTapGesture {
                            carreraEdit = c
                            mostrarForm = true
                        }
                }
            }
        }
    }
}

struct TarjetaCarrera: View {
    let c: Carrera
    @State private var foto: FotoSel? = nil

    var ritmo: String? {
        guard let s = c.seg, c.km > 0 else { return nil }
        let r = Int((Double(s) / c.km).rounded())
        return String(format: "%d:%02d /km", r / 60, r % 60)
    }

    var datos: [(String, String)] {
        var res: [(String, String)] = []
        if let s = c.seg { res.append(("Duración", Fecha.hms(s))) }
        if let r = ritmo { res.append(("Ritmo", r)) }
        if let dn = c.desnivel { res.append(("Desnivel", "\(Int(dn.rounded())) m")) }
        if let p = c.pulso { res.append(("Pulso medio", "\(Int(p.rounded())) ppm")) }
        return res
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
            if !datos.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(0..<datos.count, id: \.self) { i in
                        dato(datos[i].0, datos[i].1)
                    }
                }
            }
            if let n = c.nota, !n.isEmpty {
                Text(n).font(.subheadline).foregroundStyle(Color.white)
            }
            if let fs = c.fotos, !fs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(fs, id: \.self) { nombre in
                            miniatura(nombre)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tarjeta, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(Rectangle())
        .fullScreenCover(item: $foto) { f in
            VisorFoto(nombre: f.id)
        }
    }

    @ViewBuilder
    func miniatura(_ nombre: String) -> some View {
        if let img = FotosDiario.cargar(nombre) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .onTapGesture { foto = FotoSel(id: nombre) }
        }
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

struct VisorFoto: View {
    let nombre: String
    @Environment(\.dismiss) private var cerrar

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if let img = FotosDiario.cargar(nombre) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Button {
                cerrar()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.white)
                    .padding(20)
            }
        }
    }
}

struct FormularioCarrera: View {
    @EnvironmentObject var almacen: Almacen
    @Environment(\.dismiss) private var cerrar
    let original: Carrera?

    @State private var fecha: Date
    @State private var kmTxt: String
    @State private var durTxt: String
    @State private var desnivelTxt: String
    @State private var pulsoTxt: String
    @State private var nota: String
    @State private var fotos: [String]
    @State private var nuevas: [String] = []
    @State private var paraBorrar: [String] = []
    @State private var seleccion: [PhotosPickerItem] = []
    @State private var aviso = ""
    @State private var confirmarBorrado = false

    init(original: Carrera?) {
        self.original = original
        let f = original.flatMap { Fecha.fecha($0.fecha) } ?? Date()
        _fecha = State(initialValue: f)
        _kmTxt = State(initialValue: original.map { String(format: "%.2f", $0.km) } ?? "")
        _durTxt = State(initialValue: original?.seg.map { Fecha.hms($0) } ?? "")
        _desnivelTxt = State(initialValue: original?.desnivel.map { String(Int($0.rounded())) } ?? "")
        _pulsoTxt = State(initialValue: original?.pulso.map { String(Int($0.rounded())) } ?? "")
        _nota = State(initialValue: original?.nota ?? "")
        _fotos = State(initialValue: original?.fotos ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Obligatorio") {
                    DatePicker("Fecha", selection: $fecha, in: ...Date(), displayedComponents: .date)
                    TextField("Kilómetros", text: $kmTxt)
                        .keyboardType(.decimalPad)
                }
                Section("Opcional") {
                    TextField("Duración (por ejemplo 32:15)", text: $durTxt)
                        .keyboardType(.numbersAndPunctuation)
                    TextField("Desnivel (m)", text: $desnivelTxt)
                        .keyboardType(.decimalPad)
                    TextField("Pulso medio (ppm)", text: $pulsoTxt)
                        .keyboardType(.numberPad)
                    TextField("Nota", text: $nota, axis: .vertical)
                        .lineLimit(1...4)
                }
                Section("Fotos") {
                    PhotosPicker(selection: $seleccion, maxSelectionCount: 4, matching: .images) {
                        Label("Añadir fotos", systemImage: "photo.on.rectangle")
                    }
                    if !fotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(fotos, id: \.self) { nombre in
                                    miniatura(nombre)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                if !aviso.isEmpty {
                    Section {
                        Text(aviso).foregroundStyle(Color.rojo)
                    }
                }
                if original != nil {
                    Section {
                        Button("Eliminar carrera", role: .destructive) {
                            confirmarBorrado = true
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.fondoApp)
            .navigationTitle(original == nil ? "Registrar carrera" : "Editar carrera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cancelar() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { guardar() }
                        .bold()
                }
            }
            .confirmationDialog("¿Eliminar esta carrera?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive) { borrar() }
                Button("Cancelar", role: .cancel) {}
            }
        }
        .preferredColorScheme(.dark)
        .tint(Color.azul)
        .onChange(of: seleccion) { _, items in
            cargarFotos(items)
        }
    }

    func miniatura(_ nombre: String) -> some View {
        ZStack(alignment: .topTrailing) {
            if let img = FotosDiario.cargar(nombre) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.tarjeta)
                    .frame(width: 84, height: 84)
            }
            Button {
                quitarFoto(nombre)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.white, Color.black.opacity(0.7))
            }
            .buttonStyle(.borderless)
            .offset(x: 6, y: -6)
        }
    }

    func cargarFotos(_ items: [PhotosPickerItem]) {
        if items.isEmpty { return }
        Task {
            for it in items {
                if let data = try? await it.loadTransferable(type: Data.self),
                   let nombre = FotosDiario.guardar(data) {
                    fotos.append(nombre)
                    nuevas.append(nombre)
                }
            }
            seleccion = []
        }
    }

    func quitarFoto(_ nombre: String) {
        fotos.removeAll { $0 == nombre }
        if nuevas.contains(nombre) {
            nuevas.removeAll { $0 == nombre }
            FotosDiario.borrar(nombre)
        } else {
            paraBorrar.append(nombre)
        }
    }

    func cancelar() {
        for n in nuevas { FotosDiario.borrar(n) }
        cerrar()
    }

    func borrar() {
        if let o = original {
            for n in o.fotos ?? [] { FotosDiario.borrar(n) }
            for n in nuevas { FotosDiario.borrar(n) }
            almacen.eliminarCarrera(o.id)
        }
        cerrar()
    }

    func duracion(_ t: String) -> Int? {
        let limpio = t.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if limpio.isEmpty { return nil }
        let partes = limpio.split(separator: ":").map { String($0) }
        var nums: [Double] = []
        for p in partes {
            guard let v = Double(p) else { return nil }
            nums.append(v)
        }
        if nums.count == 1 { return Int(nums[0] * 60) }
        if nums.count == 2 { return Int(nums[0] * 60 + nums[1]) }
        if nums.count == 3 { return Int(nums[0] * 3600 + nums[1] * 60 + nums[2]) }
        return nil
    }

    func numero(_ t: String) -> Double? {
        let limpio = t.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if limpio.isEmpty { return nil }
        return Double(limpio)
    }

    func guardar() {
        guard let km = numero(kmTxt), km > 0, km < 1000 else {
            aviso = "Escribe los kilómetros (un número mayor que 0)"
            return
        }
        let tD = durTxt.trimmingCharacters(in: .whitespaces)
        let seg = duracion(tD)
        if !tD.isEmpty && seg == nil {
            aviso = "La duración no se entiende. Usa 32:15 o solo los minutos"
            return
        }
        let tN = desnivelTxt.trimmingCharacters(in: .whitespaces)
        let desn = numero(tN)
        if !tN.isEmpty && desn == nil {
            aviso = "El desnivel debe ser un número"
            return
        }
        let tP = pulsoTxt.trimmingCharacters(in: .whitespaces)
        let pul = numero(tP)
        if !tP.isEmpty && pul == nil {
            aviso = "El pulso debe ser un número"
            return
        }
        let textoNota = nota.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = original?.id ?? Int(Date().timeIntervalSince1970 * 1000)
        let c = Carrera(
            id: id,
            fecha: Fecha.clave(fecha),
            km: km,
            seg: seg,
            desnivel: desn,
            pulso: pul,
            nota: textoNota.isEmpty ? nil : textoNota,
            fotos: fotos.isEmpty ? nil : fotos
        )
        almacen.guardarCarrera(c)
        for n in paraBorrar { FotosDiario.borrar(n) }
        cerrar()
    }
}
