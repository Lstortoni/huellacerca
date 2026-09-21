import '../../models/foto_seleccionada.dart';

abstract class SelectorFotos {
  Future<FotoSeleccionada?> elegir();
  Future<FotoSeleccionada?> recuperar();
}
