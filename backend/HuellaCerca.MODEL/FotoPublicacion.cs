namespace HuellaCerca.MODEL;

public sealed class FotoPublicacion
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid PublicacionMascotaId { get; set; }
    // Referencia al archivo: el mecanismo de carga y almacenamiento se implementará después.
    public string RutaArchivo { get; set; } = "";
    public int Orden { get; set; }
    public PublicacionMascota PublicacionMascota { get; set; } = null!;
}

