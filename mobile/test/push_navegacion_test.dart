import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huella_cerca/app.dart';
import 'package:huella_cerca/core/di/service_registration.dart';
import 'package:huella_cerca/models/auth_dto.dart';
import 'package:huella_cerca/models/aviso_push.dart';
import 'package:huella_cerca/pages/login_page.dart';
import 'package:huella_cerca/pages/publicacion_detalle_page.dart';
import 'package:huella_cerca/services/contracts/auth_service.dart';
import 'package:huella_cerca/services/contracts/publicacion_service.dart';
import 'package:huella_cerca/services/contracts/push_service.dart';

import 'support/service_mocks.dart';
import 'support/comunidad_mocks.dart';

class AuthDestino extends AuthServiceMock {
  final consultas = <String>[];
  final leidas = <String>[];
  @override
  Future<Object?> getProtegido(String path) async {
    consultas.add(path);
    return {'publicacionId': 'publicacion-1'};
  }

  @override
  Future<Object?> patchProtegido(String path) async {
    leidas.add(path);
    return null;
  }
}

class PushMock implements PushService {
  final mensajes = StreamController<AvisoPush>.broadcast();
  final toques = StreamController<AvisoPush>.broadcast();
  AvisoPush? inicial;
  @override
  Stream<AvisoPush> get recibidos => mensajes.stream;
  @override
  Stream<AvisoPush> get abiertos => toques.stream;
  @override
  Future<void> iniciar() async {
    if (inicial != null) toques.add(inicial!);
  }

  @override
  Future<void> sincronizar() async {}
  @override
  Future<void> desvincular() async {}
  @override
  void dispose() {
    unawaited(mensajes.close());
    unawaited(toques.close());
  }
}

void main() {
  late AuthDestino auth;
  late PushMock push;
  const aviso = AvisoPush(
    notificacionId: 'notificacion-1',
    mascoteroId: 'mascotero-1',
  );
  setUp(() {
    auth = AuthDestino();
    push = PushMock();
    getIt.registerSingleton<AuthService>(auth);
    getIt.registerSingleton<PushService>(push);
    getIt.registerSingleton<PublicacionService>(PublicacionServiceMock());
  });
  tearDown(() async {
    push.dispose();
    auth.dispose();
    await getIt.reset();
  });

  testWidgets('tap verifica destino, marca leída y abre el detalle', (
    tester,
  ) async {
    await auth.login(const LoginRequest('test@example.com', 'password'));
    await tester.pumpWidget(const HuellaCercaApp());
    push.toques.add(aviso);
    await tester.pumpAndSettle();
    expect(auth.consultas, ['api/notificaciones/notificacion-1/destino']);
    expect(auth.leidas, ['api/notificaciones/notificacion-1/leer']);
    expect(find.byType(PublicacionDetallePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('apertura en frío espera login y continúa al detalle', (
    tester,
  ) async {
    push.inicial = aviso;
    await tester.pumpWidget(const HuellaCercaApp());
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(auth.consultas, isEmpty);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'test@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password');
    // Usar el formulario real comprueba también el popUntil después de login.
    await tester.tap(find.widgetWithText(FilledButton, 'Ingresar'));
    await tester.pumpAndSettle();
    expect(find.byType(PublicacionDetallePage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mensaje en primer plano ofrece Ver; otra cuenta no abre datos', (
    tester,
  ) async {
    await auth.login(const LoginRequest('test@example.com', 'password'));
    await tester.pumpWidget(const HuellaCercaApp());
    push.mensajes.add(aviso);
    await tester.pumpAndSettle();
    expect(find.text('Ver'), findsOneWidget);
    push.toques.add(
      const AvisoPush(notificacionId: 'ajena', mascoteroId: 'otro'),
    );
    await tester.pumpAndSettle();
    expect(auth.consultas, isEmpty);
    expect(find.byType(PublicacionDetallePage), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
