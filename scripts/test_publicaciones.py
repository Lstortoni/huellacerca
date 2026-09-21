"""Pruebas HTTP de desarrollo. Deja dos cuentas y avisos resueltos hc-pets-test-*.

No borra datos existentes. Ejecutar con el servicio huellacerca_tests de Compose.
"""
import datetime
import json
import os
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = os.environ.get("API_BASE_URL", "http://huellacerca_api:8080")
TAG = "hc-pets-test-" + uuid.uuid4().hex[:12]


def call(method, path, body=None, token=None, expected=200):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(BASE + path, method=method, headers=headers,
        data=json.dumps(body).encode() if body is not None else None)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            status, data = response.status, response.read()
            location = response.headers.get("Location")
    except urllib.error.HTTPError as error:
        status, data, location = error.code, error.read(), None
    assert status == expected, (method, path, expected, status, data[:300] if status >= 400 else "")
    result = json.loads(data) if data else None
    if status == 201 and path == "/api/publicaciones":
        assert location.endswith("/api/publicaciones/" + result["id"])
    return result


def search(**filters):
    return call("GET", "/api/publicaciones?" + urllib.parse.urlencode({"zona": TAG, **filters}))


provinces = call("GET", "/api/provincias")
province = provinces[0]["id"]
locality = call("GET", "/api/localidades?provinciaId=" + province)["items"][0]["id"]
sessions = []
for suffix in ("a", "b"):
    sessions.append(call("POST", "/api/auth/register", dict(nombre="Prueba", apellido="Publicaciones",
        email=f"{TAG}-{suffix}@example.invalid", password="Prueba.Local-2026!",
        passwordConfirm="Prueba.Local-2026!", localidadId=locality), expected=201))
a, b = sessions
token = a["accessToken"]
today = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-3))).date()
request = dict(tipoPublicacion=1, tipoMascota=1, nombreMascota=None,
    descripcion="Perro marrón con collar azul, visto junto a la plaza.", fechaSuceso=today.isoformat(),
    localidadId=locality, zona=TAG + " Plaza", informacionContacto="Contacto de prueba")
fields = dict(tamano=2, raza=2, pelaje=1, colorPredominante=3, colorOjos=1)
for pet in (1, 2):
    options = call("GET", f"/api/publicaciones/caracteristicas?tipoMascota={pet}")
    assert {x["campo"] for x in options} == set(fields)
    assert all(fields[x["campo"]] in [o["id"] for o in x["opciones"]] for x in options)
assert {x["campo"] for x in call("GET", "/api/publicaciones/caracteristicas?tipoMascota=3")} == {"tamano", "colorPredominante"}
for invalid in (0, 4, -1):
    call("GET", f"/api/publicaciones/caracteristicas?tipoMascota={invalid}", expected=400)
for field, maximum in dict(tamano=3, raza=2, pelaje=3, colorPredominante=7, colorOjos=3).items():
    for invalid in (0, -1, maximum + 1, "invalido"):
        call("POST", "/api/publicaciones", {**request, field: invalid}, token, 400)
for field in ("raza", "pelaje", "colorOjos"):
    call("POST", "/api/publicaciones", {**request, "tipoMascota": 3, field: 1}, token, 400)
call("POST", "/api/publicaciones", request, expected=401)
for bad in (
    {"tipoPublicacion": 0}, {"tipoPublicacion": 5}, {"tipoMascota": 4},
    {"fechaSuceso": "0001-01-01"}, {"fechaSuceso": (today + datetime.timedelta(days=1)).isoformat()},
    {"localidadId": str(uuid.uuid4())}, {"descripcion": " " * 15}, {"descripcion": "corta"},
    {"descripcion": "x" * 3001}, {"zona": " "}, {"informacionContacto": ""}, {"nombreMascota": "x" * 101},
):
    call("POST", "/api/publicaciones", {**request, **bad}, token, 400)
missing_date = {k: v for k, v in request.items() if k != "fechaSuceso"}
call("POST", "/api/publicaciones", missing_date, token, 400)

# Los campos de autor/estado adicionales no permiten suplantar al autor ni crear resuelta.
first = call("POST", "/api/publicaciones", {**request, "mascoteroId": b["usuario"]["mascotero"]["id"], "estado": 2}, token, 201)
assert first["mascoteroId"] == a["usuario"]["mascotero"]["id"]
assert first["estado"] == 1 and first["foto"] is None and first["nombreMascota"] is None
assert first["provinciaId"] == province and first["localidadId"] == locality
assert first["fechaSuceso"] == today.isoformat()
assert all(first[field] is None for field in fields)
second = call("POST", "/api/publicaciones", {**request, **fields, "tipoPublicacion": 2, "tipoMascota": 2,
    "nombreMascota": "  Michi  ", "fechaSuceso": (today - datetime.timedelta(days=1)).isoformat()}, token, 201)
assert second["nombreMascota"] == "Michi"
assert all(second[field] == value for field, value in fields.items())
saved = call("GET", "/api/publicaciones/" + second["id"])
assert all(saved[field] == value for field, value in fields.items())
listed = search(tipoPublicacion=2)["items"][0]
assert all(listed[field] == value for field, value in fields.items())
for field, value in fields.items():
    result = search(**{field: value})
    assert result['total'] == 1 and result['items'][0]['id'] == second['id']
    assert search(**{field: 1 if value != 1 else 2})['total'] == 0
    call('GET', '/api/publicaciones?' + urllib.parse.urlencode({field: 0}), expected=400)
    call('GET', '/api/publicaciones?' + urllib.parse.urlencode({field: 99}), expected=400)
