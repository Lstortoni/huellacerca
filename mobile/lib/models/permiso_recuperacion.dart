/// Autorización de un solo uso. Se mantiene sólo en memoria; no es una sesión.
class PermisoRecuperacion {
  const PermisoRecuperacion(this.token, this.expira);
  final String token;
  final DateTime expira;
  bool get vencido => !expira.isAfter(DateTime.now().toUtc());
}
