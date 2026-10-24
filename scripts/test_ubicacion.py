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
assert all(x["provincia"] == "Córdoba" for x in lower["items"]), "Incluye el nombre de la provincia."
# Sin provincia busca en todo el país; primero las que empiezan con lo escrito.
pais = get("/api/localidades?busqueda=la%20plata&tamanoPagina=100")
assert pais["total"] > 0
assert pais["items"][0]["nombre"].upper().startswith("LA PLATA"), pais["items"][0]
nombres = [x["nombre"].upper() for x in pais["items"]]
primera_que_no_empieza = next((i for i, n in enumerate(nombres) if not n.startswith("LA PLATA")), len(nombres))
assert all(not n.startswith("LA PLATA") for n in nombres[primera_que_no_empieza:]), "Prefijos primero."
assert len({x["provinciaId"] for x in get("/api/localidades?busqueda=san%20martin&tamanoPagina=100")["items"]}) > 1, \
    "Búsqueda nacional devuelve localidades homónimas de varias provincias."
for invalid in (
    "/api/localidades",
    "/api/localidades?busqueda=l",
    "/api/localidades?busqueda=%20%20",
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
una = lower["items"][0]
assert get("/api/localidades/" + una["id"]) == una, "Detalle de localidad con su provincia."
get("/api/localidades/ffffffff-ffff-ffff-ffff-ffffffffffff", 404)
print("OK: catálogo, búsqueda provincial y nacional, acentos, orden por prefijo, paginación, Swagger y errores HTTP.")
