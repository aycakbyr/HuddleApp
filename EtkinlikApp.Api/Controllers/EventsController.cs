using System.ComponentModel;
using System.Net.Mail;
using System.Net.Sockets;
using System.Security.Claims;
using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Core.Enums;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Query.SqlExpressions;
using Microsoft.Extensions.Configuration.UserSecrets;
using Microsoft.IdentityModel.Tokens;
using Npgsql;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EventsController : ControllerBase
{
    private readonly AppDbContext _context;
    public EventsController(AppDbContext context)
    {
        _context = context;
    }

    //api/events
    [HttpGet]
    public async Task<IActionResult> GetEvents()
    {
        var events = await _context.Events
            .Include(e => e.Category)
            .Include(e => e.Creator)
            .Include(e => e.Participants)
            .Where(e => e.StartTime > DateTime
            .UtcNow) // sadece gelecekteki etkinlikleri gösterme
            .OrderBy(e => e.StartTime)
            .Select(e => new EventListDto
            {
                Id = e.Id,
                Title = e.Title,
                CategoryName = e.Category.Name,
                Address = e.Address,
                Latitude = e.Latitude,
                Longitude = e.Longitude,
                TargetGender = e.TargetGender.ToString(),
                StartTime = e.StartTime,
                ParticipantCount = e.Participants.Count(p => p.Status == ParticipantStatus.Approved), //sadece onaylanmış katılımcıları sayar
                OrganizerName = e.Creator.DisplayName,
                ImageUrl = e.ImageUrl,
                OrganizerAverageRating = e.Creator.RatingsReceived.Any()
                    ? Math.Round(e.Creator.RatingsReceived.Average(r => (double)r.Score), 1)
                    : (double?)null
            })
            .ToListAsync();
        return Ok(events);
    }
    [Authorize] // token geçerliyse erişilir yoksa 401 döner
    [HttpPost]
    public async Task<IActionResult> CreateEvent(CreateEventDto dto)
    {
        //tokenden kullanıcı ıd si almak için
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier) ?.Value;
        if (userIdClaim == null)
           return Unauthorized();

        var userId = Guid.Parse(userIdClaim);

        //kategori var mı diye kontrol
        var categoryExists = await _context.Categories.AnyAsync(c => c.Id == dto.CategoryId);
        if (!categoryExists)
           return BadRequest(new { message = "Geçersiz kategori."});

        //geçmiş kontrolü
        if (dto.StartTime <= DateTime.UtcNow)
           return BadRequest(new { message = "Etkinlik tarihi gelecekte olmalı."});
        
        // etkinlik oluştur
        var newEvent = new Event
        {
            CreatorId = userId,
            CategoryId = dto.CategoryId,
            Title = dto.Title,
            Description = dto.Description,
            Address = dto.Address,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            TargetGender = dto.TargetGender,
            StartTime = DateTime.SpecifyKind(dto.StartTime, DateTimeKind.Utc)
        };

        _context.Events.Add(newEvent);

        //oluşturan kişiyi otomstik katılımcı yapma
        _context.EventParticipants.Add(new EventParticipant
        {
            EventId = newEvent.Id,
            UserId = userId,
            Status = ParticipantStatus.Approved,
            RespondedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync();

        return Ok(new { id = newEvent.Id, message = "Etkinlik oluşturuldu."});

    }

    // api/events/{id} sadece etkinliği oluşturan kişi düzenleyebilir
    [Authorize]
    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateEvent(Guid id, CreateEventDto dto)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null)
            return Unauthorized();

        var userId = Guid.Parse(userIdClaim);

        var existingEvent = await _context.Events.FindAsync(id);
        if (existingEvent == null)
            return NotFound(new { message = "Etkinlik bulunamadı."});

        if (existingEvent.CreatorId != userId)
           return Forbid();
        
        var categoryExists = await _context.Categories.AnyAsync(c => c.Id == dto.CategoryId);
        if (!categoryExists)
           return BadRequest(new { message = "Geçersiz kategori."});
        
        if (dto.StartTime <= DateTime.UtcNow)
           return BadRequest(new { message = "Etkinlik tarihi gelecekte olmalı."});
        
        existingEvent.CategoryId = dto.CategoryId;
        existingEvent.Title = dto.Title;
        existingEvent.Description = dto.Description;
        existingEvent.Address = dto.Address;
        existingEvent.Latitude = dto.Latitude;
        existingEvent.Longitude = dto.Longitude;
        existingEvent.TargetGender = dto.TargetGender;
        existingEvent.StartTime = DateTime.SpecifyKind(dto.StartTime, DateTimeKind.Utc);

        await _context.SaveChangesAsync();

        return Ok(new { message = "Etkinlik güncellendi."});
    }
        // api/events/{id}
    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetEventById(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var ev = await _context.Events
            .Include(e => e.Category)
            .Include(e => e.Creator)
            .Include(e => e.Participants)
                .ThenInclude(p => p.User)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (ev == null)
           return NotFound(new { message = "Etkinlik bulunamadı."} );

        var myParticipation = ev.Participants.FirstOrDefault(p => p.UserId == userId);
        var isApprovedParticipant = myParticipation?.Status == ParticipantStatus.Approved;
        var eventEnded = ev.StartTime <= DateTime.UtcNow;
        var isOrganizer = ev.CreatorId == userId;

        var myRating = await _context.Ratings
            .FirstOrDefaultAsync(r => r.EventId == id && r.RaterId == userId);

        var organizerRatingCount = await _context.Ratings.CountAsync(r=> r.RatedUserId == ev.CreatorId);
        var organizerAverageRating = organizerRatingCount == 0
            ? (double?)null
            : Math.Round(await _context.Ratings.Where(r => r.RatedUserId == ev.CreatorId).AverageAsync(r => r.Score), 1);

        // bu etkinliğe yapılmış değerlendirmeler (yorumlar) - herkes görebilir, katılım/tarih şartına bakmaz
        var eventRatings = await _context.Ratings
            .Include(r => r.Rater)
            .Where(r => r.EventId == id)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new RatingDto
            {
                Id = r.Id,
                RaterId = r.RaterId,
                RaterDisplayName = r.Rater.DisplayName,
                Score = r.Score,
                CommunicationScore = r.CommunicationScore,
                OrganizationScore = r.OrganizationScore,
                WarmthScore = r.WarmthScore,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt
            })
            .ToListAsync();

        
        var dto = new EventDetailDto
        {
            Id = ev.Id,
            Title = ev.Title,
            Description = ev.Description,
            CategoryName = ev.Category.Name,
            CategoryId = ev.CategoryId,
            Address = ev.Address,
            Latitude = ev.Latitude,
            Longitude = ev.Longitude,
            TargetGender = ev.TargetGender.ToString(),
            StartTime = ev.StartTime,
            OrganizerId= ev.CreatorId,
            OrganizerName = ev.Creator.DisplayName,
            ImageUrl = ev.ImageUrl,
            CurrentUserStatus = myParticipation?.Status.ToString(),
            Participants = ev.Participants
                 .Where(p => p.Status == ParticipantStatus.Approved)
                 .Select(p => new ParticipantDto
                 {
                    UserId =p.UserId,
                    DisplayName = p.User.DisplayName,
                    Status = p.Status.ToString() 
                 })
                 .ToList(),
                 CanAddMemoryPhoto = isApprovedParticipant && eventEnded,
                 CanRateOrganizer = isApprovedParticipant && eventEnded && !isOrganizer,
                 MyRatingScore = myRating?.Score,
                 MyRatingComment = myRating?.Comment,
                 MyRatingCommunicationScore = myRating?.CommunicationScore,
                 MyRatingOrganizationScore = myRating?.OrganizationScore,
                 MyRatingWarmthScore = myRating?.WarmthScore,
                 OrganizerAverageRating = organizerAverageRating,
                 OrganizerRatingCount = organizerRatingCount,
                 EventRatings = eventRatings
        };
        return Ok(dto);
    }

        // api/events/{id}/rating   etkinlik kurucusunu değerlendir (ekle ya da güncelle)
    [Authorize]
    [HttpPost("{id}/rating")]
    public async Task<IActionResult> RateEvent(Guid id, RateEventDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        if (dto.Score < 1 || dto.Score > 5)
            return BadRequest(new { message = "Puan 1 ile 5 arasında olmalı." });
        if (dto.CommunicationScore is null || dto.CommunicationScore < 1 || dto.CommunicationScore > 5) 
            return BadRequest(new { message = "İletişim puanı 1 ile 5 arasında olmalı."});
        if (dto.OrganizationScore is null || dto.OrganizationScore < 1 || dto.OrganizationScore > 5)
            return BadRequest(new { message = "Organizasyon puanı 1 ile 5 arasında olmalı."});
        if (dto.WarmthScore is null || dto.WarmthScore < 1 || dto.WarmthScore > 5)
            return BadRequest(new { message = "Samimiyet puanı 1 ile 5 arasında olmalı."}); 

        var ev = await _context.Events.FirstOrDefaultAsync(e => e.Id == id);
        if (ev == null)
            return NotFound(new { message = "Etkinlik bulunamadı." });

        if (ev.CreatorId == userId)
            return BadRequest(new { message = "Kendi etkinliğini değerlendiremezsin." });

        if (ev.StartTime > DateTime.UtcNow)
            return BadRequest(new { message = "Etkinlik henüz gerçekleşmedi." });

        var isApproved = await _context.EventParticipants
            .AnyAsync(p => p.EventId == id && p.UserId == userId && p.Status == ParticipantStatus.Approved);
        if (!isApproved)
            return BadRequest(new { message = "Bu etkinliğe katılmadığın için değerlendiremezsin." });

        var existingRating = await _context.Ratings
            .FirstOrDefaultAsync(r => r.EventId == id && r.RaterId == userId);

        if (existingRating != null)
        {
            existingRating.Score = dto.Score;
            existingRating.CommunicationScore = dto.CommunicationScore;
            existingRating.OrganizationScore = dto.OrganizationScore;
            existingRating.WarmthScore = dto.WarmthScore;
            existingRating.Comment = dto.Comment;
        }
        else
        {
            _context.Ratings.Add(new Rating
            {
                EventId = id,
                RaterId = userId,
                RatedUserId = ev.CreatorId,
                Score = dto.Score,
                CommunicationScore = dto.CommunicationScore,
                OrganizationScore = dto.OrganizationScore,
                WarmthScore = dto.WarmthScore,
                Comment = dto.Comment
            });
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505" })
        {
            return BadRequest(new { message = "Bu etkinliği zaten değerlendirdin." });
        }

        return Ok(new { message = "Değerlendirme kaydedildi." });
    }

    // events/{id}/join
    [Authorize]
    [HttpPost("{id}/join")]
    public async Task<IActionResult> JoinEvent(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        //etkinlik var mı
        var ev = await _context.Events.FirstOrDefaultAsync(e => e.Id == id);
        if (ev == null)
           return NotFound(new {message = "Etkinlik bulunamadı."});

        // kendi etkinliğine katılamaz
        if (ev.CreatorId == userId)
           return BadRequest(new { message = "Kendi etkinliğinize katılamazsınız. "});

        // geçmiş etkinliğe katılamaz
        if (ev.StartTime <= DateTime.UtcNow)
           return BadRequest(new {message = "Bu etkinlik geçmiştir."});

        // daha öncfe istek göndermiş mi
        var existing = await _context.EventParticipants
            .FirstOrDefaultAsync(p => p.EventId == id && p.UserId == userId);
        
        if (existing != null)
           return BadRequest(new {message = "Bu etkinliğe zaten istek gönderdiniz."});
        
        //istek oluştur
        _context.EventParticipants.Add(new EventParticipant
        {
            EventId = id,
            UserId = userId,
            Status = ParticipantStatus.Pending
        });

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505" }) // 23505 = unique_violation
        {
            // İki istek aynı anda gelmiş olabilir; yukarıdaki ön kontrol bunu yakalayamamış olabilir.
            return BadRequest(new { message = "Bu etkinliğe zaten istek gönderdiniz." });
        }

        return Ok(new { message = "Katılım isteği gönderildi."});
    }

    // events/{id}/join (iptal etme / etkinlikten ayrılma)
    [Authorize]
    [HttpDelete("{id}/join")]
    public async Task<IActionResult> CancelJoinRequest(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var participant = await _context.EventParticipants
            .FirstOrDefaultAsync(p => p.EventId == id && p.UserId == userId);

        if (participant == null)
           return NotFound(new { message = "Katılım kaydınız bulunamadı."});

        _context.EventParticipants.Remove(participant);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Katılım iptal edildi."});
    }

    //api/events/{id}/requests    bekleyen istekleri listeleme
    [Authorize]
    [HttpGet("{id}/requests")]
    public async Task<IActionResult> GetPendingRequests(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var ev = await _context.Events.FirstOrDefaultAsync(e => e.Id == id);
        if (ev == null)
           return NotFound(new {message = "Etkinlik bulunamadı."});

        // sadece etkinlik sahibi görebilir
        if (ev.CreatorId != userId)
           return Forbid();

        var requests = await _context.EventParticipants
            .Include(p => p.User)
            .Where(p => p.EventId == id && p.Status == ParticipantStatus.Pending)
            .Select(p => new PendingRequestDto
            {
                ParticipantId = p.Id,
                UserId = p.UserId,
                DisplayName = p.User.DisplayName,
                RequestedAt = p.RequestedAt
            })
            .ToListAsync();
        
        return Ok(requests);
    }

    //api/events/{id}/photos  etkinliğe eklenen anı fotoları
    [Authorize]
    [HttpGet("{id}/photos")]
    public async Task<IActionResult> GetEventPhotos( Guid id)
    {
        var photos = await _context.EventPhotos
            .Include(p => p.Event)
            .Where(p => p.EventId == id)
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new EventPhotoDto
            {
                Id = p.Id,
                EventId = p.EventId,
                EventTitle = p.Event.Title,
                ImageUrl = p.ImageUrl,
                CreatedAt = p.CreatedAt
            })
            .ToListAsync();
        
        return Ok(photos);
    }

    // api/events/requests/{participantId}/respond?approve=true
    [Authorize]
    [HttpPut("requests/{participantId}/respond")]
    public async Task<IActionResult> RespondToRequest(Guid participantId, [FromQuery] bool approve)
    {
    
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var participant = await _context.EventParticipants
            .Include(p => p.Event)
            .FirstOrDefaultAsync(p => p.Id == participantId);

        if (participant == null)
           return NotFound(new { message = "İstek bulunamadı." });

        // Sadece etkinlik sahibi yanıtlayabilir
        if (participant.Event.CreatorId != userId)
           return Forbid();

        if (participant.Status != ParticipantStatus.Pending)
           return BadRequest(new { message = "Bu istek zaten yanıtlanmış." });

        participant.Status = approve ? ParticipantStatus.Approved : ParticipantStatus.Rejected;
        participant.RespondedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { message = approve ? "İstek onaylandı." : "İstek reddedildi." });
    }

    // api/events/my   "Etkinliklerim" - kullanıcının oluşturduğu etkinlikler (geçmiş + gelecek)
    [Authorize]
    [HttpGet("my")]
    public async Task<IActionResult> GetMyEvents()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var events = await _context.Events
            .Include(e => e.Category)
            .Include(e => e.Participants)
            .Where(e => e.CreatorId == userId)
            .OrderByDescending(e => e.StartTime)
            .Select(e => new MyEventListDto
            {
                Id = e.Id,
                Title = e.Title,
                CategoryName = e.Category.Name,
                StartTime = e.StartTime,
                ParticipantCount = e.Participants.Count(p => p.Status == ParticipantStatus.Approved),
                PendingRequestCount = e.Participants.Count(p => p.Status == ParticipantStatus.Pending),
                ImageUrl = e.ImageUrl
            })
            .ToListAsync();

        return Ok(events);
    }

    // api/events/joined katıldığım etkinlikler kısmı
    [Authorize]
    [HttpGet("joined")]
    public async Task<IActionResult> GetJoinedEvents()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var events = await _context.Events
            .Include(e => e.Category)
            .Include(e => e.Participants)
            .Where(e => e.CreatorId != userId && e.Participants.Any(p => p.UserId == userId && p.Status == ParticipantStatus.Approved))
            .OrderByDescending(e => e.StartTime)
            .Select(e => new UserEventListDto
            {
               Id = e.Id,
               Title = e.Title,
               CategoryName = e.Category.Name,
               StartTime = e.StartTime,
               ParticipantCount = e.Participants.Count(p => p.Status == ParticipantStatus.Approved),
               ImageUrl = e.ImageUrl                                     
            })
            .ToListAsync();
        
        return Ok(events);
    }

    // api/events/requests   Bildirimler - kullanıcının sahip olduğu TÜM etkinlikler için bekleyen istekler
    [Authorize]
    [HttpGet("requests")]
    public async Task<IActionResult> GetMyPendingRequests()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var requests = await _context.EventParticipants
            .Include(p => p.User)
            .Include(p => p.Event)
            .Where(p => p.Event.CreatorId == userId && p.Status == ParticipantStatus.Pending)
            .OrderByDescending(p => p.RequestedAt)
            .Select(p => new PendingRequestWithEventDto
            {
                ParticipantId = p.Id,
                EventId = p.EventId,
                EventTitle = p.Event.Title,
                UserId = p.UserId,
                DisplayName = p.User.DisplayName,
                RequestedAt = p.RequestedAt
            })
            .ToListAsync();

        return Ok(requests);
    }
}