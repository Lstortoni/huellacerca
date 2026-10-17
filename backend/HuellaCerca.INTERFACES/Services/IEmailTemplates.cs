using HuellaCerca.CONTRACT.Email;

namespace HuellaCerca.INTERFACES.Services;

public interface IEmailTemplates
{
    ContenidoEmail RecuperacionPassword(string codigo);
}
