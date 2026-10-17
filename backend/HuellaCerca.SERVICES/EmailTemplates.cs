using HuellaCerca.CONTRACT.Email;
using HuellaCerca.INTERFACES.Services;

namespace HuellaCerca.SERVICES;

/// Arma el contenido de los correos. No genera códigos ni realiza envíos.
public sealed class EmailTemplates : IEmailTemplates
{
    public ContenidoEmail RecuperacionPassword(string codigo)
    {
        if (codigo is null || codigo.Length != 6 || codigo.Any(c => c < '0' || c > '9'))
            throw new ArgumentException("El código debe contener seis dígitos numéricos.", nameof(codigo));

        var html = $"""
            <!doctype html>
            <html lang="es">
            <head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
            <body style="margin:0;padding:24px;background-color:#f6f5f0;font-family:Arial,sans-serif;color:#24332d;">
              <div style="max-width:560px;margin:0 auto;padding:24px;background-color:#ffffff;border-radius:12px;">
                <h1 style="font-size:24px;color:#246653;">Huella Cerca</h1>
                <h2 style="font-size:20px;">Recuperar contraseña</h2>
                <p>Hola,</p>
                <p>Recibimos una solicitud para recuperar la contraseña de tu cuenta de Huella Cerca.</p>
                <p>Ingresá este código en la aplicación:</p>
                <p style="font-size:32px;font-weight:bold;letter-spacing:6px;color:#246653;">{codigo}</p>
                <p>Este código vence dentro de <strong>10 minutos</strong> y puede utilizarse una sola vez.</p>
                <p>No compartas este código con otras personas.</p>
                <p>Si no solicitaste recuperar tu contraseña, podés ignorar este mensaje.</p>
                <p>Equipo Huella Cerca</p>
              </div>
            </body>
            </html>
            """;
        var texto = $"""
            Hola,

            Recibimos una solicitud para recuperar la contraseña de tu cuenta de Huella Cerca.

            Ingresá este código en la aplicación: {codigo}

            Este código vence dentro de 10 minutos y puede utilizarse una sola vez.
            No compartas este código con otras personas.

            Si no solicitaste recuperar tu contraseña, podés ignorar este mensaje.

            Equipo Huella Cerca
            """;
        return new ContenidoEmail("Recuperación de contraseña — Huella Cerca", html, texto);
    }
}
