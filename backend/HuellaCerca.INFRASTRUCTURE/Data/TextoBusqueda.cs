using System.Globalization;
using System.Text;

namespace HuellaCerca.INFRASTRUCTURE.Data;

public static class TextoBusqueda
{
    public static string Normalizar(string text) => new string(text.Trim().Normalize(NormalizationForm.FormD)
        .Where(c => CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark).ToArray())
        .Normalize(NormalizationForm.FormC).ToUpperInvariant();
}

