using System.Net.Mail;

namespace HuellaCerca.INFRASTRUCTURE.Email;

public sealed class BrevoOptions
{
    public bool Enabled { get; set; }
    public string BaseUrl { get; set; } = "https://api.brevo.com/v3/";
    public string SenderEmail { get; set; } = "no-reply@huellacerca.online";
    public string SenderName { get; set; } = "Huella Cerca";
    public string ApiKey { get; set; } = "";

    public bool EsValida() => !Enabled || (
        Uri.TryCreate(BaseUrl, UriKind.Absolute, out var uri) && uri.Scheme == "https"
        && string.IsNullOrEmpty(uri.UserInfo) && string.IsNullOrEmpty(uri.Query)
        && string.IsNullOrEmpty(uri.Fragment)
        && MailAddress.TryCreate(SenderEmail, out var address) && address.Address == SenderEmail
        && !string.IsNullOrWhiteSpace(SenderName) && !string.IsNullOrWhiteSpace(ApiKey)
        && !ApiKey.Contains('\r') && !ApiKey.Contains('\n'));
}
