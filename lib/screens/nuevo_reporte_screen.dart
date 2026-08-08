import 'dart:io';

import 'package:flutter/foundation.dart'; // Factory
import 'package:flutter/gestures.dart'; // reconocedores de gestos para el mapa
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/reporte_model.dart';
import '../services/dispositivo_service.dart'; // <-- IMPORT NUEVO
import '../services/reporte_service.dart';
import '../theme/app_theme.dart';

/// Pantalla de creación de un reporte (Tarea 3).
///
/// Recibe del Home la ubicación que este ya capturó por GPS (para no volver
/// a pedir permisos ni leer el GPS otra vez) y la usa como punto de partida.
/// A partir de ahí el usuario arma el reporte: elige el tipo de incidente,
/// ajusta la ubicación exacta en el mapa, sube una o varias fotos, escribe
/// una descripción y marca la urgencia.
///
/// Se deja como StatefulWidget porque toda esta pantalla es "estado que
/// cambia mientras el usuario la usa" (tipo seleccionado, marcador movido,
/// fotos agregadas, texto escrito). El resultado final se empaqueta en un
/// [ReporteModel], listo para que el compañero de base de datos lo mande a
/// Supabase.
class NuevoReporteScreen extends StatefulWidget {
  const NuevoReporteScreen({super.key});

  @override
  State<NuevoReporteScreen> createState() => _NuevoReporteScreenState();
}

class _NuevoReporteScreenState extends State<NuevoReporteScreen> {
  // Selecciones del formulario. Empiezan "sin elegir" para poder validar
  // que el usuario realmente escogió algo antes de enviar.
  TipoIncidente? _tipoSeleccionado;
  NivelUrgencia _urgencia = NivelUrgencia.media; // media como punto medio sensato

  // Controlador del campo de descripción. Se libera en dispose() para no
  // dejar memoria colgando cuando la pantalla se cierra.
  final TextEditingController _descripcionController = TextEditingController();

  // image_picker: puente hacia la cámara/galería del teléfono.
  final ImagePicker _selectorImagenes = ImagePicker();

  // Rutas de las fotos que el usuario ya agregó. El modelo soporta varias,
  // así que guardamos una lista y no una sola foto.
  final List<String> _rutasFotos = [];

  // Bytes de cada foto, capturados EN EL MOMENTO de elegirla. En web la URL
  // blob: que devuelve image_picker puede quedar revocada después de un rato,
  // así que no se puede re-leer al enviar; por eso se retiene la data aquí.
  final List<Uint8List> _fotosBytes = [];

  // Ubicación del reporte. Arranca en la que envía el Home y el usuario la
  // puede ajustar moviendo el marcador en el mapa.
  GoogleMapController? _mapController;
  LatLng? _ubicacionSeleccionada;

  // Bandera para leer los argumentos de navegación una sola vez. Sin esto,
  // didChangeDependencies podría re-pisar la ubicación que el usuario ya
  // ajustó en el mapa.
  bool _argumentosLeidos = false;

