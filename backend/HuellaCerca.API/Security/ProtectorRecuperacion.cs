using System.Security.Cryptography;
using System.Text;
using HuellaCerca.INTERFACES.Security;
using Microsoft.Extensions.Options;

namespace HuellaCerca.API.Security;

public sealed class ProtectorRecuperacion(IOptions<RecuperacionOptions> options) : IProtectorRecuperacion
{
    public string ProtegerCodigo(Guid id, string codigo) => Convert.ToHexString(HMACSHA256.HashData(
        Convert.FromBase64String(options.Value.HmacKey), Encoding.UTF8.GetBytes($"recuperacion:{id:N}:{codigo}")));
    public bool VerificarCodigo(Guid id, string codigo, string hash) =>
        CryptographicOperations.FixedTimeEquals(Encoding.UTF8.GetBytes(ProtegerCodigo(id, codigo)), Encoding.UTF8.GetBytes(hash));
}
