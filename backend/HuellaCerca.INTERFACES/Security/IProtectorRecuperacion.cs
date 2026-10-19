namespace HuellaCerca.INTERFACES.Security;

public interface IProtectorRecuperacion
{
    string ProtegerCodigo(Guid id, string codigo);
    bool VerificarCodigo(Guid id, string codigo, string hash);
}
