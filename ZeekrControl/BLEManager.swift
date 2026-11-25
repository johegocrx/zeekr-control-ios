//
//  BLEManager.swift
//  ZeekrControl
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let serviceUUID    = CBUUID(string: "F0A1C000-9A8B-4C3D-8E2F-1A2B3C4D5E6F")
    static let charCmdUUID    = CBUUID(string: "F0A1C001-9A8B-4C3D-8E2F-1A2B3C4D5E6F")
    static let charResUUID    = CBUUID(string: "F0A1C002-9A8B-4C3D-8E2F-1A2B3C4D5E6F")
    static let charStateUUID  = CBUUID(string: "F0A1C003-9A8B-4C3D-8E2F-1A2B3C4D5E6F")

    @Published var isConnected = false
    @Published var isScanning = false
    @Published var statusText = "BLE: Desconectado"

    var onLog: ((String) -> Void)?

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var charCmd: CBCharacteristic?
    private var charRes: CBCharacteristic?
    private var charState: CBCharacteristic?

    private var bleBuffer = ""

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScan() {
        guard centralManager.state == .poweredOn else {
            statusText = "BLE: Bluetooth apagado"
            onLog?("[BLE] El Bluetooth está desactivado en el iPhone.")
            return
        }
        isScanning = true
        statusText = "BLE: Escaneando..."
        onLog?("[BLE] Escaneando periférico Zeekr 7X...")
        centralManager.scanForPeripherals(withServices: [BLEManager.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScan() {
        if isScanning {
            centralManager.stopScan()
            isScanning = false
            if !isConnected {
                statusText = "BLE: Desconectado"
            }
            onLog?("[BLE] Escaneo detenido.")
        }
    }

    func disconnect() {
        stopScan()
        if let p = peripheral {
            centralManager.cancelPeripheralConnection(p)
        }
        peripheral = nil
        charCmd = nil
        charRes = nil
        charState = nil
        isConnected = false
        statusText = "BLE: Desconectado"
        onLog?("[BLE] Desconectado.")
    }

    func sendCommand(action: String, params: [String: Any]? = nil) {
        guard isConnected, let p = peripheral, let cmd = charCmd else {
            onLog?("[BLE] No hay conexión BLE activa.")
            return
        }

        var dict: [String: Any] = ["action": action]
        if let params = params {
            dict["params"] = params
        }

        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let jsonStr = String(data: data, encoding: .utf8) else {
            onLog?("[BLE] Error codificando comando JSON.")
            return
        }

        onLog?("-> [BLE] Enviando orden: \(action)...")
        writeChunks(json: jsonStr, peripheral: p, characteristic: cmd)
    }

    private func writeChunks(json: String, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        guard let raw = json.data(using: .utf8) else { return }
        bleBuffer = ""

        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        let room = max(16, mtu - 20)
        let total = raw.count
        let chunks = max(1, (total + room - 1) / room)

        for i in 0..<chunks {
            let start = i * room
            let len = min(room, total - start)
            let sub = raw.subdata(in: start..<(start + len))
            let body = String(data: sub, encoding: .utf8) ?? ""
            let head = "LEN|\(total)|\(i)|\(chunks)|"
            let piece = head + body

            DispatchQueue.global().asyncAfter(deadline: .now() + Double(i) * 0.06) { [weak self] in
                guard let self = self, let pieceData = piece.data(using: .utf8) else { return }
                peripheral.writeValue(pieceData, for: characteristic, type: .withResponse)
            }
        }
    }

    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            statusText = "BLE: Listo para escanear"
            onLog?("[BLE] Bluetooth activado y listo.")
        case .poweredOff:
            isConnected = false
            statusText = "BLE: Bluetooth apagado"
            onLog?("[BLE] Bluetooth desactivado.")
        case .unauthorized:
            statusText = "BLE: Sin permiso"
            onLog?("[BLE] Permiso de Bluetooth denegado.")
        default:
            statusText = "BLE: No disponible"
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        onLog?("[BLE] Vehículo encontrado: \(peripheral.name ?? "Zeekr 7X") (\(RSSI) dBm)")
        stopScan()
        self.peripheral = peripheral
        peripheral.delegate = self
        statusText = "BLE: Conectando..."
        central.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        statusText = "BLE: Conectado. Descubriendo..."
        onLog?("[BLE] Conexión establecida. Descubriendo servicios...")
        peripheral.discoverServices([BLEManager.serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusText = "BLE: Error al conectar"
        onLog?("[BLE] Falló la conexión: \(error?.localizedDescription ?? "Desconocido")")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        statusText = "BLE: Desconectado"
        onLog?("[BLE] Desconectado del vehículo.")
        charCmd = nil
        charRes = nil
        charState = nil
    }

    // MARK: - CBPeripheralDelegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for s in services where s.uuid == BLEManager.serviceUUID {
            peripheral.discoverCharacteristics([BLEManager.charCmdUUID, BLEManager.charResUUID, BLEManager.charStateUUID], for: s)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let chars = service.characteristics else { return }
        for c in chars {
            if c.uuid == BLEManager.charCmdUUID { charCmd = c }
            if c.uuid == BLEManager.charResUUID {
                charRes = c
                peripheral.setNotifyValue(true, for: c)
            }
            if c.uuid == BLEManager.charStateUUID { charState = c }
        }

        if charCmd != nil && charRes != nil {
            isConnected = true
            statusText = "BLE: Conectado al vehículo"
            onLog?("[BLE] Enlace GATT completado y listo para órdenes.")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value, let text = String(data: data, encoding: .utf8) else { return }

        if !text.hasPrefix("LEN|") {
            onLog?("<- [BLE] \(text)")
            return
        }

        let parts = text.components(separatedBy: "|")
        guard parts.count >= 5,
              let total = Int(parts[1]),
              let idx = Int(parts[2]),
              let chunks = Int(parts[3]) else { return }

        let body = parts[4]
        if idx == 0 { bleBuffer = "" }
        bleBuffer += body

        if idx + 1 < chunks {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.08) { [weak self] in
                guard let self = self, let p = self.peripheral, let cmd = self.charCmd else { return }
                let nextReq = "{\"action\":\"_next\"}"
                if let nextData = nextReq.data(using: .utf8) {
                    p.writeValue(nextData, for: cmd, type: .withResponse)
                }
            }
        } else {
            onLog?("<- [BLE RESPUESTA]:\n\(bleBuffer)")
            bleBuffer = ""
        }
    }
}
