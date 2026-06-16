# QuePlan — App iOS (SwiftUI)

App móvil para **descubrir, reservar y publicar eventos**, con dos tipos de cuenta:
**Negocio** (publica y administra eventos) y **Cliente/Turista** (descubre y reserva).
Construida en **SwiftUI** consumiendo la API REST de QuePlan.

## Cómo abrir y ejecutar

1. Abre `QuePlan.xcodeproj` en **Xcode 16 o superior** (en una Mac).
2. Selecciona un simulador de iPhone (iOS 17+).
3. Pulsa **Run** (⌘R).

> El proyecto usa *grupos sincronizados con el sistema de archivos* (Xcode 16),
> por lo que cualquier archivo dentro de `QuePlan/` se incluye automáticamente.
> El `Info.plist` ya permite tráfico HTTP (la API corre sobre `http://`).

### Usuarios de prueba (de `endpoints.txt`)

| Tipo     | Usuario        | Contraseña |
|----------|----------------|------------|
| Negocio  | `soumaya`      | `12345`    |
| Negocio  | `bellas_artes` | `12345`    |
| Cliente  | `ruth`         | `12345`    |
| Cliente  | `mariana`      | `12345`    |

El login detecta automáticamente si la cuenta es de cliente o de negocio.

## Arquitectura (MVVM)

```
QuePlan/
├─ App/            QuePlanApp (entry) + RootView (enrutado por sesión)
├─ Config/         APIConfig (URL base de la API)
├─ Models/         Modelos Codable de todos los endpoints
├─ Services/       QueplanService (capa de red, async/await)
├─ ViewModels/     SessionManager + ViewModels @MainActor por pantalla
├─ Theme/          Paleta, botones, campos y estrellas reutilizables
└─ Views/
   ├─ Shared/      Componentes, logo, diálogos, términos y ayuda
   ├─ Auth/        Bienvenida, login, tipo de cuenta, registros
   ├─ Cliente/     Home/catálogo, filtros, detalle, reserva, calendario,
   │               historial, opinión y perfil
   └─ Negocio/     Calendario, detalle/administración, crear-editar-repetir
                   evento, historial y perfil
```

## Pantallas implementadas

**Iniciales:** Bienvenida · Login · Selección de tipo de cuenta.

**Cliente:** Registro · Editar perfil · Inicio (catálogo + búsqueda) ·
Filtros (calificación / tarifa) · Detalle de evento + opiniones ·
Reserva ("Asegura tu lugar") · Calendario "Mi experiencia" · Historial ·
Modal de opinión/calificación · Términos y Ayuda.

**Negocio:** Registro · Calendario de eventos · Detalle del evento con
"Personas interesadas" (confirmar/cancelar reservas) · Crear / Editar /
Repetir evento · Cancelar evento (con diálogos y aviso de afectados) ·
Historial · Mi perfil · Editar perfil.

## Notas de integración con la API

- La API responde **HTTP 200 incluso en errores**, con el detalle en
  `{"response": "..."}`. `QueplanService` intercepta esos casos y lanza
  `APIError.server(mensaje)` para mostrarlos en la UI.
- Las **fechas** viajan como `"yyyy-MM-dd HH:mm:ss"` y los **booleanos** de
  evento como enteros `0/1` (ver `Int.asBool` / `Bool.asInt`).
- `APIConfig.baseURL` apunta al servidor de pruebas; cámbialo a tu entorno
  local (`http://localhost:8080/QuePlan/api`) si lo necesitas.
