class AvisoPush {
  const AvisoPush({required this.notificacionId, required this.mascoteroId});
  final String notificacionId;
  final String mascoteroId;

  static AvisoPush? desdeDatos(Map<String, dynamic> data) {
    final id = data['notificacionId'];
    final autor = data['mascoteroId'];
    final guid = RegExp(
      r'^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$',
    );
    if (data['tipo'] != 'coincidencia' ||
        id is! String ||
        autor is! String ||
        !guid.hasMatch(id) ||
        !guid.hasMatch(autor)) {
      return null;
    }
    return AvisoPush(notificacionId: id, mascoteroId: autor);
  }
}
