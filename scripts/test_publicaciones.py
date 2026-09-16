"""Pruebas HTTP de desarrollo. Deja dos cuentas y dos avisos resueltos hc-pets-test-*.

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
call("POST", "/api/publicaciones", request, expected=401)
for bad in (
    {"tipoPublicacion": 0}, {"tipoPublicacion": 3}, {"tipoMascota": 4},
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
assert first["estado"] == 1 and first["fotografias"] == [] and first["nombreMascota"] is None
assert first["provinciaId"] == province and first["localidadId"] == locality
assert first["fechaSuceso"] == today.isoformat()
second = call("POST", "/api/publicaciones", {**request, "tipoPublicacion": 2, "tipoMascota": 2,
    "nombreMascota": "  Michi  ", "fechaSuceso": (today - datetime.timedelta(days=1)).isoformat()}, token, 201)
assert second["nombreMascota"] == "Michi"
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
for session in sessions:
    call("POST", "/api/auth/logout", {"refreshToken": session["refreshToken"]}, expected=204)
print("OK: creación sin fotos, validaciones, autor desde JWT, detalle público, filtros, paginación y resolución con permisos.")
print("Datos de prueba identificados por:", TAG)
