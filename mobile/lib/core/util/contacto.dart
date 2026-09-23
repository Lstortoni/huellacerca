// Utilidades para contactar a partir de un texto libre de contacto.

final _posibleTelefono = RegExp(r'\+?\d[\d\s\-.()]{6,}\d');

/// Primer teléfono (8 a 15 dígitos) dentro de [texto], o null si no hay.
/// Conserva el "+" inicial si la persona lo escribió.
String? telefonoEn(String texto) {
  for (final m in _posibleTelefono.allMatches(texto)) {
    final digitos = m.group(0)!.replaceAll(RegExp(r'\D'), '');
    if (digitos.length >= 8 && digitos.length <= 15) {
      return m.group(0)!.startsWith('+') ? '+$digitos' : digitos;
    }
  }
  return null;
}

/// Número para wa.me en formato internacional de celular argentino (549…).
/// Acepta números con +54/54, con 0 inicial o con el 15 local
/// (por ejemplo 221 15 555-0000). Otros formatos se envían tal cual.
String numeroWhatsApp(String telefono) {
  var d = telefono.replaceAll(RegExp(r'\D'), '');
  if (telefono.trim().startsWith('+') || d.startsWith('54')) return d;
  if (d.startsWith('0')) d = d.substring(1);
  // Código de área (2 a 4 dígitos) + 15 + número: 12 dígitos en total.
  if (d.length == 12) {
    for (final area in [2, 3, 4]) {
      if (d.substring(area, area + 2) == '15') {
        d = d.substring(0, area) + d.substring(area + 2);
        break;
      }
    }
  }
  return d.length == 10 ? '549$d' : d;
}

Uri uriLlamada(String telefono) => Uri(scheme: 'tel', path: telefono);

Uri uriWhatsApp(String telefono, String mensaje) =>
    Uri.https('wa.me', '/${numeroWhatsApp(telefono)}', {'text': mensaje});
