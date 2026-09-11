namespace HuellaCerca.API.Security;

public sealed class JwtSettings
{
    public string Key { get; set; } = "";
    public string Issuer { get; set; } = "HuellaCercaApi";
    public string Audience { get; set; } = "HuellaCercaMobile";
    public int AccessMinutes { get; set; } = 15;
    public int RefreshDays { get; set; } = 30;
}

