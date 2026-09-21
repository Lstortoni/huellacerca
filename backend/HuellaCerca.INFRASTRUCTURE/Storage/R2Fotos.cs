using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using HuellaCerca.INTERFACES;
using HuellaCerca.INTERFACES.Services;
using Microsoft.Extensions.Options;
using System.Net;

namespace HuellaCerca.INFRASTRUCTURE.Storage;

public sealed class R2Settings
{
    public bool Enabled { get; set; }
    public string Endpoint { get; set; } = "";
    public string Bucket { get; set; } = "";
    public string AccessKeyId { get; set; } = "";
    public string SecretAccessKey { get; set; } = "";
}

public sealed class R2Fotos : IAlmacenamientoFotos, IDisposable
{
    private readonly R2Settings settings;
    private readonly AmazonS3Client? client;
    public bool Habilitado => settings.Enabled;
    public R2Fotos(IOptions<R2Settings> options)
    {
        settings = options.Value;
        if (settings.Enabled)
            client = new AmazonS3Client(new BasicAWSCredentials(settings.AccessKeyId, settings.SecretAccessKey), new AmazonS3Config {
                ServiceURL = settings.Endpoint, AuthenticationRegion = "auto", ForcePathStyle = true,
                Timeout = TimeSpan.FromSeconds(30), MaxErrorRetry = 1,
                RequestChecksumCalculation = RequestChecksumCalculation.WHEN_REQUIRED,
                ResponseChecksumValidation = ResponseChecksumValidation.WHEN_REQUIRED
            });
    }
    private AmazonS3Client Client => client ?? throw new AppException(503, "El almacenamiento de fotos todavía no está configurado.");
    public async Task SubirAsync(string key, byte[] contenido, CancellationToken ct)
    {
        using var stream = new MemoryStream(contenido, false);
        try
        {
            await Client.PutObjectAsync(new PutObjectRequest { BucketName = settings.Bucket, Key = key,
                InputStream = stream, ContentType = "image/webp", DisablePayloadSigning = true,
                DisableDefaultChecksumValidation = true }, ct);
        }
        catch (AmazonS3Exception) { throw new AppException(503, "No pudimos guardar la foto. Volvé a intentar."); }
    }
    public async Task<byte[]> LeerAsync(string key, CancellationToken ct)
    {
        try
        {
            using var response = await Client.GetObjectAsync(settings.Bucket, key, ct);
            using var output = new MemoryStream();
            await response.ResponseStream.CopyToAsync(output, ct);
            return output.ToArray();
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == HttpStatusCode.NotFound) { throw new AppException(404, "Foto no encontrada."); }
        catch (AmazonS3Exception) { throw new AppException(503, "No pudimos cargar la foto."); }
    }
    public async Task EliminarAsync(string key, CancellationToken ct) =>
        await Client.DeleteObjectAsync(settings.Bucket, key, ct);
    public void Dispose() => client?.Dispose();
}
