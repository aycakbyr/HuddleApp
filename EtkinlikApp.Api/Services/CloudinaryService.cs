using System.Diagnostics.CodeAnalysis;
using CloudinaryDotNet;
using CloudinaryDotNet.Actions;

namespace EtkinlikApp.Api.Services;

public class CloudinaryService
{
    private readonly Cloudinary _cloudinary;

    public CloudinaryService(IConfiguration config)
    {
        var account = new Account(
            config["Cloudinary:CloudName"],
            config["Cloudinary:ApiKey"],
            config["Cloudinary:ApiSecret"]
        );

        _cloudinary = new Cloudinary(account);
    }

    public async Task<string?> UploadImageAsync(IFormFile file) // asp.net corun dosya yükleme tipi.flutterdan gelen foto buraya düşüyor 
    {
        if (file.Length == 0) return null;

        await using var stream = file.OpenReadStream(); // dosyayı okumaya başlar 

        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(file.FileName, stream),
            Folder = "huddle/events",
            Transformation = new Transformation()
                .Width(1200)
                .Height(800)
                .Crop("limit")
                .Quality("auto")
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if ( result.StatusCode != System.Net.HttpStatusCode.OK)
           return null;

        return result.SecureUrl.ToString();
    }
}