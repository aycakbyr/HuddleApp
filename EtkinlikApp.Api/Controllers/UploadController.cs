using EtkinlikApp.Api.Services;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Core.Enums;
using System.Drawing;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class UploadController : ControllerBase
{
    private readonly CloudinaryService _cloudinary;
    private readonly AppDbContext _context;

    public UploadController(CloudinaryService cloudinary, AppDbContext context)
    {
        _cloudinary = cloudinary;
        _context = context;
    }

    //post api/upload/event/{eventıd}
    [HttpPost("event/{eventId}")]
    public async Task<IActionResult> UploadEventImage(Guid eventId, IFormFile file)
    {
        //etkinlik var mı diye
        var ev = await _context.Events.FirstOrDefaultAsync(e => e.Id == eventId);
        if ( ev == null)
           return NotFound(new { message = "Etkinlik bulunamadı."});

        //dosya var mı
        if (file == null || file.Length == 0)
           return BadRequest(new { message = "Dosya seçilmedi."});

        //sadece resim dosyası kabul et
        var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
        if (!allowedTypes.Contains(file.ContentType))
           return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

        //cloudinary yükleme
        var imageUrl = await _cloudinary.UploadImageAsync(file);
        if (imageUrl == null)
           return StatusCode(500, new { message = "Fotoğraf yüklenemedi. "});

        //url veritabanına kaydetme
        ev.ImageUrl = imageUrl;
        await _context.SaveChangesAsync();

        return Ok(new { imageUrl });
    }

   // post api/upload/event/{eventId}/photo  katılımcının foto eklemesi
   [HttpPost("event/{eventId}/photo")]
   public async Task<IActionResult> UploadEventMemoryPhoto(Guid eventId, IFormFile file )
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
      
      var ev = await _context.Events.FirstOrDefaultAsync(e => e.Id == eventId);
      if (ev == null)
        return NotFound(new { message = "Etkinlik bulunamadı."});

      if (ev.StartTime > DateTime.UtcNow)
         return BadRequest(new { message = "Etkinlik henüz gerçekleşmedi."});

      var isApproved = await _context.EventParticipants
         .AnyAsync(p => p.EventId == eventId && p.UserId == userId && p.Status == ParticipantStatus.Approved);
      if (!isApproved)
         return BadRequest(new { message = "Bu etkinliğe katılmadığın için fotoğraf ekleyemezsin."});
      
      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya seçilemedi."});
      
      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});
      
      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});
      
      var photo = new EventPhoto
      {
         EventId = eventId,
         UserId = userId,
         ImageUrl = imageUrl
      };
      _context.EventPhotos.Add(photo);
      await _context.SaveChangesAsync();

      return Ok(new { id = photo.Id, imageUrl});
   }

   // post api/upload/profile/photo   kullanıcının doğrudan kendi profiline (bir etkinliğe bağlı olmadan) foto eklemesi
   [HttpPost("profile/photo")]
   public async Task<IActionResult> UploadProfilePhoto(IFormFile file)
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya seçilemedi."});

      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});

      var photo = new ProfilePhoto
      {
         UserId = userId,
         ImageUrl = imageUrl
      };
      _context.ProfilePhotos.Add(photo);
      await _context.SaveChangesAsync();

      return Ok(new { id = photo.Id, imageUrl});
   }

   // post api/upload/profile/picture   profil fotosu 
   [HttpPost("profile/picture")]
   public async Task<IActionResult> UploadProfilePicture(IFormFile file)
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

      var user = await _context.Users.FindAsync(userId);
      if (user == null)
         return NotFound(new { message = "Kullanıcı bulunamadı."});

      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya seçilemedi."});

      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});
      
      user.ProfilePictureUrl = imageUrl;
      await _context.SaveChangesAsync();

      return Ok(new { imageUrl });
   }
}