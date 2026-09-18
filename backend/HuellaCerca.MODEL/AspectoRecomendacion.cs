namespace HuellaCerca.MODEL;

public sealed class AspectoRecomendacion
{
    public Guid Id { get; set; }
    public string Nombre { get; set; } = "";
    public bool Activo { get; set; } = true;
}

public sealed class RecomendacionAspecto
{
    public Guid RecomendacionId { get; set; }
    public Guid AspectoRecomendacionId { get; set; }
    public Recomendacion Recomendacion { get; set; } = null!;
    public AspectoRecomendacion AspectoRecomendacion { get; set; } = null!;
}
