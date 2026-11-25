//
//  ContentView.swift
//  ZeekrControl
//

import SwiftUI

struct ContentView: View {
    @StateObject private var net = NetworkManager()
    @StateObject private var ble = BLEManager()

    @State private var logText = "Listo. Sistema en línea."

    let bgDark     = Color(red: 0.04, green: 0.06, blue: 0.08)
    let cardBg     = Color(red: 0.08, green: 0.11, blue: 0.14)
    let cardBorder = Color(red: 0.13, green: 0.19, blue: 0.25)
    let accentBlue = Color(red: 0.24, green: 0.66, blue: 1.0)
    let statusGreen = Color(red: 0.18, green: 0.82, blue: 0.54)
    let statusRed   = Color(red: 1.0, green: 0.35, blue: 0.35)
    let statusOrange = Color(red: 1.0, green: 0.69, blue: 0.13)
    let btnDark    = Color(red: 0.11, green: 0.15, blue: 0.20)

    var body: some View {
        ZStack {
            bgDark.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Cabecera
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zeekr 7X")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("VIN: L6T79NCE1SN010116")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)

                    // Tarjeta de Estado
                    VStack(alignment: .leading, spacing: 6) {
                        Text(net.connStatus)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(net.isLocalActive || net.isCloudActive ? statusGreen : statusRed)

                        Text(net.connDetail)
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        Text(ble.statusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ble.isConnected ? statusGreen : statusOrange)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBg)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(cardBorder, lineWidth: 1))

                    // Seccion BLE
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Canal Bluetooth LE (Cercanía)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentBlue)

                        HStack(spacing: 8) {
                            Button(action: { ble.startScan() }) {
                                Text("Buscar Carro BLE")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }

                            Button(action: { ble.disconnect() }) {
                                Text("Desconectar BLE")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Seccion Climatizacion (VHAL)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Control de Clima (VHAL)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentBlue)

                        // Fila 1: Clima On / Off
                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("hvac_on") }) {
                                Text("Encender Clima")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(statusGreen)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("hvac_off") }) {
                                Text("Apagar Clima")
                                    .font(.system(size: 14, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(statusRed)
                                    .cornerRadius(8)
                            }
                        }

                        // Fila 2: A/C Compresor
                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("hvac_ac", params: ["value": 1]) }) {
                                Text("A/C Compresor ON")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("hvac_ac", params: ["value": 0]) }) {
                                Text("A/C Compresor OFF")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        // Fila 3: Modo Auto / Max AC
                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("hvac_auto", params: ["value": 1]) }) {
                                Text("Modo Automático")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("hvac_max_ac", params: ["value": 1]) }) {
                                Text("Máximo Frío A/C")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        // Fila 4: Desempañar / Recirculacion
                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("hvac_defrost", params: ["value": 1]) }) {
                                Text("Desempañador")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("hvac_recirc", params: ["value": 1]) }) {
                                Text("Recirculación")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        // Fila 5: Ventilacion Delantera / Fila 2
                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("hvac_vent", params: ["value": 1]) }) {
                                Text("Ventilación Delantera")
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("hvac_vent_row2", params: ["value": 1]) }) {
                                Text("Ventilación Fila 2")
                                    .font(.system(size: 12))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        // Fila 6: Estado Clima
                        Button(action: { dispatchCmd("hvac_state") }) {
                            Text("Ver Estado Clima")
                                .font(.system(size: 13, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(btnDark)
                                .foregroundColor(accentBlue)
                                .cornerRadius(8)
                        }
                    }

                    // Seccion Diagnostico
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Diagnóstico y Conexión")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentBlue)

                        HStack(spacing: 8) {
                            Button(action: { net.checkStatus() }) {
                                Text("Refrescar Estado")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("ping") }) {
                                Text("Probar Ping")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        Button(action: { dispatchCmd("status") }) {
                            Text("Telemetría VHAL")
                                .font(.system(size: 13))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(btnDark)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }

                    // Seccion Carroceria (Experimental)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Carrocería (Experimental)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.gray)

                        HStack(spacing: 8) {
                            Button(action: { dispatchCmd("lock") }) {
                                Text("Bloquear (Exp)")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                            }
                            Button(action: { dispatchCmd("horn") }) {
                                Text("Bocina (Exp)")
                                    .font(.system(size: 13))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(btnDark)
                                    .foregroundColor(.gray)
                                    .cornerRadius(8)
                            }
                        }
                    }

                    // Registro de Eventos
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Registro de Eventos")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)

                        ScrollView {
                            Text(logText)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                        }
                        .frame(height: 140)
                        .background(cardBg)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(cardBorder, lineWidth: 1))
                    }
                }
                .padding(16)
            }
        }
        .onAppear {
            net.onLog = { appendLog($0) }
            ble.onLog = { appendLog($0) }
            net.checkStatus()
        }
    }

    private func dispatchCmd(_ action: String, params: [String: Any]? = nil) {
        if ble.isConnected {
            ble.sendCommand(action: action, params: params)
        } else {
            net.sendCommand(action: action, params: params)
        }
    }

    private func appendLog(_ msg: String) {
        DispatchQueue.main.async {
            var curr = self.logText
            if curr.count > 3000 {
                curr = String(curr.prefix(1500))
            }
            self.logText = "\(msg)\n\n\(curr)"
        }
    }
}
