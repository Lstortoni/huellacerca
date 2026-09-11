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
    data = dict(nombre="Prueba", apellido="Comunidad", email=f"{TAG}-{suffix}@example.invalid",
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

# Recomendaciones: prestador nuevo o existente, nunca ambos; autor desde JWT.
a = call("POST", "/api/auth/login", {"email": data_a["email"], "password": PASSWORD})
rubro = call("GET", "/api/rubros")[0]["id"]
new_provider = dict(nombre=TAG + " Veterinaria Los Tilos", rubroId=rubro, localidadId=locality,
    direccion="Dirección de prueba", telefono="000", enlace="https://example.invalid")
request = dict(titulo=TAG + " experiencia", descripcion="Muy buena atención en esta prueba.",
    nuevoPrestador=new_provider)
call("POST", "/api/recomendaciones", request, expected=401)
call("POST", "/api/recomendaciones", {**request, "prestadorServicioId": str(uuid.uuid4())}, a["accessToken"], 400)
call("POST", "/api/recomendaciones", {**request, "nuevoPrestador": {**new_provider, "enlace": "javascript:alert(1)"}}, a["accessToken"], 400)
first = call("POST", "/api/recomendaciones", request, a["accessToken"], 201)
assert first["mascoteroId"] == a["usuario"]["mascotero"]["id"]
provider_id = first["prestador"]["id"]
query = urllib.parse.urlencode(dict(nombre=TAG + " Veterinaria Los Tilo", rubroId=rubro, localidadId=locality))
assert provider_id in [p["id"] for p in call("GET", "/api/prestadores/similares?" + query)]
assert call("GET", "/api/prestadores/" + provider_id)["nombre"] == new_provider["nombre"]
second = call("POST", "/api/recomendaciones", dict(prestadorServicioId=provider_id,
    titulo=TAG + " segunda", descripcion="Otra experiencia de prueba con el mismo lugar."), b["accessToken"], 201)
assert second["prestador"]["id"] == provider_id
assert second["mascoteroId"] == b["usuario"]["mascotero"]["id"]
duplicate = call("POST", "/api/recomendaciones", request, a["accessToken"], 201)
assert duplicate["prestador"]["id"] != provider_id, "Se permite crear otro prestador parecido."
page = call("GET", "/api/recomendaciones?" + urllib.parse.urlencode(dict(busqueda=TAG, localidadId=locality, rubroId=rubro)))
assert page["total"] == 3
assert call("GET", "/api/recomendaciones?" + urllib.parse.urlencode(dict(busqueda=TAG, localidadId=str(uuid.uuid4()))))["total"] == 0
edit = dict(titulo="Editada", descripcion="Experiencia de prueba actualizada correctamente.")
call("PUT", "/api/recomendaciones/" + first["id"], edit, b["accessToken"], 403)
call("DELETE", "/api/recomendaciones/" + first["id"], token=b["accessToken"], expected=403)
updated = call("PUT", "/api/recomendaciones/" + first["id"], edit, a["accessToken"])
assert updated["fechaActualizacion"] and updated["titulo"] == "Editada"
for item, session in ((first, a), (second, b), (duplicate, a)):
    call("DELETE", "/api/recomendaciones/" + item["id"], token=session["accessToken"], expected=204)
    call("GET", "/api/recomendaciones/" + item["id"], expected=404)
assert call("GET", "/api/prestadores/" + provider_id)["id"] == provider_id
print("OK: registro, validaciones, login, JWT, refresh, replay, concurrencia, logout y recomendaciones con permisos.")
print("Cuentas y prestadores de prueba identificables por:", TAG)
