using HuellaCerca.INFRASTRUCTURE.Data;
using HuellaCerca.INFRASTRUCTURE.Repositories;
using HuellaCerca.INTERFACES.Repositories;
using HuellaCerca.INTERFACES.Services;
using HuellaCerca.SERVICES;
using Microsoft.EntityFrameworkCore;
using HuellaCerca.API.Errors;
using HuellaCerca.API.Security;
using HuellaCerca.INTERFACES.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.HttpOverrides;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddSingleton<IEmailTemplates, EmailTemplates>();
builder.Services.AddOptions<RecuperacionOptions>()
    .Bind(builder.Configuration.GetSection("PasswordRecovery"))
    .Validate(x => x.EsValida(), "PasswordRecovery:HmacKey requiere al menos 32 bytes aleatorios en Base64.")
    .Validate(x => !x.Enabled || builder.Configuration.GetValue<bool>("Brevo:Enabled"),
        "Habilitar Brevo para habilitar recuperación de contraseña.")
    .ValidateOnStart();
builder.Services.AddSingleton<IProtectorRecuperacion, ProtectorRecuperacion>();
builder.Services.AddScoped<IRecuperacionRepository, RecuperacionRepository>();
builder.Services.AddScoped<IRecuperacionService, RecuperacionService>();
builder.Services.AddSingleton<HuellaCerca.API.Email.ColaRecuperacion>();
builder.Services.AddHostedService<HuellaCerca.API.Email.EnviarCodigosRecuperacion>();
// Sólo confiar en proxies configurados explícitamente. Nunca aceptar X-Forwarded-For de cualquier origen.
builder.Services.Configure<ForwardedHeadersOptions>(options =>
{
    options.ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto;
    options.ForwardLimit = 1;
    foreach (var ip in (builder.Configuration["ReverseProxy:KnownProxies"] ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        options.KnownProxies.Add(System.Net.IPAddress.Parse(ip));
});

builder.Services.AddOptions<HuellaCerca.INFRASTRUCTURE.Email.BrevoOptions>()
    .Bind(builder.Configuration.GetSection("Brevo"))
    .Validate(x => x.EsValida(), "Brevo requiere BaseUrl HTTPS, SenderEmail, SenderName y ApiKey válidos al habilitar correos.")
    .ValidateOnStart();
builder.Services.AddHttpClient<IEmailService, HuellaCerca.INFRASTRUCTURE.Email.BrevoEmailService>(client =>
    client.Timeout = TimeSpan.FromSeconds(20))
    .ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler { AllowAutoRedirect = false })
    .RedactLoggedHeaders(new[] { "api-key" });

builder.Services.AddControllers();
builder.Services.AddHealthChecks();
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<AppExceptionHandler>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme { Type = SecuritySchemeType.Http, Scheme = "bearer", BearerFormat = "JWT" });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement {
        [new OpenApiSecurityScheme { Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" } }] = Array.Empty<string>()
    });
});
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")
        ?? throw new InvalidOperationException("Falta ConnectionStrings__DefaultConnection.")));
builder.Services.AddScoped<IUbicacionRepository, UbicacionRepository>();
builder.Services.AddScoped<IUbicacionService, UbicacionService>();
builder.Services.AddScoped<IAuthRepository, AuthRepository>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IRecomendacionRepository, RecomendacionRepository>();
builder.Services.AddScoped<IRecomendacionService, RecomendacionService>();
builder.Services.AddScoped<IPublicacionRepository, PublicacionRepository>();
builder.Services.AddScoped<IPublicacionService, PublicacionService>();
builder.Services.AddScoped<INotificacionRepository, NotificacionRepository>();
builder.Services.AddScoped<INotificacionService, NotificacionService>();
builder.Services.AddScoped<IPushRepository, PushRepository>();
builder.Services.AddScoped<IPushService, PushService>();
builder.Services.AddOptions<HuellaCerca.INFRASTRUCTURE.Push.FirebasePushSettings>()
    .Bind(builder.Configuration.GetSection("FirebasePush"))
    .Validate(x => !x.Enabled || (!string.IsNullOrWhiteSpace(x.ProjectId) && File.Exists(x.CredentialsPath)),
        "FirebasePush requiere ProjectId y CredentialsPath de una cuenta de servicio existente.")
    .ValidateOnStart();
