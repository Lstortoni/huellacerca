"""Prueba HTTP de edición. Solo modifica/resuelve sus propios avisos de prueba."""
import datetime as dt
import json
import os
import time
import urllib.request
import urllib.error
import uuid

BASE = os.environ.get('API_BASE_URL', 'http://localhost:5080')
tag = 'hc-edit-' + uuid.uuid4().hex[:12]
def call(method, path, body=None, token=None, status=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    request = urllib.request.Request(BASE + path, method=method, headers=headers,
        data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            code, data = response.status, response.read()
    except urllib.error.HTTPError as error:
        code, data = error.code, error.read()
    assert code == status, (path, code, data[:350])
    return json.loads(data) if data else None

fields = ['version', 'tipoMascota', 'tamano', 'raza', 'pelaje', 'colorPredominante', 'colorOjos',
    'nombreMascota', 'descripcion', 'fechaSuceso', 'localidadId', 'zona', 'informacionContacto']
def edit_body(p):
    return {key: p[key] for key in fields}

province = call('GET', '/api/provincias')[0]['id']
locations = call('GET', '/api/localidades?provinciaId=' + province)['items']
locality = next(x['id'] for x in reversed(locations)
    if call('GET', '/api/publicaciones?localidadId=' + x['id'])['total'] == 0)
other_location = next(x for x in locations if x['id'] != locality)
sessions, created = [], []
try:
    for name in ['A', 'B']:
        sessions.append(call('POST', '/api/auth/register', dict(nombre='Prueba'+name, apellido='Edicion',
            email=tag+name+'@example.invalid', password='Prueba.Local-2026!', passwordConfirm='Prueba.Local-2026!',
            localidadId=locality), status=201))
    a, b = [s['accessToken'] for s in sessions]
    def create(token, tipo=1, **extra):
        p = call('POST', '/api/publicaciones', dict(tipoPublicacion=tipo, tipoMascota=1,
            descripcion=tag, zona=tag, informacionContacto='Prueba', localidadId=locality,
            fechaSuceso=(dt.datetime.now(dt.timezone.utc).date()-dt.timedelta(days=1)).isoformat() if tipo <= 2 else None,
            **extra), token, 201)
        created.append((p['id'], token))
        return p
    p = create(a, colorPredominante=1)
    candidate = create(b, tipo=2, colorPredominante=2)
    path = '/api/publicaciones/' + p['id']
    body = edit_body(p)
    call('PUT', path, body, status=401)
    call('PUT', path, body, b, 403)
    call('PUT', '/api/publicaciones/'+str(uuid.uuid4()), body, a, 404)
    for bad in [dict(tipoPublicacion=2), dict(estado=2), dict(mascoteroId=str(uuid.uuid4())),
                dict(version=None), dict(descripcion='corta'), dict(informacionContacto=' '),
                dict(tipoMascota=3, raza=1), dict(localidadId=str(uuid.uuid4())),
                dict(fechaSuceso='2099-01-01'), dict(zona=''), dict(tamano=99)]:
        call('PUT', path, {**body, **bad}, a, 400)
    p2 = call('PUT', path, {**body, 'descripcion': 'Descripción corregida de prueba',
        'informacionContacto': 'Contacto nuevo', 'localidadId': other_location['id']}, a)
    # PostgreSQL conserva microsegundos; la respuesta inicial de .NET puede tener un decimal extra.
    assert dt.datetime.fromisoformat(p2['fechaCreacion']) == dt.datetime.fromisoformat(p['fechaCreacion']) and p2['id'] == p['id']
    assert p2['version'] != p['version'] and p2['fechaActualizacion'] is not None
    assert p2['localidad'] == other_location['nombre'] and p2['foto'] == p['foto']
    call('PUT', path, body, a, 409)
    p3 = call('PUT', path, {**edit_body(p2), 'localidadId': locality, 'colorPredominante': 2}, a)
    deadline = time.monotonic() + 45
    while True:
        notices = call('GET', '/api/notificaciones?tamanoPagina=50', token=a)['items']
        if any(n['publicacionId'] == p['id'] and n['publicacionCoincidenteId'] == candidate['id'] for n in notices):
            break
        assert time.monotonic() < deadline, 'La edición no notificó la nueva coincidencia'
        time.sleep(1)
    # Cambiar a otro tipo de mascota limpiando atributos no admitidos.
    p4 = call('PUT', path, {**edit_body(p3), 'tipoMascota': 3, 'raza': None, 'pelaje': None, 'colorOjos': None}, a)
    assert p4['tipoMascota'] == 3 and p4['raza'] is None
    resolved = call('PATCH', path+'/resolver', token=a)
    call('PUT', path, edit_body(p4), a, 409)
    result = call('PUT', path, {**edit_body(resolved), 'informacionContacto': 'Contacto resuelta'}, a)
    assert result['estado'] == 2
    call('PATCH', path+'/reabrir', status=401)
    call('PATCH', path+'/reabrir', token=b, status=403)
    call('PATCH', '/api/publicaciones/'+str(uuid.uuid4())+'/reabrir', token=a, status=404)
    # Vuelve a perro mientras está resuelta: reabrir debe generar las nuevas notificaciones.
    result = call('PUT', path, {**edit_body(result), 'tipoMascota': 1}, a)
    new_candidate = create(b, tipo=2, colorPredominante=2)
    reopened = call('PATCH', path+'/reabrir', token=a)
    assert reopened['estado'] == 1 and reopened['version'] != result['version']
    for key in ['id', 'mascoteroId', 'tipoPublicacion', 'foto', 'fechaCreacion', 'fechaSuceso', 'descripcion']:
        assert reopened[key] == result[key], key
    repeated = call('PATCH', path+'/reabrir', token=a)
    assert repeated['version'] == reopened['version'] and repeated['fechaActualizacion'] == reopened['fechaActualizacion']
    call('PUT', path, edit_body(result), a, 409)
    deadline = time.monotonic() + 45
    while True:
        notices = call('GET', '/api/notificaciones?tamanoPagina=50', token=a)['items']
        own = [n for n in notices if n['publicacionId'] == p['id']]
        if any(n['publicacionCoincidenteId'] == new_candidate['id'] for n in own):
            break
        assert time.monotonic() < deadline, 'Reabrir no notificó la nueva coincidencia'
        time.sleep(1)
    assert len([n for n in own if n['publicacionCoincidenteId'] == candidate['id']]) == 1
    assert any(x['id'] == p['id'] for x in call('GET', '/api/publicaciones?estado=1&localidadId='+locality)['items'])
    for tipo in [3, 4]:
        ad = create(a, tipo=tipo)
        result = call('PUT', '/api/publicaciones/'+ad['id'], {**edit_body(ad),
            'nombreMascota': 'Prueba', 'fechaSuceso': None, 'zona': '' if tipo == 4 else tag}, a)
        assert result['tipoPublicacion'] == tipo and result['fechaSuceso'] is None
        if tipo == 4:
            assert result['nombreMascota'] is None
        ad_path = '/api/publicaciones/'+ad['id']
        call('PATCH', ad_path+'/resolver', token=a)
        assert call('PATCH', ad_path+'/reabrir', token=a)['estado'] == 1
    candidate_path = '/api/publicaciones/'+candidate['id']
    call('PATCH', candidate_path+'/resolver', token=b)
    assert call('PATCH', candidate_path+'/reabrir', token=b)['estado'] == 1
    print('OK: reapertura de los cuatro tipos, permisos, idempotencia, versiones y notificaciones sin duplicados.')
    print('OK: edición HTTP, autor/JWT, validaciones, tipo fijo, localidad actualizada, versiones, resuelta y nuevas notificaciones.')
finally:
    for id, token in created:
        call('PATCH', '/api/publicaciones/'+id+'/resolver', token=token)
    for session in sessions:
        call('POST', '/api/auth/logout', {'refreshToken': session['refreshToken']}, status=204)
