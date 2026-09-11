"""Pruebas HTTP de solo lectura contra la API y el catálogo importado."""
import json
import os
import urllib.error
import urllib.request

BASE = os.environ.get("API_BASE_URL", "http://huellacerca_api:8080")


def get(path, expected=200):
    try:
        with urllib.request.urlopen(BASE + path, timeout=30) as response:
            status, body = response.status, response.read()
    except urllib.error.HTTPError as error:
        status, body = error.code, error.read()
    assert status == expected, (path, expected, status, body[:200])
    return json.loads(body) if body and body[:1] in (b"{", b"[") else body


assert get("/health") == b"Healthy"
assert "/api/localidades" in get("/swagger/v1/swagger.json")["paths"]
assert any(x["codigo"] == "AR" for x in get("/api/paises"))
provincias = get("/api/provincias")
assert len(provincias) == 24, "Importar GeoRef antes de ejecutar estas pruebas."
assert provincias == get("/api/provincias?paisCodigo=ar")
cordoba = next(p for p in provincias if p["nombre"] == "Córdoba")
path = "/api/localidades?provinciaId=" + cordoba["id"]
lower = get(path + "&busqueda=cordoba")
upper = get(path + "&busqueda=C%C3%93RDOBA")
assert lower["total"] > 0 and lower == upper, "Búsqueda sin acentos ni mayúsculas."
assert all(x["provinciaId"] == cordoba["id"] for x in lower["items"])
page1 = get(path + "&pagina=1&tamanoPagina=2")
page2 = get(path + "&pagina=2&tamanoPagina=2")
assert len(page1["items"]) == len(page2["items"]) == 2
assert page1["total"] == page2["total"]
assert not ({x["id"] for x in page1["items"]} & {x["id"] for x in page2["items"]})
empty = get(path + "&busqueda=zzzzhuellacercasincoincidencias")
assert empty["items"] == [] and empty["total"] == 0
for invalid in (
    "/api/localidades",
    "/api/localidades?provinciaId=no-es-guid",
    "/api/localidades?provinciaId=00000000-0000-0000-0000-000000000000",
    path + "&tamanoPagina=101",
    path + "&tamanoPagina=0",
    path + "&pagina=0",
    path + "&busqueda=" + "a" * 151,
    "/api/provincias?paisCodigo=INVALIDO",
):
    get(invalid, 400)
get("/api/localidades?provinciaId=ffffffff-ffff-ffff-ffff-ffffffffffff", 404)
print("OK: catálogo, búsqueda, acentos, filtro, paginación, Swagger y errores HTTP.")
