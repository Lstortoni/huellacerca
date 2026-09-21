namespace HuellaCerca.MODEL;

// Cola durable: recupera subidas interrumpidas y elimina versiones reemplazadas.
public sealed class FotoPendienteLimpieza
{
    public string ObjectKey { get; set; } = "";
    public DateTime LimpiarDesdeUtc { get; set; }
}
