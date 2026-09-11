namespace HuellaCerca.MODEL;

public sealed class Pais
{
    public string Codigo { get; set; } = "";
    public string Nombre { get; set; } = "";
    public bool Activo { get; set; } = true;
    public ICollection<Provincia> Provincias { get; set; } = new List<Provincia>();
}

