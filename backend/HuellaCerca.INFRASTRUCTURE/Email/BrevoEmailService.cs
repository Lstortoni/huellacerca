using System.Net.Http.Json;
using System.Text.Json;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HuellaCerca.INFRASTRUCTURE.Email;

public sealed class BrevoEmailService(HttpClient client, IOptions<BrevoOptions> options,
    ILogger<BrevoEmailService> logger) : IEmailService
{
    public async Task<string?> EnviarAsync(string destinatario, string asunto, string html,
        string texto, CancellationToken ct = default)
    {
        var config = options.Value;
        if (!config.Enabled) throw new AppException(503, "El envío de correos no está habilitado.");
        using var request = new HttpRequestMessage(HttpMethod.Post,
            new Uri(new Uri(config.BaseUrl.TrimEnd('/') + "/"), "smtp/email"));
        request.Headers.Add("api-key", config.ApiKey);
        request.Content = JsonContent.Create(new {
            sender = new { email = config.SenderEmail, name = config.SenderName },
            to = new[] { new { email = destinatario } }, subject = asunto,
            htmlContent = html, textContent = texto
        });
        try
        {
            using var response = await client.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                // No registrar respuesta, destinatario, contenido ni encabezados privados.
                logger.LogWarning("Brevo rechazó un envío. HTTP {StatusCode}.", (int)response.StatusCode);
                throw new AppException(503, "No pudimos enviar el correo. Intentá nuevamente más tarde.");
            }
            string? id = null;
            try
            {
                var result = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: ct);
                if (result.ValueKind == JsonValueKind.Object && result.TryGetProperty("messageId", out var field)
                    && field.ValueKind == JsonValueKind.String) id = field.GetString();
            }
            catch (JsonException)
            {
                // Ya fue aceptado: una respuesta inesperada no debe provocar otro envío.
                logger.LogWarning("Brevo aceptó un correo sin una respuesta JSON interpretable.");
            }
            logger.LogInformation("Brevo aceptó un correo transaccional.");
            return id;
        }
        catch (OperationCanceledException) when (!ct.IsCancellationRequested)
        {
            logger.LogWarning("Se agotó el tiempo de espera de Brevo; entrega no confirmada.");
            throw new AppException(503, "No pudimos confirmar el envío del correo. Intentá nuevamente más tarde.");
        }
        catch (HttpRequestException)
        {
            logger.LogWarning("No se pudo confirmar la comunicación con Brevo.");
            throw new AppException(503, "No pudimos confirmar el envío del correo. Intentá nuevamente más tarde.");
        }
    }
}
