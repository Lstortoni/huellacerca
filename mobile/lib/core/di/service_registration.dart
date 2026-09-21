import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../services/contracts/auth_service.dart';
import '../../services/contracts/ubicacion_service.dart';
import '../../services/contracts/publicacion_service.dart';
import '../../services/contracts/recomendacion_service.dart';
import '../../services/implementations/publicacion_service_api.dart';
import '../../services/implementations/recomendacion_service_api.dart';
import '../../services/implementations/auth_service_api.dart';
import '../../services/implementations/ubicacion_service_api.dart';
import '../config/api_config.dart';
import '../network/api_client.dart';
import '../network/http_api_client.dart';
import '../storage/session_storage.dart';
import '../storage/secure_session_storage.dart';
import '../../services/contracts/selector_fotos.dart';
import '../../services/implementations/selector_fotos_galeria.dart';

final getIt = GetIt.instance;

/// Equivalente al registro de servicios de Program.cs.
/// Llamar una vez al arrancar. En pruebas, await getIt.reset() entre escenarios.
void configurarServicios({
  http.Client? httpClient,
  SessionStorage? sessionStorage,
  String baseUrl = ApiConfig.baseUrl,
}) {
  getIt.registerLazySingleton<ApiClient>(
    () => HttpApiClient(baseUrl: baseUrl, client: httpClient),
    dispose: (api) => api.close(),
  );
  getIt.registerLazySingleton<SessionStorage>(
    () => sessionStorage ?? SecureSessionStorage(),
  );
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceApi(getIt<ApiClient>(), getIt<SessionStorage>()),
    dispose: (auth) => auth.dispose(),
  );
  getIt.registerLazySingleton<UbicacionService>(
    () => UbicacionServiceApi(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PublicacionService>(
    () => PublicacionServiceApi(
      getIt<ApiClient>(),
      getIt<AuthService>(),
      getIt<SelectorFotos>(),
    ),
  );
  getIt.registerLazySingleton<SelectorFotos>(() => SelectorFotosGaleria());
  getIt.registerLazySingleton<RecomendacionService>(
    () => RecomendacionServiceApi(getIt<ApiClient>(), getIt<AuthService>()),
  );
}