builder.Services.AddSingleton<IEmisorPush, HuellaCerca.INFRASTRUCTURE.Push.FirebaseEmisorPush>();
builder.Services.AddHostedService<HuellaCerca.API.Notificaciones.EnviarNotificacionesPush>();
builder.Services.AddHostedService<HuellaCerca.API.Notificaciones.ProcesarNotificaciones>();
builder.Services.AddScoped<IFotoRepository, FotoRepository>();
builder.Services.AddScoped<IFotoService, FotoService>();
builder.Services.AddSingleton<IProcesadorFoto, HuellaCerca.INFRASTRUCTURE.Storage.ProcesadorFoto>();
builder.Services.AddOptions<HuellaCerca.INFRASTRUCTURE.Storage.R2Settings>().Bind(builder.Configuration.GetSection("R2"))
    .Validate(x => !x.Enabled || (Uri.TryCreate(x.Endpoint, UriKind.Absolute, out var uri)
        && uri.Scheme == "https" && !string.IsNullOrWhiteSpace(x.Bucket)
        && !string.IsNullOrWhiteSpace(x.AccessKeyId) && !string.IsNullOrWhiteSpace(x.SecretAccessKey)),
        "Configurar R2:Endpoint HTTPS, Bucket, AccessKeyId y SecretAccessKey al habilitar fotos.")
    .ValidateOnStart();
builder.Services.AddSingleton<IAlmacenamientoFotos, HuellaCerca.INFRASTRUCTURE.Storage.R2Fotos>();
builder.Services.AddHostedService<HuellaCerca.API.Fotos.LimpiezaFotos>();
builder.Services.AddSingleton<ICredenciales, Credenciales>();
builder.Services.AddOptions<JwtSettings>().Bind(builder.Configuration.GetSection("Jwt"))
    .Validate(x => Encoding.UTF8.GetByteCount(x.Key) >= 32 && !x.Key.StartsWith("CAMBIAR_") && !string.IsNullOrWhiteSpace(x.Issuer) && !string.IsNullOrWhiteSpace(x.Audience), "Configurar Jwt:Key (mínimo 32 bytes), Issuer y Audience.")
    .Validate(x => x.AccessMinutes is >= 1 and <= 60 && x.RefreshDays is >= 1 and <= 90, "Duración JWT o refresh fuera de rango.")
    .ValidateOnStart();
var jwt = builder.Configuration.GetSection("Jwt").Get<JwtSettings>() ?? new();
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.MapInboundClaims = false;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true, ValidIssuer = jwt.Issuer,
        ValidateAudience = true, ValidAudience = jwt.Audience,
        ValidateLifetime = true, RequireExpirationTime = true,
        RequireSignedTokens = true, ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
        ValidAlgorithms = [SecurityAlgorithms.HmacSha256],
        ClockSkew = TimeSpan.FromSeconds(5)
    };
    options.Events = new JwtBearerEvents { OnTokenValidated = async context =>
    {
        if (!Guid.TryParse(context.Principal?.FindFirst("sub")?.Value, out var userId) ||
            !Guid.TryParse(context.Principal?.FindFirst("mascoteroId")?.Value, out var mascoteroId) ||
            !Guid.TryParse(context.Principal?.FindFirst("sid")?.Value, out var sesionId))
        { context.Fail("Identidad inválida."); return; }
        var db = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
        // Tokens anteriores a esta versión no tienen sv: sólo son válidos hasta el primer restablecimiento.
        var versionText = context.Principal?.FindFirst("sv")?.Value;
        var version = Guid.Empty;
        if (versionText is not null && !Guid.TryParse(versionText, out version))
        { context.Fail("Versión de sesión inválida."); return; }
        var ahora = DateTime.UtcNow;
        if (!await db.RefreshTokens.AnyAsync(x => x.UsuarioId == userId && x.SesionId == sesionId
            && x.FechaRevocacion == null && x.FechaExpiracion > ahora && x.VersionSeguridad == version
            && x.Usuario.MascoteroId == mascoteroId && x.Usuario.Activo && x.Usuario.VersionSeguridad == version,
            context.HttpContext.RequestAborted))
            context.Fail("Sesión revocada o inválida.");
    }};
});
builder.Services.AddAuthorization();
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = 429;
    options.AddPolicy("recuperacion", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 10, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    options.AddPolicy("fotos", context => RateLimitPartition.GetFixedWindowLimiter(
        context.User.FindFirst("sub")?.Value ?? context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 15, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    options.AddPolicy("auth", context => RateLimitPartition.GetFixedWindowLimiter(
        context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
        _ => new FixedWindowRateLimiterOptions { PermitLimit = 60, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
});

var app = builder.Build();
app.UseForwardedHeaders();
app.UseExceptionHandler();
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.MapControllers();
app.MapHealthChecks("/health");

app.Run();

// Punto de entrada accesible para las pruebas HTTP en un servidor en memoria.
public partial class Program { }
