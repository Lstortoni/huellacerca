namespace HuellaCerca.MODEL;

public sealed class FotoPublicacion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PublicacionMascotaId { get; set; }
    public string ObjectKey { get; set; } = "";
    public PublicacionMascota PublicacionMascota { get; set; } = null!;
}
