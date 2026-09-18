"""Integración HTTP: crea cuentas etiquetadas hc-test-* y limpia sus recomendaciones.

Ejecutar únicamente en desarrollo con docker compose. No imprime credenciales.
"""
import base64
import concurrent.futures
import hashlib
import hmac
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

BASE = os.environ.get("API_BASE_URL", "http://huellacerca_api:8080")
TAG = "hc-test-" + uuid.uuid4().hex[:12]
PASSWORD = "Prueba.Local-2026!"


def call(method, path, body=None, token=None, expected=200):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(BASE + path,
        data=json.dumps(body).encode() if body is not None else None, headers=headers, method=method)
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            status, data = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, data = error.code, error.read()
    assert status == expected, (method, path, expected, status, data[:300] if status >= 400 else "respuesta inesperada")
    return json.loads(data) if data else None


def register(suffix, locality):
    data = dict(nombre="Prueba " + suffix, apellido="Comunidad", email=f"{TAG}-{suffix}@example.invalid",
        password=PASSWORD, passwordConfirm=PASSWORD, localidadId=locality)
    return data, call("POST", "/api/auth/register", data, expected=201)


def refresh(session, expected=200):
    return call("POST", "/api/auth/refresh", {"refreshToken": session["refreshToken"]}, expected=expected)


provincias = call("GET", "/api/provincias")
provincia = provincias[0]["id"]
locality = call("GET", "/api/localidades?provinciaId=" + provincia)["items"][0]["id"]
data_a, a = register("a", locality)
data_b, b = register("b", locality)
assert a["usuario"]["id"] != a["usuario"]["mascotero"]["id"]
assert a["usuario"]["mascotero"]["localidadId"] == locality
assert "passwordHash" not in json.dumps(a)
call("POST", "/api/auth/register", {**data_a, "email": data_a["email"].upper()}, expected=409)
bad_email = f"{TAG}-invalid@example.invalid"
call("POST", "/api/auth/register", {**data_a, "email": bad_email, "localidadId": str(uuid.uuid4())}, expected=400)
call("POST", "/api/auth/login", {"email": bad_email, "password": PASSWORD}, expected=401)
call("POST", "/api/auth/register", {**data_a, "passwordConfirm": "distinta"}, expected=400)
call("POST", "/api/auth/login", {"email": data_a["email"], "password": "incorrecta"}, expected=401)
call("GET", "/api/auth/me", expected=401)
assert call("GET", "/api/auth/me", token=a["accessToken"])["id"] == a["usuario"]["id"]
login = call("POST", "/api/auth/login", {"email": data_a["email"], "password": PASSWORD})
rotated = refresh(login)
assert rotated["refreshToken"] != login["refreshToken"]
assert rotated["accessToken"] != login["accessToken"]
refresh(login, 401)  # replay revoca la familia
refresh(rotated, 401)
call("POST", "/api/auth/logout", {"refreshToken": a["refreshToken"]}, expected=204)
refresh(a, 401)
call("POST", "/api/auth/logout", {"refreshToken": "x" * 64}, expected=204)
call("POST", "/api/auth/refresh", {"refreshToken": "x" * 64}, expected=401)

# JWT firmados de prueba: vencimiento, issuer y audience deben rechazarse.
def encode(value):
    return base64.urlsafe_b64encode(json.dumps(value, separators=(",", ":")).encode()).rstrip(b"=").decode()


header, payload, signature = b["accessToken"].split(".")
claims = json.loads(base64.urlsafe_b64decode(payload + "=" * (-len(payload) % 4)))
key = os.environ["JWT_TEST_KEY"].encode()
for modifications in ({"exp": int(time.time()) - 120, "nbf": int(time.time()) - 300},
                      {"iss": "OtroEmisor"}, {"aud": "OtraApp"}, {"mascoteroId": str(uuid.uuid4())}):
    segment = header + "." + encode({**claims, **modifications})
    signed = base64.urlsafe_b64encode(hmac.new(key, segment.encode(), hashlib.sha256).digest()).rstrip(b"=").decode()
    call("GET", "/api/auth/me", token=segment + "." + signed, expected=401)
call("GET", "/api/auth/me", token=header + "." + payload + "." + ("A" * len(signature)), expected=401)

# Dos renovaciones simultáneas nunca deben producir dos sesiones válidas.
race_session = call("POST", "/api/auth/login", {"email": data_b["email"], "password": PASSWORD})
def race(_):
    try:
        refresh(race_session)
        return 200
    except AssertionError as error:
        assert error.args[0][3] == 401, error
        return 401
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    results = list(pool.map(race, range(2)))
assert sorted(results) == [200, 401], results

# Recomendación = voto único, con aspectos opcionales.
a = call("POST", "/api/auth/login", {"email": data_a["email"], "password": PASSWORD})
rubro = call("GET", "/api/rubros")[0]["id"]
aspectos = call("GET", "/api/aspectos-recomendacion")
assert len(aspectos) == 6 and all(x["activo"] for x in aspectos)
ids = [x["id"] for x in aspectos[:2]]
new_provider = dict(nombre=TAG + " Veterinaria Los Tilos", rubroId=rubro, localidadId=locality,
    direccion="Dirección de prueba", telefono="000", enlace="https://example.invalid")
