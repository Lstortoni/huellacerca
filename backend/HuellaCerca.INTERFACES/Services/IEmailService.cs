namespace HuellaCerca.INTERFACES.Services;

/// Envía correo transaccional. El identificador confirma aceptación, no entrega.
public interface IEmailService
{
    Task<string?> EnviarAsync(string destinatario, string asunto, string html,
        string texto, CancellationToken ct = default);
}
