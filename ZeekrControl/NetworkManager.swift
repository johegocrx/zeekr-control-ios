//
//  NetworkManager.swift
//  ZeekrControl
//

import Foundation

class NetworkManager: ObservableObject {
    static let urlLocal   = "http://192.168.8.108:8790"
    static let urlHotspot = "http://192.168.5.250:8790"
    static let urlRemoto  = "https://zeekr-direct.johegocr.workers.dev"
    static let token      = "zeekr-local"

    @Published var connStatus = "Comprobando enlaces..."
    @Published var connDetail = "Iniciando verificación..."
    @Published var isLocalActive = false
    @Published var isCloudActive = false

    var onLog: ((String) -> Void)?

    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 10.0
        self.session = URLSession(configuration: config)
    }

    func checkStatus() {
        DispatchQueue.main.async {
            self.connStatus = "Comprobando servidores..."
            self.connDetail = "Consultando canal local y nube..."
        }

        // 1. Probar local MiFi
        checkUrl(NetworkManager.urlLocal + "/api/health", timeout: 1.5) { [weak self] okLocal, resLocal in
            if okLocal && (resLocal?.contains("\"ok\":true") == true) {
                DispatchQueue.main.async {
                    self?.connStatus = "Conectado (MiFi Local)"
                    self?.connDetail = "Canal local ultrarrápido"
                    self?.isLocalActive = true
                }
                self?.onLog?("[LOCAL] Salud vehículo OK: \(resLocal ?? "")")
                return
            }

            // 2. Probar Nube Cloudflare
            self?.checkUrl(NetworkManager.urlRemoto + "/api/state", timeout: 4.0) { okCloud, resCloud in
                DispatchQueue.main.async {
                    if okCloud && (resCloud?.contains("\"car\"") == true || resCloud?.contains("\"online\"") == true || resCloud?.contains("\"ok\":true") == true) {
                        self?.connStatus = "Conectado (Nube Worker)"
                        self?.connDetail = "Servidor Cloudflare activo"
                        self?.isCloudActive = true
                        self?.onLog?("[NUBE] Servidor y cola en línea:\n\(resCloud ?? "")")
                    } else {
                        self?.connStatus = "Sin conexión"
                        self?.connDetail = "Servidores no disponibles"
                        self?.onLog?("[ERROR] Sin respuesta de los servidores")
                    }
                }
            }
        }
    }

    func sendCommand(action: String, params: [String: Any]? = nil, completion: ((Bool) -> Void)? = nil) {
        onLog?("-> Enviando orden: \(action)...")

        var payload: [String: Any] = ["action": action]
        if let params = params {
            payload["params"] = params
        }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            onLog?("[ERROR] Falló serialización del comando")
            completion?(false)
            return
        }

        let targetUrl = isLocalActive ? NetworkManager.urlLocal : NetworkManager.urlRemoto
        let etiqueta = isLocalActive ? "[LOCAL]" : "[NUBE]"

        postHttp(urlStr: targetUrl + "/api/cmd", body: bodyData, timeout: isLocalActive ? 2.5 : 7.0) { [weak self] ok, res in
            if ok, let res = res, res.contains("\"ok\":true") {
                DispatchQueue.main.async {
                    self?.connDetail = "Orden enviada correctamente"
                }
                self?.onLog?("<- \(etiqueta) \(action):\n\(res)")
                completion?(true)
            } else if self?.isLocalActive == true {
                self?.onLog?("-> Reintentando por nube Worker...")
                self?.postHttp(urlStr: NetworkManager.urlRemoto + "/api/cmd", body: bodyData, timeout: 7.0) { okCloud, resCloud in
                    if okCloud, let resCloud = resCloud, resCloud.contains("\"ok\":true") {
                        self?.onLog?("<- [NUBE] \(action):\n\(resCloud)")
                        completion?(true)
                    } else {
                        self?.onLog?("<- [FALLO] \(action): Sin respuesta")
                        completion?(false)
                    }
                }
            } else {
                self?.onLog?("<- [FALLO] \(action): Sin respuesta del servidor")
                completion?(false)
            }
        }
    }

    private func checkUrl(_ urlStr: String, timeout: TimeInterval, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlStr) else { completion(false, nil); return }
        var req = URLRequest(url: url)
        req.timeoutInterval = timeout
        req.setValue(NetworkManager.token, forHTTPHeaderField: "x-token")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: req) { data, resp, err in
            if let data = data, let text = String(data: data, encoding: .utf8), (resp as? HTTPURLResponse)?.statusCode ?? 0 < 400 {
                completion(true, text)
            } else {
                completion(false, nil)
            }
        }.resume()
    }

    private func postHttp(urlStr: String, body: Data, timeout: TimeInterval, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlStr) else { completion(false, nil); return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = timeout
        req.httpBody = body
        req.setValue(NetworkManager.token, forHTTPHeaderField: "x-token")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        session.dataTask(with: req) { data, resp, err in
            if let data = data, let text = String(data: data, encoding: .utf8), (resp as? HTTPURLResponse)?.statusCode ?? 0 < 400 {
                completion(true, text)
            } else {
                completion(false, nil)
            }
        }.resume()
    }
}
