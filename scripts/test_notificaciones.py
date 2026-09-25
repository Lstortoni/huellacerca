"""Prueba HTTP de notificaciones. Resuelve únicamente sus avisos al terminar."""
import datetime as dt
import json
import os
import time
import urllib.request
import urllib.error
import uuid

BASE = os.environ.get('API_BASE_URL', 'http://localhost:5080')
tag = 'hc-notif-' + uuid.uuid4().hex[:12]

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
    assert code == status, (path, code, data[:300])
    return json.loads(data) if data else None

province = call('GET', '/api/provincias')[0]['id']
localities = call('GET', '/api/localidades?provinciaId=' + province)['items']
locality = next(x['id'] for x in reversed(localities)
    if call('GET', '/api/publicaciones?localidadId=' + x['id'])['total'] == 0)
sessions, created = [], []
try:
    for name in ['A', 'B', 'C']:
        sessions.append(call('POST', '/api/auth/register', dict(nombre='Prueba'+name, apellido='Notificaciones',
            email=tag+name+'@example.invalid', password='Prueba.Local-2026!', passwordConfirm='Prueba.Local-2026!',
            localidadId=locality), status=201))
    a, b, c = [s['accessToken'] for s in sessions]
    def create(token, tipo):
        result = call('POST', '/api/publicaciones', dict(tipoPublicacion=tipo, tipoMascota=1,
            descripcion=tag, zona=tag, informacionContacto='Prueba', localidadId=locality, tamano=1,
            fechaSuceso=(dt.datetime.now(dt.timezone.utc).date()-dt.timedelta(days=1)).isoformat() if tipo <= 2 else None),
            token, 201)
        created.append((result['id'], token))
        return result['id']
    perdida, encontrada = create(a, 1), create(b, 2)
    adopcion, busca = create(a, 3), create(b, 4)
    # Mismo dueño: este hallazgo no debe notificar a C por su propio extravío.
    propia1, propia2 = create(c, 1), create(c, 2)
    deadline = time.monotonic() + 45
    while True:
        page = call('GET', '/api/notificaciones?tamanoPagina=50', token=a)
        pairs = {(n['publicacionId'], n['publicacionCoincidenteId']) for n in page['items']}
        if (perdida, encontrada) in pairs and (adopcion, busca) in pairs:
            break
        assert time.monotonic() < deadline, 'No se procesaron las notificaciones'
        time.sleep(1)
    for token, own, other in [(a, perdida, encontrada), (b, encontrada, perdida), (a, adopcion, busca), (b, busca, adopcion)]:
        items = call('GET', '/api/notificaciones?tamanoPagina=50', token=token)['items']
        assert len([n for n in items if n['publicacionId'] == own and n['publicacionCoincidenteId'] == other]) == 1
    items_c = call('GET', '/api/notificaciones?tamanoPagina=50', token=c)['items']
    assert not any(n['publicacionId'] == propia1 and n['publicacionCoincidenteId'] == propia2 for n in items_c)
    n = next(x for x in page['items'] if x['publicacionId'] == perdida and x['publicacionCoincidenteId'] == encontrada)
    # Resumen de ambos avisos para mostrar la notificación sin pedir cada detalle.
    assert n['publicacion']['id'] == perdida and n['publicacion']['tipoPublicacion'] == 1
    assert n['coincidente']['id'] == encontrada and n['coincidente']['tipoPublicacion'] == 2
    assert n['coincidente']['estado'] == 1 and n['coincidente']['fotoUrl'] is None
    assert n['coincidente']['localidad'] and n['coincidente']['tipoMascota'] == 1
    call('GET', '/api/notificaciones', status=401)
    call('GET', '/api/notificaciones/no-leidas/cantidad', status=401)
    call('PATCH', '/api/notificaciones/'+n['id']+'/leer', status=401)
    call('PATCH', '/api/notificaciones/leer-todas', status=401)
    call('PATCH', '/api/notificaciones/'+n['id']+'/leer', token=b, status=404)
    call('GET', '/api/notificaciones?pagina=0', token=a, status=400)
    call('GET', '/api/notificaciones?tamanoPagina=51', token=a, status=400)
    call('PATCH', '/api/notificaciones/'+n['id']+'/leer', token=a, status=204)
    call('PATCH', '/api/notificaciones/'+n['id']+'/leer', token=a, status=204)
    unread = call('GET', '/api/notificaciones?soloNoLeidas=true', token=a)
    assert n['id'] not in [x['id'] for x in unread['items']]
    call('PATCH', '/api/notificaciones/leer-todas', token=a, status=204)
    assert call('GET', '/api/notificaciones/no-leidas/cantidad', token=a)['cantidad'] == 0
    assert call('GET', '/api/notificaciones/no-leidas/cantidad', token=b)['cantidad'] > 0
    for _ in range(2):
        call('GET', '/api/publicaciones/'+perdida+'/coincidencias', token=a)
    again = call('GET', '/api/notificaciones?tamanoPagina=50', token=a)
    assert len({x['id'] for x in again['items']}) == len(again['items'])
    print('OK HTTP: generación automática, ambos autores, cuatro tipos, propias excluidas, resumen de avisos, JWT, aislamiento, paginación y lecturas.')
finally:
    for id, token in created:
        call('PATCH', '/api/publicaciones/'+id+'/resolver', token=token)
    for session in sessions:
        call('POST', '/api/auth/logout', {'refreshToken': session['refreshToken']}, status=204)