assert search(**fields)['total'] == 1
assert search(**{**fields, 'tamano': 1})['total'] == 0
assert search(**fields, tipoMascota=1)['total'] == 0
assert search(**fields, tipoMascota=2, localidadId=locality)['total'] == 1
assert search(**fields, tamanoPagina=1, pagina=2)['items'] == []
call('GET', '/api/publicaciones?tipoMascota=3&raza=1', expected=400)
detail = call("GET", "/api/publicaciones/" + first["id"])
# PostgreSQL conserva microsegundos; .NET puede serializar una fracción adicional al crear.
assert {k: v for k, v in detail.items() if k != "fechaCreacion"} == {
    k: v for k, v in first.items() if k != "fechaCreacion"}
assert search()["total"] == 2
for filters in ({"tipoPublicacion": 1}, {"tipoMascota": 2}, {"fechaDesde": today.isoformat()},
                {"fechaHasta": (today - datetime.timedelta(days=1)).isoformat()}):
    assert search(**filters)["total"] == 1
assert search(provinciaId=province, localidadId=locality, estado=1,
              mascoteroId=a["usuario"]["mascotero"]["id"])["total"] == 2
for filters in ({"provinciaId": str(uuid.uuid4())}, {"localidadId": str(uuid.uuid4())},
                {"mascoteroId": b["usuario"]["mascotero"]["id"]}, {"estado": 2}, {"zona": TAG + " ausente"}):
    assert search(**filters)["total"] == 0
page1, page2 = search(tamanoPagina=1), search(tamanoPagina=1, pagina=2)
assert page1["total"] == 2 and len(page1["items"]) == 1
assert page1["items"][0]["id"] != page2["items"][0]["id"]
for query in ("pagina=0", "tamanoPagina=101", "estado=3", "tipoPublicacion=8", "tipoMascota=0",
              "fechaDesde=2026-02-02&fechaHasta=2026-01-01", "fechaDesde=invalida"):
    call("GET", "/api/publicaciones?" + query, expected=400)
missing = "/api/publicaciones/" + str(uuid.uuid4())
call("GET", missing, expected=404)
call("PATCH", missing + "/resolver", token=token, expected=404)
for item in (first, second):
    path = "/api/publicaciones/" + item["id"] + "/resolver"
    call("PATCH", path, expected=401)
    call("PATCH", path, token=b["accessToken"], expected=403)
    assert call("GET", "/api/publicaciones/" + item["id"])["estado"] == 1
    assert call("PATCH", path, token=token)["estado"] == 2
    assert call("PATCH", path, token=token)["estado"] == 2
    call("PATCH", path, token=b["accessToken"], expected=403)
assert search(estado=1)["total"] == 0 and search(estado=2)["total"] == 2
adoption = call("POST", "/api/publicaciones", {**request, "tipoPublicacion": 3}, token, 201)
assert adoption["tipoPublicacion"] == 3 and adoption["foto"] is None
assert call("GET", "/api/publicaciones/" + adoption["id"])["tipoPublicacion"] == 3
assert search(tipoPublicacion=3)["items"][0]["id"] == adoption["id"]
call("PATCH", "/api/publicaciones/" + adoption["id"] + "/resolver", token=b["accessToken"], expected=403)
assert call("PATCH", "/api/publicaciones/" + adoption["id"] + "/resolver", token=token)["estado"] == 2
assert adoption["fechaSuceso"] is None
wanted_request = {k: v for k, v in request.items() if k not in ("fechaSuceso", "nombreMascota", "zona")}
wanted_request["tipoPublicacion"] = 4
call("POST", "/api/publicaciones", wanted_request, expected=401)
call("POST", "/api/publicaciones", {**wanted_request, "informacionContacto": " "}, token, 400)
wanted = call("POST", "/api/publicaciones", wanted_request, token, 201)
assert wanted["fechaSuceso"] is None and wanted["nombreMascota"] is None and wanted["zona"] == ""
assert wanted["foto"] is None and wanted["informacionContacto"] == request["informacionContacto"]
filters = urllib.parse.urlencode(dict(tipoPublicacion=4, mascoteroId=wanted["mascoteroId"], fechaDesde=today.isoformat(), fechaHasta=today.isoformat()))
assert wanted["id"] in [x["id"] for x in call("GET", "/api/publicaciones?" + filters)["items"]]
tomorrow = (today + datetime.timedelta(days=1)).isoformat()
assert call("GET", "/api/publicaciones?" + filters + "&estado=2")["total"] == 0
assert call("GET", "/api/publicaciones?" + urllib.parse.urlencode(dict(tipoPublicacion=4, mascoteroId=wanted["mascoteroId"], fechaDesde=tomorrow)))["total"] == 0
assert call("GET", "/api/publicaciones/" + wanted["id"])["fechaCreacion"]
call("PATCH", "/api/publicaciones/" + wanted["id"] + "/resolver", token=b["accessToken"], expected=403)
assert call("PATCH", "/api/publicaciones/" + wanted["id"] + "/resolver", token=token)["estado"] == 2
for extra in ({field: None for field in fields}, {"tipoMascota": 3, "tamano": 1, "colorPredominante": 7}, fields):
    item = call("POST", "/api/publicaciones", {**request, **extra}, token, 201)
    for field in fields:
        assert item[field] == extra.get(field)
    resolved = call("PATCH", "/api/publicaciones/" + item["id"] + "/resolver", token=token)
    assert all(resolved[field] == item[field] for field in fields)
for session in sessions:
    call("POST", "/api/auth/logout", {"refreshToken": session["refreshToken"]}, expected=204)
print("OK: creación sin fotos, validaciones, autor desde JWT, detalle público, filtros, paginación y resolución con permisos.")
print("OK: características opcionales, persistencia, catálogo por especie y rechazo de valores incompatibles.")
print("Datos de prueba identificados por:", TAG)
