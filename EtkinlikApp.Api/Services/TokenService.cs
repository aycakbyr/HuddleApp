using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using EtkinlikApp.Core.Entities;
using Microsoft.IdentityModel.Tokens;

namespace EtkinlikApp.Api.Services;

public class TokenService
{
    private readonly IConfiguration _config; // json daki ayarlara erişir

    public TokenService(IConfiguration config)
    {
        _config = config;
    }
    
    public string CreateToken(User user)
    {
        // token için bilgiler claims
        var claims = new List<Claim> //tokenin payload kısmına konacak bilgiler
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.DisplayName)
        };

        // gizli anahtarı okuma ve imzalama bilgileri hazırlaması
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Key"]!)
        );
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        //token oluştur
        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddDays(int.Parse(_config["Jwt:ExpiryDays"]!)),
            signingCredentials: creds
        );

        //metin hale getirme
        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}