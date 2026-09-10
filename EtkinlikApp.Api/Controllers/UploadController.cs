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

   //post api/upload/community/{communityId}/photo üyenin topluluğa foto eklemesi
   [HttpPost("community/{communityId}/photo")]
   public async Task<IActionResult> UploadCommunityPhoto(Guid communityId, IFormFile file)
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

      var community = await _context.Communities.FirstOrDefaultAsync(c => c.Id == communityId);
      if (community == null)
         return NotFound(new { message = "Topluluk bulunamadı."});

      var isMember = await _context.CommunityMembers
          .AnyAsync(m => m.CommunityId == communityId && m.UserId == userId);
      if (!isMember)
         return Forbid();

      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya Seçilemedi"});

      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});
      
      var photo = new CommunityPhoto
      {
         CommunityId = communityId,
         UserId = userId,
         ImageUrl = imageUrl
      };
      _context.CommunityPhotos.Add(photo);
      await _context.SaveChangesAsync();

      return Ok(new { id = photo.Id, imageUrl});

   }

   //post api/upload/direct-messages/{otherUserId}/photo iki kullanıcı arasındaki dm sohbetine foto ekleme (CommunityPhoto tablosu dm için de kullanılıyor, DRY)
   [HttpPost("direct-messages/{otherUserId}/photo")]
   public async Task<IActionResult> UploadDirectPhoto(Guid otherUserId, IFormFile file)
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

      var receiverExists = await _context.Users.AnyAsync(u => u.Id == otherUserId);
      if (!receiverExists)
         return NotFound(new { message = "Kullanıcı bulunamadı."});

      // dm izin modeli mesajlaşmadakiyle aynı: hiç takip ilişkisi yoksa ve önceden hiç mesajlaşılmamışsa foto da gönderilemez
      var followsExists = await _context.Follows.AnyAsync(f =>
          (f.FollowerId == userId && f.FollowingId == otherUserId) ||
          (f.FollowerId == otherUserId && f.FollowingId == userId));
      if (!followsExists)
      {
         var alreadyConversed = await _context.Messages.AnyAsync(m =>
             m.ReceiverId != null &&
             ((m.SenderId == userId && m.ReceiverId == otherUserId) ||
              (m.SenderId == otherUserId && m.ReceiverId == userId)));
         if (!alreadyConversed)
            return StatusCode(403, new { message = "Bu kullanıcıyla fotoğraf paylaşabilmen için birbirinizi takip etmeniz gerekiyor."});
      }

      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya seçilemedi."});

      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});

      var photo = new CommunityPhoto
      {
         UserId = userId,
         ReceiverId = otherUserId,
         ImageUrl = imageUrl
      };
      _context.CommunityPhotos.Add(photo);
      await _context.SaveChangesAsync();

      return Ok(new { id = photo.Id, imageUrl});
   }

   //post api/upload/community/{communityId}/picture yöneticinin topluluk pp değiştirmesi
   [HttpPost("community/{communityId}/picture")]
   public async Task<IActionResult> UploadCommunityPicture(Guid communityId, IFormFile file)
   {
      var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

      var community = await _context.Communities.FirstOrDefaultAsync(c => c.Id == communityId);
      if (community == null)
         return NotFound(new { message = "Topluluk bulunamadı."});
      
      var isAdmin = await _context.CommunityMembers
         .AnyAsync(m => m.CommunityId == communityId && m.UserId == userId && m.Role == CommunityRole.Admin);
      if (!isAdmin)
         return Forbid();
      
      if (file == null || file.Length == 0)
         return BadRequest(new { message = "Dosya seçilemedi."});
      
      var allowedTypes = new[] {"image/jpeg", "image/png", "image/webp"};
      if (!allowedTypes.Contains(file.ContentType))
         return BadRequest(new { message = "Sadece JPEG, PNG veya WebP yükleyebilirsiniz."});

      var imageUrl = await _cloudinary.UploadImageAsync(file);
      if (imageUrl == null)
         return StatusCode(500, new { message = "Fotoğraf yüklenemedi."});
      
      community.ProfilePictureUrl = imageUrl;
      await _context.SaveChangesAsync();

      return Ok(new { imageUrl });
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