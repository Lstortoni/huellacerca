using System.Net;
using System.Text.Json;
using HuellaCerca.INFRASTRUCTURE.Email;
using HuellaCerca.INTERFACES;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

var config = new BrevoOptions { Enabled = true, ApiKey = "fake-test-key" };
void Check(bool condition) { if (!condition) throw new Exception("Falló una comprobación de correo."); }
Check(config.EsValida());
Check(!new BrevoOptions { Enabled = true }.EsValida());
Check(new BrevoOptions().EsValida());
Check(!new BrevoOptions { Enabled = true, ApiKey = "test", BaseUrl = "http://example.invalid" }.EsValida());
var handler = new FakeHandler(async (request, ct) => {
    Check(request.Method == HttpMethod.Post);
    Check(request.RequestUri!.ToString() == "https://api.brevo.com/v3/smtp/email");
    Check(request.Headers.GetValues("api-key").Single() == "fake-test-key");
    using var body = JsonDocument.Parse(await request.Content!.ReadAsStringAsync(ct));
    Check(body.RootElement.GetProperty("sender").GetProperty("email").GetString() == config.SenderEmail);
    Check(body.RootElement.GetProperty("to")[0].GetProperty("email").GetString() == "test@example.invalid");
    Check(body.RootElement.GetProperty("htmlContent").GetString() == "<p>Prueba</p>");
    Check(body.RootElement.GetProperty("textContent").GetString() == "Prueba");
    Check(body.RootElement.GetProperty("subject").GetString() == "Asunto");
    return new HttpResponseMessage(HttpStatusCode.Created) { Content = new StringContent("{\"messageId\":\"test-id\"}") };
});
using var client = new HttpClient(handler);
var service = new BrevoEmailService(client, Options.Create(config), NullLogger<BrevoEmailService>.Instance);
Task<string?> Send(CancellationToken ct = default) => service.EnviarAsync("test@example.invalid", "Asunto", "<p>Prueba</p>", "Prueba", ct);
Check(await Send() == "test-id");
foreach (var status in new[] { 401, 403, 429, 500, 302 })
{
    handler.Callback = (_, _) => Task.FromResult(new HttpResponseMessage((HttpStatusCode)status));
    var before = handler.Calls;
    try { await Send(); throw new Exception("Se esperaba rechazo."); }
    catch (AppException e) { Check(e.StatusCode == 503); }
    Check(handler.Calls == before + 1); // Sin reintentos automáticos.
}
foreach (var error in new Exception[] { new HttpRequestException(), new TaskCanceledException() })
{
    handler.Callback = (_, _) => Task.FromException<HttpResponseMessage>(error);
    try { await Send(); throw new Exception("Se esperaba error."); }
    catch (AppException e) { Check(e.StatusCode == 503); }
}
using var cancel = new CancellationTokenSource();
cancel.Cancel();
try { await Send(cancel.Token); throw new Exception("Se esperaba cancelación."); }
catch (OperationCanceledException) { }
config.Enabled = false;
var calls = handler.Calls;
try { await Send(); throw new Exception("Se esperaba deshabilitado."); }
catch (AppException e) { Check(e.StatusCode == 503); }
Check(handler.Calls == calls);
Console.WriteLine("OK: configuración, payload, aceptación, rechazos, timeout, red, cancelación y deshabilitado. Sin envíos reales.");

sealed class FakeHandler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> callback) : HttpMessageHandler
{
    public Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> Callback = callback;
    public int Calls;
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
    { Calls++; return Callback(request, ct); }
}
