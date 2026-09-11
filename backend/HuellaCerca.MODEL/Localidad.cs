namespace HuellaCerca.MODEL;

public sealed class Localidad
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string GeorefId { get; set; } = "";
    public Guid ProvinciaId { get; set; }
    public string Nombre { get; set; } = "";
    public string NombreBusqueda { get; set; } = "";
    public bool Activa { get; set; } = true;
    public decimal? Latitud { get; set; }
    public decimal? Longitud { get; set; }
    public Provincia Provincia { get; set; } = null!;
}