  // Mientras se genera/lee el ID del dispositivo y se envía el reporte,
  // deshabilitamos el botón para evitar doble envío por doble tap.
  bool _enviando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentosLeidos) return;

    // Los argumentos vienen del Navigator.pushNamed() en HomeScreen, como un
    // Map con 'latitud' y 'longitud' (la ubicación ya capturada por GPS).
    final argumentos = ModalRoute.of(context)!.settings.arguments as Map;
    final double latitud = argumentos['latitud'];
    final double longitud = argumentos['longitud'];

    _ubicacionSeleccionada = LatLng(latitud, longitud);
    _argumentosLeidos = true;
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Abre una hoja inferior para que el usuario elija de dónde sacar la foto:
  /// tomarla con la cámara o escogerla de la galería. Es más cómodo que
  /// forzar una sola opción.
  Future<void> _agregarFoto() async {
    final ImageSource? fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primario),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primario),
                title: const Text('Elegir de la galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    // Si cerró la hoja sin elegir, no hacemos nada.
    if (fuente == null) return;

    final XFile? imagen = await _selectorImagenes.pickImage(
      source: fuente,
      imageQuality: 70, // comprime un poco para que el reporte no pese de más
    );
    if (imagen == null) return;

    // Se leen los bytes inmediatamente, cuando el blob sigue disponible.
    final Uint8List bytes = await imagen.readAsBytes();

    // Guard obligatorio: pudo haberse cerrado la pantalla mientras el usuario
    // estaba en la cámara/galería. Sin este chequeo, setState reventaría.
    if (!mounted) return;
    setState(() {
      _rutasFotos.add(imagen.path);
      _fotosBytes.add(bytes);
    });
  }

  /// Quita una foto de la lista (por si el usuario se arrepiente o se equivocó).
  void _quitarFoto(int indice) {
    setState(() {
      _rutasFotos.removeAt(indice);
      _fotosBytes.removeAt(indice);
    });
  }

  /// Valida el formulario y, si todo está bien, arma el [ReporteModel],
  /// sube las fotos y guarda el reporte en Supabase.
  ///
  /// Ahora es async porque hay que leer/generar el ID del dispositivo
  /// (DispositivoService) antes de poder armar el ReporteModel, ya que
  /// 'creadoPor' es un campo requerido del modelo.
  Future<void> _enviarReporte() async {
    // Validaciones mínimas: sin tipo o sin descripción, el reporte no sirve.
    if (_tipoSeleccionado == null) {
      _mostrarAviso('Selecciona el tipo de incidente.');
      return;
    }
    if (_descripcionController.text.trim().isEmpty) {
      _mostrarAviso('Escribe una descripción del problema.');
      return;
    }

    setState(() => _enviando = true);

    // ID único de este dispositivo (se genera una sola vez y se reutiliza
    // siempre). Sirve para que "Mis Reportes" en el Historial pueda filtrar
    // y mostrar solo lo que este dispositivo ha reportado, sin login.
    final idDispositivo = await DispositivoService.obtenerIdDispositivo();

    // Guard: la pantalla pudo haberse cerrado mientras esperábamos el ID.
    if (!mounted) return;

    final reporte = ReporteModel(
      tipo: _tipoSeleccionado!,
      descripcion: _descripcionController.text.trim(),
      latitud: _ubicacionSeleccionada!.latitude,
      longitud: _ubicacionSeleccionada!.longitude,
      rutasFotos: _rutasFotos,
      urgencia: _urgencia,
      creadoPor: idDispositivo, // <-- CAMPO NUEVO
    );

    // Guarda en Supabase: primero sube las fotos al bucket privado y luego
    // inserta la fila. Si algo falla, se avisa y el usuario puede reintentar.
    try {
      await ReporteService.guardarReporte(reporte, _fotosBytes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      debugPrint('Error guardando reporte: $e');
      _mostrarAviso('No se pudo guardar el reporte: $e');
      return;
    }

    if (!mounted) return;
    setState(() => _enviando = false);

    // Confirmamos visualmente que el reporte se guardó, mostrando el ID
    // único que se generó solo (sin necesidad de login).
    _mostrarConfirmacion(reporte);
  }

  /// Aviso corto para errores de validación.
  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: AppColors.acento),
    );
  }

  /// Diálogo de confirmación: le muestra al usuario que su reporte quedó
  /// listo y regresa al Home al aceptar.
  void _mostrarConfirmacion(ReporteModel reporte) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.urgenciaBaja, size: 48),
          title: const Text('¡Reporte creado!'),
          content: Text(
            'Tu reporte se registró correctamente.\n\n'
            'ID: ${reporte.id.substring(0, 8)}...',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // cierra el diálogo
                Navigator.pop(context); // vuelve al Home
              },
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Reporte')),
      // ScrollConfiguration con un comportamiento propio: quita el efecto de
      // "estiramiento" elástico de Android (overscroll stretch), que hacía
      // que la pantalla se sintiera rara y se deformara al desplazarse.
      body: ScrollConfiguration(
        behavior: const _ScrollFirme(),
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTituloSeccion('Tipo de incidente'),
            _buildSelectorTipo(),
            const SizedBox(height: 20),

            _buildTituloSeccion('Ubicación del reporte'),
            _buildTextoAyuda('Toca el mapa o arrastra el marcador para ajustar el punto exacto.'),
            _buildMapaSeleccion(),
            const SizedBox(height: 20),

            _buildTituloSeccion('Foto del problema'),
            _buildTextoAyuda(
                'Opcional, pero una foto ayuda a entender mejor lo que pasó. '
                'Evita capturar caras o placas de vehículos.'),
            _buildSeccionFotos(),
            const SizedBox(height: 20),

            _buildTituloSeccion('Descripción'),
            _buildCampoDescripcion(),
            const SizedBox(height: 20),

            _buildTituloSeccion('Nivel de urgencia'),
            _buildSelectorUrgencia(),
            const SizedBox(height: 28),

            _buildBotonEnviar(),
          ],
        ),
        ),
      ),
    );
  }

  /// Título de cada sección del formulario. Se centraliza en un helper para
  /// que todos los títulos se vean igual y cambiarlos sea en un solo lugar.
  Widget _buildTituloSeccion(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(texto, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  /// Texto de ayuda gris debajo de algunos títulos, para explicarle al
  /// usuario qué hacer sin saturar la pantalla.
  Widget _buildTextoAyuda(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(texto, style: Theme.of(context).textTheme.bodyMedium),
    );
  }

  /// Botones de tipo de incidente (Tarea 3 - item 1).
  ///
  /// Se muestran los tipos del modelo como tarjetas tocables en fila.
  /// La seleccionada se resalta con el color primario; así el usuario ve de
  /// un vistazo qué escogió, sin tener que abrir un menú desplegable.
  Widget _buildSelectorTipo() {
    return Row(
      children: [
        _buildTarjetaTipo(TipoIncidente.accidente, Icons.car_crash, 'Accidente'),
        const SizedBox(width: 10),
        _buildTarjetaTipo(TipoIncidente.problemaVial, Icons.warning_amber_rounded, 'Problema Vial'),
        const SizedBox(width: 10),
        _buildTarjetaTipo(TipoIncidente.inundacion, Icons.waves, 'Inundación'),
        const SizedBox(width: 10),
        _buildTarjetaTipo(TipoIncidente.otro, Icons.more_horiz, 'Otro'),
      ],
    );
  }

  /// Una tarjeta individual de tipo de incidente. Se usa Expanded en el Row
  /// para que las tres queden del mismo ancho sin importar el largo del texto.
  Widget _buildTarjetaTipo(TipoIncidente tipo, IconData icono, String etiqueta) {
    final bool seleccionado = _tipoSeleccionado == tipo;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tipoSeleccionado = tipo),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            // Fondo con un tinte del primario cuando está seleccionado, para
            // que "encienda" sin cambiar de color de golpe.
            color: seleccionado
                ? AppColors.primario.withValues(alpha: 0.10)
                : AppColors.superficie,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: seleccionado ? AppColors.primario : Colors.grey.shade300,
              width: seleccionado ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                size: 28,
                color: seleccionado ? AppColors.primario : AppColors.textoSecundario,
              ),
              const SizedBox(height: 8),
              Text(
                etiqueta,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                  color: seleccionado ? AppColors.primario : AppColors.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mapa para seleccionar/ajustar la ubicación (Tarea 3 - item 2).
  ///
  /// Va dentro de un recuadro con altura fija (no a pantalla completa) porque
  /// aquí es un paso más del formulario, no el foco de la pantalla. El usuario
  /// puede tocar cualquier punto o arrastrar el marcador para corregir el
  /// lugar exacto si el GPS no acertó.
  Widget _buildMapaSeleccion() {
    // Mientras se leen los argumentos, _ubicacionSeleccionada podría ser null
    // por un instante; mostramos un cargando para no romper el mapa.
    if (_ubicacionSeleccionada == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _ubicacionSeleccionada!,
            // zoom 14 = nivel "ciudad": se ve el barrio y sus alrededores,
            // no tan pegado como para tener que arrastrar mucho si el usuario
            // quiere moverse a otra zona. Igual puede acercarse con el pellizco
            // o con los botones de zoom para marcar el punto exacto.
            zoom: 14,
          ),
          onMapCreated: (controller) => _mapController = controller,
          // El mapa está dentro de una lista que scrollea. Sin esto, la lista
          // "gana" los gestos y el mapa no se podría mover ni hacer zoom.
          // Con EagerGestureRecognizer, el mapa reclama para sí todos los
          // gestos que ocurran sobre él (paneo, pellizco), y la página sigue
          // desplazándose con normalidad fuera del mapa.
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
          // Al tocar el mapa, movemos el marcador a ese punto.
          onTap: _moverMarcador,
          markers: {
            Marker(
              markerId: const MarkerId('ubicacion_reporte'),
              position: _ubicacionSeleccionada!,
              draggable: true, // también se puede arrastrar el pin
              onDragEnd: _moverMarcador,
            ),
          },
          // Bloqueamos rotar/inclinar igual que en el Home, para que el
          // usuario no pierda la orientación norte-arriba por accidente.
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          // Botones +/- de zoom visibles: dan una forma fácil de alejarse
          // para moverse a otra zona y luego acercarse a marcar el punto,
          // sin depender solo del gesto de pellizco.
          zoomControlsEnabled: true,
        ),
      ),
    );
  }

  /// Actualiza la ubicación seleccionada cuando el usuario toca el mapa o
  /// suelta el marcador arrastrado.
  void _moverMarcador(LatLng nuevaPosicion) {
    setState(() => _ubicacionSeleccionada = nuevaPosicion);
  }

  /// Sección de fotos (Tarea 3 - item 3): botón para agregar + tira horizontal
  /// con las miniaturas de las fotos ya elegidas, cada una con su "x" para
  /// quitarla.
  Widget _buildSeccionFotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _agregarFoto,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('Agregar foto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primario,
            side: const BorderSide(color: AppColors.primario),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        // Solo mostramos la tira de miniaturas si ya hay al menos una foto.
        if (_rutasFotos.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _rutasFotos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, indice) => _buildMiniaturaFoto(indice),
            ),
          ),
        ],
      ],
    );
  }

  /// Miniatura de una foto con su botón para quitarla. Se usa Stack para
  /// montar la "x" en la esquina superior derecha de la imagen.
  ///
  /// En web no existe el filesystem local: image_picker devuelve una URL
  /// tipo blob:, que se muestra con Image.network. En Android/iOS se usa
  /// Image.file con la ruta real del teléfono.
  Widget _buildMiniaturaFoto(int indice) {
    final ruta = _rutasFotos[indice];
    final Widget imagen = kIsWeb
        ? Image.network(ruta, width: 90, height: 90, fit: BoxFit.cover)
        : Image.file(File(ruta), width: 90, height: 90, fit: BoxFit.cover);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imagen,
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _quitarFoto(indice),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// Campo de descripción (Tarea 3 - item 4). Multilínea, porque el usuario
  /// puede querer explicar con detalle qué está pasando. Hereda el estilo de
  /// los inputs definido en app_theme.dart.
  Widget _buildCampoDescripcion() {
    return TextField(
      controller: _descripcionController,
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        hintText: 'Describe qué está pasando (ej. "Bache grande en el carril derecho").',
      ),
    );
  }

  /// Selector de urgencia. No estaba en la lista original de sub-items, pero
  /// el ReporteModel lo requiere, así que se incluye. Usa los mismos colores
  /// tipo semáforo del tema (verde/ámbar/rojo) para que el usuario reconozca
  /// el nivel sin leer.
  Widget _buildSelectorUrgencia() {
    return Row(
      children: [
        _buildChipUrgencia(NivelUrgencia.baja, 'Baja', AppColors.urgenciaBaja),
        const SizedBox(width: 10),
        _buildChipUrgencia(NivelUrgencia.media, 'Media', AppColors.urgenciaMedia),
        const SizedBox(width: 10),
        _buildChipUrgencia(NivelUrgencia.alta, 'Alta', AppColors.urgenciaAlta),
      ],
    );
  }

  /// Un chip de urgencia. Cuando está seleccionado se rellena con su color;
  /// cuando no, queda solo con el borde de ese color (más discreto).
  Widget _buildChipUrgencia(NivelUrgencia nivel, String etiqueta, Color color) {
    final bool seleccionado = _urgencia == nivel;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _urgencia = nivel),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seleccionado ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: seleccionado ? 0 : 1),
          ),
          child: Text(
            etiqueta,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: seleccionado ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  /// Botón principal de la pantalla: enviar el reporte. Ocupa todo el ancho
  /// para que sea la acción más clara y fácil de tocar. Se deshabilita
  /// mientras se está generando el ID del dispositivo y armando el reporte,
  /// para evitar que un doble tap cree el reporte dos veces.
  Widget _buildBotonEnviar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : _enviarReporte,
        icon: _enviando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(_enviando ? 'Enviando...' : 'Enviar Reporte'),
      ),
    );
  }
}

/// Comportamiento de scroll "firme" para esta pantalla.
///
/// Por defecto, Android aplica un efecto elástico de estiramiento cuando se
/// llega al borde de una lista (overscroll stretch). En una pantalla con un
/// mapa embebido eso se sentía raro y "deformaba" la vista al desplazarse.
/// Aquí quitamos ese indicador y usamos una física de tope firme, para que
/// el scroll se sienta estable y predecible.
class _ScrollFirme extends MaterialScrollBehavior {
  const _ScrollFirme();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Sin glow ni estiramiento: devolvemos el contenido tal cual.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Frena "en seco" en los bordes, sin rebote elástico.
    return const ClampingScrollPhysics();
  }
}