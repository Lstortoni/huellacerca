using HuellaCerca.MODEL;
namespace HuellaCerca.INTERFACES.Security;

public interface ICredenciales
{
    string HashPassword(string password);
    bool VerifyPassword(string hash, string password);
    (string Token, DateTime Expira) CrearAccessToken(Usuario usuario, Guid sesionId);
    int RefreshDias { get; }
}

