# Informe de integración — VOS IA iOS nativo

Fecha: 2026-11-21

## 1. Arquitectura encontrada

- `vos-api` (NestJS): motor único de IA (`BusinessAssistantService` + `BusinessInsightsService` + OpenAI Chat Completions).
- `vos-front` (React): cliente web; `POST /assistant/ask` con `history` en el cliente.
- `vos-front/ios`: Capacitor (híbrido), no SwiftUI nativo.
- `AiConversation` / `AiMessage` / `AiAgent`: solo en Prisma; **cero uso** en `vos-api/src`.
- El asistente es conversacional (lectura de contexto). **No** hay tool calling.

## 2. Arquitectura implementada

```
SwiftUI (vos-ios)
  → APIClient (JWT + X-Company-Id)
  → vos-api
       → /auth/*
       → /assistant/ask  (OpenAI solo aquí)
       → /journal, /operations/day
```

Sin segundo motor de IA. Sin WebView. Sin API key de OpenAI en el cliente.

## 3. Archivos creados

Proyecto nuevo `vos-ios/` (SwiftUI, iOS 17+), generado con XcodeGen (`project.yml`).

## 4. Archivos modificados

Ninguno en `vos-api` ni `vos-front` para esta integración (contrato conservado).

## 5. Endpoints integrados

| Endpoint | Uso iOS | Verificado |
|----------|---------|------------|
| GET /health | disponibilidad local | 200 |
| POST /auth/login | login | 401 con credenciales inválidas (contrato) |
| GET /auth/me | bootstrap sesión | 401 sin JWT |
| POST /assistant/ask | chat | 401 sin JWT |
| POST /auth/switch-company | cambio empresa | cableado |
| POST /auth/platform/enter-company | admin plataforma | cableado |
| GET/POST/PATCH/DELETE /journal | módulo diario | cableado |
| GET /operations/day | operación del día | cableado (requiere permisos sales/finance) |

## 6. Autenticación

- JWT en Keychain (`com.vosia.app`).
- `companyId` en Keychain.
- Headers: `Authorization`, `X-Company-Id`.
- 401 limpia sesión.
- Sin OpenAI key en la app.

## 7. Asistente

- Mismo contrato que la web: `{ question, history? }` → `{ answer }`.
- Historial en memoria de `SessionStore` (máx. 12, como el DTO).
- Saludo con `__SESSION_START__`.
- UI: carga, reintento, burbujas, scroll.

## 8. Módulos

- Diario: API real `/journal`.
- Operación: API real `/operations/day` (distingue datos de módulo vs texto de IA).
- Cuenta: perfil, cambio de empresa, logout.
- Ventas/POS/inventario: APIs existen en backend; pantallas nativas pendientes (no inventadas).

## 9. Pruebas ejecutadas

| Prueba | Resultado |
|--------|-----------|
| `xcodebuild` iPhone 17 Simulator | **BUILD SUCCEEDED** |
| health / auth barriers / assistant 401 | OK |
| `vos-front` `tsc -b` | OK (sin regresiones de tipado) |
| Login con cuenta real + ask autenticado | **No ejecutado** (sin credenciales en esta sesión) |

## 10. Problemas encontrados

- pbxproj manual rechazado por Xcode 26 → resuelto con XcodeGen.
- `foregroundStyle(.secondary : .red)` no compila → corregido con `Color`.

## 11. Funcionalidades que aún no existen

- Tool calling / agente que ejecuta operaciones.
- Memoria de conversación en servidor (`AiConversation` no cableada).
- Historial compartido web ↔ iOS.
- Pantallas nativas completas de POS, ventas, inventario, etc.
- Google Sign-In nativo (en iOS se usa email/password).

## 12. Siguiente fase recomendada

1. Probar login real en simulador contra API local.
2. Ampliar módulos nativos consumiendo APIs ya usadas por la web.
3. Si se desea agente con acciones: añadir tools en **backend** de forma retrocompatible; iOS solo consume el mismo `/assistant/ask` (o un endpoint versionado).
