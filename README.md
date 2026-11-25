# Zeekr Control iOS (iPhone)

Aplicación nativa para iPhone desarrollada en SwiftUI para el control directo y remoto del **Zeekr 7X** (VIN `L6T79NCE1SN010116`), sin servidores chinos ni intermediarios.

## Características

- **Diseño Nativo SwiftUI**: Interfaz oscura moderna ajustada a la identidad de Zeekr.
- **Canal Bluetooth LE (CoreBluetooth)**:
  * Servicio UUID: `F0A1C000-9A8B-4C3D-8E2F-1A2B3C4D5E6F`
  * Detección, negociación de MTU y ensamblado de paquetes de respuesta larga (`LEN|total|idx|chunks|data`).
  * Conexión directa al vehículo cuando estés cerca sin necesidad de red Wi-Fi ni datos.
- **Canal de Red Híbrido (URLSession)**:
  * Prioridad 1: Wi-Fi Local MiFi (`http://192.168.8.108:8790`).
  * Prioridad 2: Wi-Fi Hotspot del propio carro (`http://192.168.5.250:8790`).
  * Prioridad 3: Nube Cloudflare Worker (`https://zeekr-direct.johegocr.workers.dev`).
- **Control de Climatización VHAL Verificado**:
  * Encender Clima / Apagar Clima (`hvac_on`, `hvac_off`)
  * Compresor A/C: ON / OFF (`hvac_ac`)
  * Modo Automático (`hvac_auto`)
  * Máximo Frío A/C (`hvac_max_ac`)
  * Desempañador Delantero (`hvac_defrost`)
  * Recirculación de Aire (`hvac_recirc`)
  * Ventilación Frontal y Ventilación Fila 2 (`hvac_vent`, `hvac_vent_row2`)
  * Ver Estado Real del Clima (`hvac_state`)
- **Diagnóstico y Telemetría**:
  * Probar Ping (`ping`) y Telemetría VHAL completa (`status`).
- **Registro en Vivo**:
  * Consola inferior con respuestas y códigos de estado en tiempo real.

---

## Compilación del .IPA con GitHub Actions (Sin Mac)

Al igual que en EVA Copilot, la aplicación utiliza **XcodeGen** y **GitHub Actions** para compilar el paquete `.ipa` sin necesidad de una Mac física.

### Pasos:

1. Crea un repositorio en GitHub (ej. `zeekr-control-ios`). Debe ser **Público** para que los minutos de GitHub Actions sean gratuitos.
2. Sube esta carpeta (`D:\AppZeekr\ios`):
   ```bash
   cd D:\AppZeekr\ios
   git init
   git add .
   git commit -m "Zeekr Control iOS v1.0"
   git branch -M main
   git remote add origin https://github.com/TU_USUARIO/zeekr-control-ios.git
   git push -u origin main
   ```
3. En GitHub, ve a la pestaña **Actions** -> **Build Zeekr Control IPA** -> **Run workflow**.
4. En 5 a 8 minutos terminará de compilar.
5. Haz clic en el run finalizado y descarga el artefacto **`Zeekr-Control-unsigned`**.
6. Descomprímelo para obtener **`Zeekr-Control.ipa`**.

---

## Instalación en el iPhone con iLoader

1. Conecta tu iPhone por cable USB a la computadora.
2. Abre **iLoader**.
3. Selecciona el archivo `Zeekr-Control.ipa`.
4. Ingresa tus credenciales de Apple ID para firmar la aplicación (certificado gratuito de 7 días).
5. Pulsa Instalar.
6. En tu iPhone, ve a:
   **Ajustes -> General -> VPN y gestión de dispositivos -> [Tu Apple ID] -> Confiar**.
7. ¡Listo! Abre **Zeekr Control** en la pantalla de inicio de tu iPhone. Cada 7 u 8 días repites este mismo paso con iLoader para renovar la firma.
