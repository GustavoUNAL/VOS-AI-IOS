# VOS IA — iOS nativo (SwiftUI)

Repositorio: [GustavoUNAL/VOS-AI-IOS](https://github.com/GustavoUNAL/VOS-AI-IOS)

Cliente **SwiftUI nativo** de VOS IA. No llama a OpenAI. Usa el mismo backend que la web:

| Pieza | Repo |
|-------|------|
| API | [vos-api](https://github.com/GustavoUNAL/vos-api) |
| Web | [vos-front](https://github.com/GustavoUNAL/vos-front) |
| iOS nativo | este repo |

## Requisitos

- Xcode 16+
- iOS 17+
- API local en `http://127.0.0.1:3000` (Debug) o `https://vos-ia.com/backend` (Release)
- Front web en `http://localhost:5173` (Debug) o `https://vos-ia.com` (Release) para módulos embebidos

## Abrir y ejecutar

```bash
git clone https://github.com/GustavoUNAL/VOS-AI-IOS.git
cd VOS-AI-IOS
open VOSIA.xcodeproj
```

Seleccione un simulador iPhone y pulse Run.

O regenerar el proyecto Xcode con [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
open VOSIA.xcodeproj
```

## Paridad con la web

| Área | iOS |
|------|-----|
| Main (Aura, Notas, Pendientes, Agenda, Proyectos, Dinero) | Nativo |
| Ideas / Bienestar | Nativo (Cuenta → Más en Main) |
| Operación, Asistente empresa, Finanzas, Proyectos, Tareas | Nativo |
| Catálogo, Recetas, Stock, Ventas, POS, Tienda, Compras, Personal, Cierre, Agenda de citas, Clientes, Servicios, Enlace público | **Web embebida** (misma UI que vos-ia.com, sesión JWT inyectada) |

Los módulos “Completo” del launcher abren `WebModuleView` con handoff `#/native-handoff?access_token=…&next=e/{slug}/{view}`.

## Contrato con el backend

- `POST /auth/login` → JWT (Keychain); acepta usuario corto o email
- `GET /auth/google?mobile=1` → deep link `vosia://google-auth?access_token=…`
- `GET /auth/me`
- `GET /platform/companies` (platform admin)
- `POST /auth/platform/enter-company`
- `POST /auth/platform/home`
- `POST /assistant/ask`, `POST /personal/aura/ask` (`mode`: `chat` \| `call`)
- `GET/POST/PATCH/DELETE /journal`
- `GET /operations/day`
- Header `Authorization: Bearer …` y `X-Company-Id`

## Nota

`vos-front/ios` es el shell Capacitor (web embebida). Este repo es la app nativa con módulos SwiftUI + WebView para el resto.
