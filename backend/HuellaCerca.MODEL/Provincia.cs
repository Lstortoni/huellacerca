namespace HuellaCerca.MODEL;

public sealed class Provincia
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string GeorefId { get; set; } = "";
    public string PaisCodigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public bool Activa { get; set; } = true;
    public Pais Pais { get; set; } = null!;
    public ICollection<Localidad> Localidades { get; set; } = new List<Localidad>();
}

