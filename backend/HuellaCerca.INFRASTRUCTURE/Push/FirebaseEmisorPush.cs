using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using HuellaCerca.INTERFACES.Services;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HuellaCerca.INFRASTRUCTURE.Push;

public sealed class FirebasePushSettings
{
    public bool Enabled { get; set; }
    public string ProjectId { get; set; } = "";
    public string CredentialsPath { get; set; } = "";
}

public sealed class FirebaseEmisorPush : IEmisorPush, IDisposable
{
    private readonly FirebaseApp? app;
    private readonly ILogger<FirebaseEmisorPush> logger;
    public bool Habilitado => app != null;

    public FirebaseEmisorPush(IOptions<FirebasePushSettings> options, ILogger<FirebaseEmisorPush> logger)
    {
        this.logger = logger;
        var settings = options.Value;
        if (!settings.Enabled) return;
        // El JSON es una cuenta de servicio del backend; nunca google-services.json de Android.
        var credential = CredentialFactory.FromFile<ServiceAccountCredential>(settings.CredentialsPath).ToGoogleCredential();
        app = FirebaseApp.Create(new AppOptions { Credential = credential, ProjectId = settings.ProjectId }, "huella-cerca-push");
    }

    public async Task<ResultadoPush> EnviarAsync(TrabajoPush trabajo, CancellationToken ct)
    {
        if (app is null) return ResultadoPush.Reintentar;
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(ct);
        timeout.CancelAfter(TimeSpan.FromSeconds(30));
        try
        {
            await FirebaseMessaging.GetMessaging(app).SendAsync(new Message
            {
                // Flutter getToken() entrega un token FCM, no un Firebase Installation ID (FID).
#pragma warning disable CS0618
                Token = trabajo.Token,
#pragma warning restore CS0618
                Notification = new Notification { Title = trabajo.Titulo, Body = trabajo.Mensaje },
                Data = new Dictionary<string, string>
                {
                    ["tipo"] = "coincidencia",
                    ["notificacionId"] = trabajo.NotificacionId.ToString(),
                    ["publicacionId"] = trabajo.PublicacionId.ToString(),
                    ["mascoteroId"] = trabajo.MascoteroId.ToString()
                },
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    TimeToLive = TimeSpan.FromHours(24) - (DateTime.UtcNow - trabajo.FechaCreacion),
                    Notification = new AndroidNotification { Tag = trabajo.NotificacionId.ToString(), Icon = "ic_notificacion" }
                }
            }, timeout.Token);
            logger.LogInformation("Push {EnvioId} aceptado por Firebase", trabajo.Id);
            return ResultadoPush.Enviado;
        }
        catch (FirebaseMessagingException ex)
        {
            // No registrar el token ni el payload. InvalidArgument puede ser un error del mensaje, no del token.
            logger.LogWarning("Push {EnvioId}: Firebase {Codigo}", trabajo.Id, ex.MessagingErrorCode);
            return ex.MessagingErrorCode == MessagingErrorCode.Unregistered
                ? ResultadoPush.TokenInvalido : ResultadoPush.Reintentar;
        }
    }

    public void Dispose() => app?.Delete();
}
