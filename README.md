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

Build por terminal:

```bash
xcodebuild -project VOSIA.xcodeproj -scheme VOSIA \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  CODE_SIGNING_ALLOWED=NO build
```

## Contrato con el backend

- `POST /auth/login` → JWT (Keychain); acepta usuario corto (`omar`) o email
- `GET /auth/google?mobile=1` → deep link `vosia://google-auth?access_token=…`
- `GET /auth/me`
- `GET /platform/companies` (platform admin)
- `POST /auth/platform/enter-company` (sin `reason`)
- `POST /auth/platform/home`
- `POST /assistant/ask` con `{ question, history? }` → `{ answer }`
- `GET/POST/PATCH/DELETE /journal`
- `GET /operations/day`
- Header `Authorization: Bearer …`
- Header `X-Company-Id` cuando hay empresa activa

El historial del chat vive en la app (igual que la web). No hay segundo motor de IA.

## Flujo actual

1. Login (password o Google).
2. Platform admin → lista de empresas (`/platform/companies`).
3. Al entrar a una empresa → Inicio (launcher) + Asistente + Diario + Operación + Cuenta.
4. Módulos aún no nativos aparecen como “Próximamente” (mismos endpoints que la web).

## Nota

`vos-front/ios` es el shell Capacitor (web embebida). Este repo es la app nativa.
