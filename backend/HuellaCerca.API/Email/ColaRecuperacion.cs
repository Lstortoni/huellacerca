using System.Threading.Channels;

namespace HuellaCerca.API.Email;

/// Cola acotada y sin códigos: desacopla la respuesta pública del envío y de la existencia de la cuenta.
public sealed class ColaRecuperacion
{
    private readonly Channel<(string Email, DateTime Fecha)> canal = Channel.CreateBounded<(string, DateTime)>(100);
    public bool Agregar(string email) => canal.Writer.TryWrite((email, DateTime.UtcNow));
    public IAsyncEnumerable<(string Email, DateTime Fecha)> LeerAsync(CancellationToken ct) => canal.Reader.ReadAllAsync(ct);
}
