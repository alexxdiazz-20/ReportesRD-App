# ReportesRD-App
Idea de app para reportes de accidentes utilizando supabase.

# ReportesRD 🚧

Aplicación móvil para reportar accidentes de tránsito y problemas viales de forma rápida y anónima. Cualquier persona puede reportar lo que está sucediendo en su zona sin necesidad de crear una cuenta ni iniciar sesión — solo abre la app, ve el mapa, y reporta.

Proyecto final de la asignatura **Desarrollo de Aplicaciones Móviles**, ITLA.

---

## 📱 De qué se trata

El problema que resuelve: cuando ocurre un accidente de tránsito o un problema vial (bache, semáforo dañado, calle bloqueada, etc.), no siempre hay una forma rápida y sencilla de avisar a otros o dejar registro de lo que pasó. ReportesRD busca ser esa vía — simple, sin fricción, sin login.

**Funcionalidades principales:**
- Ver un mapa con tu ubicación actual
- Crear un reporte nuevo (tipo de incidente, descripción, urgencia, fotos)
- Consultar el historial de reportes ya creados
- Cada reporte se genera con un ID único, sin necesidad de cuenta de usuario

---

## 🛠️ Stack tecnológico

- **Framework:** Flutter (Dart)
- **Base de datos / Backend:** Supabase (PostgreSQL)
- **Mapas:** Google Maps SDK (`google_maps_flutter`)
- **Ubicación:** `geolocator`
- **Fotos:** `image_picker`
- **IDs únicos:** `uuid`
- **Editor:** VS Code

---

## 🚀 Cómo correr el proyecto

### 1. Clonar el repositorio
```bash
git clone https://github.com/alexxdiazz-20/ReportesRD-App.git
cd ReportesRD-App
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Requisitos previos
- Tener Flutter SDK instalado ([guía oficial](https://docs.flutter.dev/get-started/install))
- Un emulador Android configurado (Android Studio → Device Manager), o un dispositivo físico conectado
- En Windows, activar el **Modo de desarrollador** (`start ms-settings:developers`) para que compilen los plugins nativos

### 4. Correr la app
```bash
flutter run
```
O desde VS Code, con el emulador seleccionado como dispositivo destino, dale a **Run > Start Debugging** (`F5`).

### 5. Notas de configuración
- El proyecto ya tiene configurada la API Key de Google Maps y los permisos de ubicación/cámara en `android/app/src/main/AndroidManifest.xml`
- Si vas a generar tu propia API Key (por ejemplo para producción), recuerda restringirla por nombre de paquete (`com.reportesrd.reportes_rd`) y huella SHA-1 en Google Cloud Console

---

## 🌳 Flujo de trabajo (Git)

- `main` → rama estable, solo se mergea desde `dev` cuando algo está probado y funcionando
- `dev` → rama de trabajo activo, donde cada quien hace commits de su parte
- Commits pequeños y documentados, uno por avance concreto (ej. `feat: agregar tema visual`, `config: permisos de camara y ubicacion`)

---

## ✅ Progreso actual

### Configuración base del proyecto
- [x] Proyecto Flutter creado e inicializado
- [x] Dependencias instaladas (mapas, geolocalización, cámara, uuid)
- [x] Permisos de Android configurados (ubicación, cámara)
- [x] API Key de Google Maps generada y restringida
- [x] Tema visual centralizado (`lib/theme/app_theme.dart`) — paleta de colores y tipografía consistente en toda la app

### Pantalla Home (Alex — Ricardo Alexander Díaz Santana)
- [x] Banner de bienvenida con descripción de la app
- [x] Mapa interactivo mostrando la ubicación actual del usuario
- [x] Botón "Crear Nuevo Reporte" que navega a la pantalla de creación, pasando la ubicación ya capturada por GPS
- [x] Diseño visual: mapa en recuadro, sección inferior tipo tarjeta
- [x] Modelo de datos del reporte (`lib/models/reporte_model.dart`) — incluye generación automática de ID único y soporte para múltiples fotos, listo para conectar a Supabase

### Pendiente
- [ ] Pantalla de creación de reporte (formulario completo) — **compañero encargado: [nombre]**
- [ ] Conexión a Supabase (guardar y leer reportes) — **compañero encargado: [nombre]**
- [ ] Pantalla de Historial de Reportes (Alex)
- [ ] Políticas RLS para las tablas de Supabase — **compañero encargado: [nombre]**

---

## 📂 Estructura del proyecto (parte de Home)

```
lib/
├── main.dart                        # Punto de entrada, rutas de la app
├── theme/
│   └── app_theme.dart               # Paleta de colores y estilos globales
├── models/
│   └── reporte_model.dart           # Estructura de datos de un reporte
└── screens/
    ├── home_screen.dart             # Pantalla principal (mapa + bienvenida)
    └── nuevo_reporte_screen.dart    # Placeholder — pendiente por el compañero
```

---

## 👥 Equipo

| Integrante | Parte asignada |
|---|---|
| Ricardo Alexander Díaz Santana (Alex) | Pantalla Home, Historial de Reportes |
| [Nombre] | Creación de Reportes, conexión a Supabase |
| [Nombre] | [Parte asignada] |