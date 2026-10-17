namespace HuellaCerca.CONTRACT.Email;

/// Contenido de un correo; no incluye destinatario ni datos del proveedor.
public sealed record ContenidoEmail(string Asunto, string Html, string Texto);
