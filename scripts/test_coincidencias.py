"""Verifica candidatos por HTTP. Solo resuelve los avisos creados por esta prueba."""
import datetime as dt
import json
import os
import urllib.request
import urllib.error
import uuid

BASE = os.environ.get('API_BASE_URL', 'http://localhost:5080')
tag = 'hc-match-test-' + uuid.uuid4().hex[:10]

def call(method, path, body=None, token=None, status=200):
    headers = {'Content-Type': 'application/json'}
    if token:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(BASE + path, method=method, headers=headers,
        data=None if body is None else json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            code, data = r.status, r.read()
    except urllib.error.HTTPError as e:
        code, data = e.code, e.read()
    assert code == status, (path, code, data[:500])
    return json.loads(data) if data else None

province = call('GET', '/api/provincias')[0]['id']
localities = call('GET', '/api/localidades?provinciaId=' + province)['items']
session = call('POST', '/api/auth/register', dict(nombre='Prueba', apellido='Coincidencias',
    email=tag+'@example.invalid', password='Prueba.Local-2026!', passwordConfirm='Prueba.Local-2026!',
    localidadId=localities[0]['id']), status=201)
token = session['accessToken']
created = []
today = dt.datetime.now(dt.timezone.utc).date() - dt.timedelta(days=1)
def create(**extra):
    body = dict(tipoPublicacion=1, tipoMascota=1, descripcion=tag, zona=tag,
        fechaSuceso=(today-dt.timedelta(days=40)).isoformat(), localidadId=localities[0]['id'],
        informacionContacto='Contacto de prueba', tamano=1, colorPredominante=3)
    p = call('POST', '/api/publicaciones', {**body, **extra}, token, 201)
    created.append(p['id'])
    return p['id']
def matches(id, query=''):
    return call('GET', '/api/publicaciones/'+id+'/coincidencias'+query, token=token)

try:
    origin = create()
    both = create(tipoPublicacion=2)
    one = create(tipoPublicacion=2, tamano=2)
    neither = create(tipoPublicacion=2, tamano=2, colorPredominante=1)
    unknown = create(tipoPublicacion=2, tamano=None, colorPredominante=None)
    wrong_species = create(tipoPublicacion=2, tipoMascota=2)
    wrong_date = create(tipoPublicacion=2, fechaSuceso=today.isoformat())
    wrong_place = create(tipoPublicacion=2, localidadId=localities[1]['id'])
    data = matches(origin, '?tamanoPagina=20')
    ids = [x['publicacion']['id'] for x in data['items']]
    assert both in ids and one in ids and ids.index(both) < ids.index(one), data
    assert all(x not in ids for x in [origin, neither, unknown, wrong_species, wrong_date, wrong_place])
    assert len(next(x for x in data['items'] if x['publicacion']['id'] == one)['coincideEn']) == 1
    assert origin in [x['publicacion']['id'] for x in matches(both)['items']]
    a = matches(origin, '?tamanoPagina=1&pagina=1')
    b = matches(origin, '?tamanoPagina=1&pagina=2')
    assert a['total'] == b['total'] and a['items'][0] != b['items'][0]
    call('GET', '/api/publicaciones/'+origin+'/coincidencias', status=401)
    call('GET', '/api/publicaciones/'+origin+'/coincidencias?pagina=0', token=token, status=400)
    call('PATCH', '/api/publicaciones/'+both+'/resolver', token=token)
    assert both not in [x['publicacion']['id'] for x in matches(origin)['items']]
    call('PATCH', '/api/publicaciones/'+origin+'/resolver', token=token)
    assert matches(origin)['total'] == 0
    # Adopción tiene FechaSuceso null: debe cruzar ambos sentidos sin filtrar fechas.
    wanted = create(tipoPublicacion=4, raza=2, colorPredominante=1)
    offered = create(tipoPublicacion=3, raza=2, colorPredominante=1)
    partial = create(tipoPublicacion=3, raza=1, tamano=2, colorPredominante=1)
    unrelated = create(tipoPublicacion=3, raza=1, tamano=2, colorPredominante=3)
    other_species = create(tipoPublicacion=3, tipoMascota=2, raza=2, colorPredominante=1)
    other_place = create(tipoPublicacion=3, localidadId=localities[1]['id'], raza=2, colorPredominante=1)
    data = matches(wanted, '?tamanoPagina=20')
    ids = [x['publicacion']['id'] for x in data['items']]
    assert offered in ids and partial in ids and ids.index(offered) < ids.index(partial)
    assert all(x['publicacion']['tipoPublicacion'] == 3 for x in data['items'])
    assert all(x not in ids for x in [unrelated, other_species, other_place, one])
    inverse = matches(offered, '?tamanoPagina=20')
    assert wanted in [x['publicacion']['id'] for x in inverse['items']]
    assert all(x['publicacion']['tipoPublicacion'] == 4 for x in inverse['items'])
    call('PATCH', '/api/publicaciones/'+offered+'/resolver', token=token)
    assert offered not in [x['publicacion']['id'] for x in matches(wanted, '?tamanoPagina=20')['items']]
    call('PATCH', '/api/publicaciones/'+wanted+'/resolver', token=token)
    assert matches(wanted)['total'] == 0
    print('OK: adopción en ambos sentidos, sin fecha de suceso, coincidencia parcial y separación de extraviadas/encontradas.')
    print('OK: coincidencia parcial, orden, especie, localidad, fechas, nulos, inversa, paginación y resolución.')
finally:
    for id in created:
        call('PATCH', '/api/publicaciones/'+id+'/resolver', token=token)
    call('POST', '/api/auth/logout', {'refreshToken': session['refreshToken']}, status=204)
