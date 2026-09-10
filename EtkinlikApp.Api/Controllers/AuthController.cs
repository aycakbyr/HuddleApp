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
    private readonly EmailService _emailService;

    public AuthController(AppDbContext context, TokenService tokenService, EmailService emailService)
    {
        _context = context;
        _tokenService = tokenService;
        _emailService = emailService;
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

    // api/auth/change-password   mevcut şifreyi doğrulayıp yenisiyle değiştirir
    [Authorize]
    [HttpPut("change-password")]
    public async Task<IActionResult> ChangePassword(ChangePasswordDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, user.PasswordHash))
            return BadRequest(new { message = "Mevcut şifren yanlış." });

        if (dto.NewPassword.Length < 6)
            return BadRequest(new { message = "Yeni şifre en az 6 karakter olmalı." });

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Şifren güncellendi." });
    }

    // api/auth (DELETE)   hesabı siler
    // not: Message/Event/Rating/CommunityPhoto gibi tablolarda User'a Restrict ile bağlıyız (geçmiş verinin bozulmaması için bilinçli tercih),
    // o yüzden satırı gerçekten silmek FK hatası verir. Bunun yerine hesabı anonimleştirip devre dışı bırakıyoruz:
    // eski mesajlar/etkinlikler/değerlendirmeler veritabanında kalır ama "Silinmiş Kullanıcı" olarak görünür, email boşa çıkar (tekrar kayıt olunabilir).
    [Authorize]
    [HttpDelete]
    public async Task<IActionResult> DeleteAccount(DeleteAccountDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return NotFound();

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.PasswordHash))
            return BadRequest(new { message = "Şifren yanlış." });

        user.IsDeleted = true;
        user.DisplayName = "Silinmiş Kullanıcı";
        user.Email = $"silinmis_{user.Id}@silinmis.etkinlikapp";
        user.Username = null;
        user.ProfilePictureUrl = null;
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString()); // eski şifreyle tekrar giriş yapılamasın diye rastgele bir hashe çeviriyoruz

        await _context.SaveChangesAsync();

        return Ok(new { message = "Hesabın silindi." });
    }

    // api/auth/forgot-password   maile 6 haneli sıfırlama kodu gönderir
    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordDto dto)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email && !u.IsDeleted);

        // kullanıcı var mı yok mu belli etmemek için (güvenlik) her zaman aynı mesajı dönüyoruz,
        // ama email gerçekten kayıtlıysa arka planda kod üretip gönderiyoruz
        if (user != null)
        {
            var code = Random.Shared.Next(100000, 999999).ToString();
            user.PasswordResetCode = code;
            user.PasswordResetCodeExpiresAt = DateTime.UtcNow.AddMinutes(15);
            await _context.SaveChangesAsync();

            try
            {
                await _emailService.SendPasswordResetCodeAsync(user.Email, code);
            }
            catch
            {
                // mail gönderilemedi (örn. SMTP ayarları henüz girilmemiş) - kullanıcıya sızdırmadan sessizce geçiyoruz,
                // backend loglarından fark edilir
                return StatusCode(500, new { message = "Mail gönderilirken bir sorun oluştu, lütfen daha sonra tekrar dene." });
            }
        }

        return Ok(new { message = "Bu email adresine kayıtlı bir hesap varsa, sıfırlama kodu gönderildi." });
    }

    // api/auth/reset-password   kodu doğrulayıp şifreyi yeniler
    [HttpPost("reset-password")]
    public async Task<IActionResult> ResetPassword(ResetPasswordDto dto)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == dto.Email && !u.IsDeleted);

        if (user == null || user.PasswordResetCode == null || user.PasswordResetCode != dto.Code
            || user.PasswordResetCodeExpiresAt == null || user.PasswordResetCodeExpiresAt < DateTime.UtcNow)
            return BadRequest(new { message = "Kod geçersiz veya süresi dolmuş." });

        if (dto.NewPassword.Length < 6)
            return BadRequest(new { message = "Yeni şifre en az 6 karakter olmalı." });

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        user.PasswordResetCode = null;
        user.PasswordResetCodeExpiresAt = null;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Şifren sıfırlandı, şimdi giriş yapabilirsin." });
    }
}