import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../services/contracts/push_service.dart';
import '../../services/contracts/mensajeria_push.dart';
import '../../services/implementations/push_service_api.dart';
import '../../services/implementations/mensajeria_push_firebase.dart';

import '../../services/contracts/auth_service.dart';
import '../../services/contracts/recuperacion_service.dart';
import '../../services/implementations/recuperacion_service_api.dart';
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
import '../../services/contracts/acciones_externas.dart';
import '../../services/contracts/notificacion_service.dart';
import '../../services/implementations/notificacion_service_api.dart';
import '../../services/contracts/selector_fotos.dart';
import '../../services/implementations/acciones_externas_plataforma.dart';
import '../../services/implementations/selector_fotos_galeria.dart';

final getIt = GetIt.instance;

/// Equivalente al registro de servicios de Program.cs.
/// Llamar una vez al arrancar. En pruebas, await getIt.reset() entre escenarios.
void configurarServicios({
  http.Client? httpClient,
  SessionStorage? sessionStorage,
  String baseUrl = ApiConfig.baseUrl,
  bool habilitarPush = false,
}) {
  getIt.registerLazySingleton<ApiClient>(
    () => HttpApiClient(baseUrl: baseUrl, client: httpClient),
    dispose: (api) => api.close(),
  );
  getIt.registerLazySingleton<SessionStorage>(
    () => sessionStorage ?? SecureSessionStorage(),
  );
  getIt.registerLazySingleton<RecuperacionService>(
    () => RecuperacionServiceApi(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceApi(
      getIt<ApiClient>(),
      getIt<SessionStorage>(),
      antesDeLogout: habilitarPush
          ? () => getIt<PushService>().desvincular()
          : null,
    ),
    dispose: (auth) => auth.dispose(),
  );
  getIt.registerLazySingleton<NotificacionService>(
    () => NotificacionServiceApi(getIt<AuthService>()),
    dispose: (notificaciones) => notificaciones.dispose(),
  );
  if (habilitarPush) {
    getIt.registerLazySingleton<MensajeriaPush>(() => MensajeriaPushFirebase());
    getIt.registerLazySingleton<PushService>(
      () => PushServiceApi(getIt<AuthService>(), getIt<MensajeriaPush>()),
      dispose: (push) => push.dispose(),
    );
  }
  getIt.registerLazySingleton<UbicacionService>(
    () => UbicacionServiceApi(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<PublicacionService>(
    () => PublicacionServiceApi(
      getIt<ApiClient>(),
      getIt<AuthService>(),
      getIt<SelectorFotos>(),
      getIt<AccionesExternas>(),
    ),
  );
  getIt.registerLazySingleton<SelectorFotos>(() => SelectorFotosGaleria());
  getIt.registerLazySingleton<AccionesExternas>(
    () => AccionesExternasPlataforma(),
  );
  getIt.registerLazySingleton<RecomendacionService>(
    () => RecomendacionServiceApi(
      getIt<ApiClient>(),
      getIt<AuthService>(),
      getIt<AccionesExternas>(),
    ),
  );
}
