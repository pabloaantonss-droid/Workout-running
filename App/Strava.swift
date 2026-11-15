import SwiftUI
import AuthenticationServices

final class Strava: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let compartido = Strava()

    @Published var estado = ""
    @Published var cargando = false
    @Published var conectado = false

    private var sesionWeb: ASWebAuthenticationSession?
    private let ud = UserDefaults.standard

    override init() {
        super.init()
        conectado = ud.string(forKey: "stravaRefresh") != nil
    }

    var clientID: String { return ud.string(forKey: "stravaID") ?? "" }
    var secreto: String { return ud.string(forKey: "stravaSecret") ?? "" }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let escenas = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let ventanas = escenas.flatMap { $0.windows }
        return ventanas.first(where: { $0.isKeyWindow }) ?? ASPresentationAnchor()
    }

    @MainActor
    func conectar() async {
        guard !clientID.isEmpty, !secreto.isEmpty else {
            estado = "Falta el Client ID o el Client Secret"
            return
        }
        let texto = "https://www.strava.com/oauth/authorize?client_id=\(clientID)&redirect_uri=deporte://localhost&response_type=code&approval_prompt=auto&scope=activity:read_all"
        guard let url = URL(string: texto) else {
            estado = "Client ID no valido"
            return
        }
        do {
            let vuelta: URL = try await withCheckedThrowingContinuation { cont in
                let s = ASWebAuthenticationSession(url: url, callbackURLScheme: "deporte") { u, e in
                    if let u = u {
                        cont.resume(returning: u)
                    } else if let e = e {
                        cont.resume(throwing: e)
                    } else {
                        cont.resume(throwing: URLError(.cancelled))
                    }
                }
                s.presentationContextProvider = self
                s.prefersEphemeralWebBrowserSession = false
                self.sesionWeb = s
                s.start()
            }
            let items = URLComponents(url: vuelta, resolvingAgainstBaseURL: false)?.queryItems
            guard let code = items?.first(where: { $0.name == "code" })?.value else {
                estado = "Strava no devolvio ningun codigo"
                return
            }
            try await pedirToken(["grant_type": "authorization_code", "code": code])
            conectado = true
            await actualizar()
        } catch {
            estado = "Error: \(error.localizedDescription)"
        }
    }

    func pedirToken(_ extra: [String: String]) async throws {
        guard let url = URL(string: "https://www.strava.com/oauth/token") else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        var p = extra
        p["client_id"] = clientID
        p["client_secret"] = secreto
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var partes: [String] = []
        for (k, v) in p {
            let cod = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            partes.append("\(k)=\(cod)")
        }
        req.httpBody = partes.joined(separator: "&").data(using: .utf8)
        let (data, _) = try await URLSession.shared.data(for: req)
        guard let j = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let acc = j["access_token"] as? String,
              let ref = j["refresh_token"] as? String,
              let exp = (j["expires_at"] as? NSNumber)?.doubleValue else {
            throw URLError(.badServerResponse)
        }
        ud.set(acc, forKey: "stravaAccess")
        ud.set(ref, forKey: "stravaRefresh")
        ud.set(exp, forKey: "stravaExpira")
    }

    func asegurarToken() async throws {
        let exp = ud.double(forKey: "stravaExpira")
        if exp - 60 > Date().timeIntervalSince1970 { return }
        guard let ref = ud.string(forKey: "stravaRefresh") else { throw URLError(.userAuthenticationRequired) }
        try await pedirToken(["grant_type": "refresh_token", "refresh_token": ref])
    }

    @MainActor
    func actualizar() async {
        guard conectado else {
            estado = "Conecta Strava primero"
            return
        }
        cargando = true
        defer { cargando = false }
        do {
            try await asegurarToken()
            guard let url = URL(string: "https://www.strava.com/api/v3/athlete/activities?per_page=200") else { return }
            var req = URLRequest(url: url)
            req.setValue("Bearer \(ud.string(forKey: "stravaAccess") ?? "")", forHTTPHeaderField: "Authorization")
            let (data, resp) = try await URLSession.shared.data(for: req)
            if let h = resp as? HTTPURLResponse, h.statusCode != 200 {
                estado = "Strava respondio con el codigo \(h.statusCode)"
                return
            }
            guard let arr = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                estado = "Respuesta no valida de Strava"
                return
            }
            var lista: [Carrera] = []
            for a in arr {
                let tipo = (a["sport_type"] as? String) ?? (a["type"] as? String) ?? ""
                if tipo != "Run" && tipo != "TrailRun" { continue }
                guard let id = (a["id"] as? NSNumber)?.intValue,
                      let f = a["start_date_local"] as? String, f.count >= 10 else { continue }
                let km = ((a["distance"] as? NSNumber)?.doubleValue ?? 0) / 1000.0
                let seg = (a["moving_time"] as? NSNumber)?.intValue ?? 0
                let desn = (a["total_elevation_gain"] as? NSNumber)?.doubleValue ?? 0
                let pulso = (a["average_heartrate"] as? NSNumber)?.doubleValue
                let nombre = (a["name"] as? String) ?? ""
                lista.append(Carrera(id: id, fecha: String(f.prefix(10)), nombre: nombre,
                                     km: km, seg: seg, desnivel: desn, pulso: pulso))
            }
            lista.sort { x, y in
                if x.fecha != y.fecha { return x.fecha > y.fecha }
                return x.id > y.id
            }
            Almacen.compartido.datos.carreras = lista
            Almacen.compartido.guardar()
            estado = "Actualizado"
        } catch {
            estado = "Error: \(error.localizedDescription)"
        }
    }
}
