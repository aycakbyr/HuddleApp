using System.ComponentModel.DataAnnotations;
using System.Security.Claims;
using BCrypt.Net;
using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using EtkinlikApp.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Npgsql;
using Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure.Internal;
using EtkinlikApp.Infrastructure.Migrations;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase // apı controllerlarının miras aldığı temel sınıf
{
    private readonly AppDbContext _context;
    private readonly TokenService _tokenService;

    public AuthController(AppDbContext context, TokenService tokenService)
    {
        _context = context;
        _tokenService = tokenService;
    }


[HttpPost("register")]
public async Task<IActionResult> Register(RegisterDto dto)
{
    // email zaten kayıtlı mı diye
    var exists = await _context.Users.AnyAsync(u => u.Email == dto.Email);
    if (exists)
        return BadRequest(new { message = "Bu email adresi zaten kayıtlı." }); // 404 hatası döner

    // yaş kontrolü 
    var age = DateTime.UtcNow.Year - dto.BirthDate.Year;
    if (dto.BirthDate.Date > DateTime.UtcNow.AddYears(-age)) age--;
    if (age < 18)
        return BadRequest(new { message = "18 yaşından küçükler kayıt olamaz." });

    // şifreyi hashler geri döndürülemez bir şekilde 
    var passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);

    // kullanıcıyı oluştur
    var user = new User
    {
        Email = dto.Email,
        PasswordHash = passwordHash,
        DisplayName = dto.DisplayName,
        Username = await GenerateUniqueUsernameAsync(dto.DisplayName),
        Gender = dto.Gender,
        BirthDate = DateTime.SpecifyKind(dto.BirthDate, DateTimeKind.Utc)
    };

    _context.Users.Add(user);

    try
    {
        await _context.SaveChangesAsync(); // kullanıcıyı veritabanına ekler
    }
    catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505" }) // 23505 = unique_violation
    {
        // İki kayıt isteği aynı anda gelmiş olabilir (aynı email ya da üretilen aynı username); yukarıdaki ön kontrol bunu yakalayamamış olabilir.
        return BadRequest(new { message = "Bu bilgilerle kayıt oluşturulamadı, lütfen tekrar deneyin." });
    }

    return Ok(new //http200 başarılı 
    {
        token = _tokenService.CreateToken(user),
        id = user.Id,
        email = user.Email,
        displayName = user.DisplayName
    });
}

[HttpPost("login")]
public async Task<IActionResult> Login(LoginDto dto)
    {
        //kullanıcıyı bul
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email);
        if (user == null)
            return Unauthorized(new { message = "Email veya şifre hatalı. "}); // http401 

        //şifre doğrulama
        var isValid = BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash);
        if (!isValid)
            return Unauthorized(new { message = "Email veya şifre hatalıdır."});

        await EnsureUsernameAsync(user); //eski hesaplarda username yoksa şimdi oluştur 

        return Ok(new
        {
            token = _tokenService.CreateToken(user),
            id = user.Id,
            email = user.Email,
            displayName = user.DisplayName,
            username = user.Username,
            gender = user.Gender.ToString()
        });   
    }

    // api/auth/me   giriş yapmış kullanıcının profil bilgilerini döner
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _context.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { message = "Kullanıcı bulunamadı." });
        
        await EnsureUsernameAsync(user);

        var followerCount = await _context.Follows.CountAsync(f => f.FollowingId == userId );
        var followingCount = await _context.Follows.CountAsync(f => f.FollowerId == userId);


        return Ok(new
        {
            id = user.Id,
            email = user.Email,
            displayName = user.DisplayName,
            username = user.Username,
            gender = user.Gender.ToString(),
            birthDate = user.BirthDate,
            createdAt = user.CreatedAt,
            profilePictureUrl = user.ProfilePictureUrl,
            followerCount,
            followingCount
        });
    }

    // Ayça -> ayca gibi Türkçe karakterleri sadeleştirir
    private static string GenerateBaseUsername(string displayName)
    {
        var map = new Dictionary<char, char>
        {
            {'ç','c'}, {'Ç','c'}, {'ğ','g'}, {'Ğ','g'}, {'ı','i'}, {'I','i'},
            {'İ','i'}, {'ö','o'}, {'Ö','o'}, {'ş','s'}, {'Ş','s'}, {'ü','u'}, {'Ü','u'}
        };

        var chars = new List<char>();
        foreach (var ch in displayName.ToLowerInvariant())
        {
            if (map.TryGetValue(ch, out var replaced))
                chars.Add(replaced);
            else if (char.IsLetterOrDigit(ch))
                chars.Add(ch);
            // boşluk, noktalama vs. atlanır
        }

        var result = new string(chars.ToArray());
        if (result.Length > 20) result = result.Substring(0, 20);
        if (string.IsNullOrEmpty(result)) result = "kullanici";

        return result;
    }

    // taban isim doluysa sonuna 1, 2, 3... ekleyerek benzersiz hale getirir
    private async Task<string> GenerateUniqueUsernameAsync(string displayName)
    {
        var baseName = GenerateBaseUsername(displayName);
        var candidate = baseName;
        var counter = 1;

        while (await _context.Users.AnyAsync(u => u.Username == candidate))
        {
            candidate = $"{baseName}{counter}";
            counter++;
        }

        return candidate;
    }

    // kullanıcının hiç username'i yoksa (eski hesaplar) otomatik oluşturup kaydeder
    private async Task EnsureUsernameAsync(User user)
    {
        if (!string.IsNullOrEmpty(user.Username)) return;

        user.Username = await GenerateUniqueUsernameAsync(user.DisplayName);
        await _context.SaveChangesAsync();
    }

    // api/auth/username   kullanıcı adını kendi seçtiğiyle değiştirir
    [Authorize]
    [HttpPut("username")]
    public async Task<IActionResult> UpdateUsername(UpdateUsernameDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var username = dto.Username.Trim().ToLowerInvariant();

        if (!System.Text.RegularExpressions.Regex.IsMatch(username, "^[a-z0-9_]{3,20}$"))
            return BadRequest(new { message = "Kullanıcı adı 3-20 karakter olmalı, sadece küçük harf, rakam ve alt çizgi (_) içerebilir." });

        var taken = await _context.Users.AnyAsync(u => u.Username == username && u.Id != userId);
        if (taken)
            return BadRequest(new { message = "Bu kullanıcı adı zaten alınmış." });

        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        user.Username = username;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Kullanıcı adı güncellendi.", username = user.Username });
    }
}