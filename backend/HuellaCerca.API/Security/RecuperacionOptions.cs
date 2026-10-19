namespace HuellaCerca.API.Security;

public sealed class RecuperacionOptions
{
    public bool Enabled { get; set; }
    public string HmacKey { get; set; } = "";
    public bool EsValida()
    {
        if (!Enabled) return true;
        try { return Convert.FromBase64String(HmacKey).Length >= 32; }
        catch (FormatException) { return false; }
    }
}