request = dict(nuevoPrestador=new_provider)
at, bt = a["accessToken"], b["accessToken"]
call("POST", "/api/recomendaciones", request, expected=401)
call("POST", "/api/recomendaciones", {**request, "titulo": "Texto anterior"}, at, 400)
call("POST", "/api/recomendaciones", {**request, "prestadorServicioId": str(uuid.uuid4())}, at, 400)
call("POST", "/api/recomendaciones", {**request, "nuevoPrestador": {**new_provider, "enlace": "javascript:alert(1)"}}, at, 400)
first = call("POST", "/api/recomendaciones", request, at, 201)
assert first["mascoteroId"] == a["usuario"]["mascotero"]["id"]
assert first["aspectos"] == [] and "titulo" not in first and "descripcion" not in first
pid, rid = first["prestador"]["id"], first["id"]
assert first["prestador"]["totalRecomendaciones"] == 1
existing = dict(prestadorServicioId=pid)
assert call("POST", "/api/recomendaciones", existing, at)["id"] == rid
query = urllib.parse.urlencode(dict(nombre=TAG + " Veterinaria Los Tilo", rubroId=rubro, localidadId=locality))
assert pid in [p["id"] for p in call("GET", "/api/prestadores/similares?" + query)]
call("GET", "/api/recomendaciones/" + rid, expected=401)
call("GET", "/api/recomendaciones/" + rid, token=bt, expected=403)
call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": ids}, bt, 403)
call("DELETE", "/api/recomendaciones/" + rid, token=bt, expected=403)
call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": [str(uuid.uuid4())]}, at, 400)
call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": None}, at, 400)
updated = call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": ids + [ids[0]]}, at)
assert {x["id"] for x in updated["aspectos"]} == set(ids)
assert len(updated["aspectos"]) == 2
repeat = call("POST", "/api/recomendaciones", existing, at)
assert repeat["id"] == rid and len(repeat["aspectos"]) == 2
assert repeat["prestador"]["totalRecomendaciones"] == 1

# Dos solicitudes concurrentes del mismo mascotero producen una sola recomendación.
def vote(_):
    try:
        return call("POST", "/api/recomendaciones", existing, bt, 201)
    except AssertionError as e:
        assert e.args[0][3] == 200, e
        return call("POST", "/api/recomendaciones", existing, bt)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    votes = list(pool.map(vote, range(2)))
assert votes[0]["id"] == votes[1]["id"]
second = votes[0]
provider = call("GET", "/api/prestadores/" + pid)
assert provider["totalRecomendaciones"] == 2
people_path = "/api/prestadores/" + pid + "/recomendadores"
people1 = call("GET", people_path + "?pagina=1&tamanoPagina=1")
people2 = call("GET", people_path + "?pagina=2&tamanoPagina=1")
assert people1["total"] == people2["total"] == 2
assert len(people1["items"]) == len(people2["items"]) == 1
people = people1["items"] + people2["items"]
assert sorted(p["nombre"] for p in people) == ["Prueba a", "Prueba b"]
assert all(set(p) == {"nombre"} for p in people), "No exponer datos privados del perfil."
call("GET", people_path + "?pagina=0", expected=400)
call("GET", "/api/prestadores/" + str(uuid.uuid4()) + "/recomendadores", expected=404)
assert {x["id"]: x["cantidad"] for x in provider["aspectos"]} == {i: 1 for i in ids}
call("PUT", "/api/recomendaciones/" + second["id"] + "/aspectos", {"aspectoIds": [ids[0]]}, bt)
provider = call("GET", "/api/prestadores/" + pid)
assert {x["id"]: x["cantidad"] for x in provider["aspectos"]} == {ids[0]: 2, ids[1]: 1}
call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": []}, at)
provider = call("GET", "/api/prestadores/" + pid)
assert provider["totalRecomendaciones"] == 2 and provider["aspectos"][0]["cantidad"] == 1

# Las ediciones simultáneas no duplican vínculos ni devuelven errores internos.
def edit_aspects(_):
    try:
        call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": ids}, at)
        return 200
    except AssertionError as e:
        assert e.args[0][3] == 409, e
        return 409
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    edits = list(pool.map(edit_aspects, range(2)))
assert 200 in edits
assert len(call("GET", "/api/recomendaciones/" + rid, token=at)["aspectos"]) == 2
call("PUT", "/api/recomendaciones/" + rid + "/aspectos", {"aspectoIds": []}, at)

mias = call("GET", "/api/recomendaciones/mias?" + urllib.parse.urlencode({
    "prestadorServicioId": pid, "mascoteroId": b["usuario"]["mascotero"]["id"]}), token=at)
assert mias["total"] == 1 and mias["items"][0]["id"] == rid
assert call("GET", "/api/recomendaciones/mias?prestadorServicioId=" + str(uuid.uuid4()), token=at)["total"] == 0
duplicate = call("POST", "/api/recomendaciones", request, at, 201)
assert duplicate["prestador"]["id"] != pid, "Se permiten fichas distintas con nombres similares."
page = call("GET", "/api/prestadores?" + urllib.parse.urlencode(dict(busqueda=TAG, localidadId=locality, rubroId=rubro)))
assert page["total"] == 2 and len({p["id"] for p in page["items"]}) == 2
assert call("GET", "/api/prestadores?" + urllib.parse.urlencode(dict(busqueda=TAG, localidadId=str(uuid.uuid4()))))["total"] == 0
for item, token in ((first, at), (second, bt), (duplicate, at)):
    call("DELETE", "/api/recomendaciones/" + item["id"], token=token, expected=204)
    call("GET", "/api/recomendaciones/" + item["id"], token=token, expected=404)
provider = call("GET", "/api/prestadores/" + pid)
assert provider["totalRecomendaciones"] == 0 and provider["aspectos"] == []
assert call("GET", people_path)["total"] == 0
assert call("GET", "/api/prestadores?" + urllib.parse.urlencode(dict(busqueda=TAG)))["total"] == 0
assert pid in [p["id"] for p in call("GET", "/api/prestadores/similares?" + query)]
print("OK: auth, JWT, refresh, recomendación sin aspectos, edición, permisos, concurrencia, unicidad y conteos.")
print("Cuentas y prestadores de prueba identificables por:", TAG)
