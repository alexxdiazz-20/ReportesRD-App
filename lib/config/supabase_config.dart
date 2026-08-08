/// Configuración de conexión a Supabase.
///
/// La URL y la anon key son públicas por diseño (viven dentro de la app).
/// La seguridad real está en las políticas RLS de la base de datos,
/// no en ocultar esta clave.
///
/// NOTA: se usa la anon key (JWT) y no la publishable key porque el
/// servicio de Storage exige un JWT válido y rechaza las claves
/// publishable (`Invalid Compact JWS`). La anon key funciona con REST,
/// Storage y URLs firmadas, todo bajo el rol anónimo sin login.
class SupabaseConfig {
  static const String url = 'https://upzbheqnmzmjhzvnkqrr.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVwemJoZXFubXptamh6dm5rcXJyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ1ODY2NDMsImV4cCI6MjEwMDE2MjY0M30.ZXWF83qlqS9J1teveZW8oFfJymTA_ECdIWI6Bbp99CU';

  static const String bucketFotos = 'reportes_fotos';
}