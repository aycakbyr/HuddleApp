using System.Security.Claims;
using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Core.Enums;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CommunitiesController : ControllerBase
{
    private readonly AppDbContext _context;
    public CommunitiesController(AppDbContext context)
    {
        _context = context;
    }

    // api/communities - yeni topluluk oluştur
    [Authorize]
    [HttpPost]
    public async Task<IActionResult> CreateCommunity(CreateCommunityDto dto)
    {
        // tokenden kullanıcı id'si almak için
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim == null)
            return Unauthorized();

        var userId = Guid.Parse(userIdClaim);

        if (string.IsNullOrWhiteSpace(dto.Name))
            return BadRequest(new { message = "Topluluk adı boş olamaz." });

        // topluluğu oluştur
        var community = new Community
        {
            CreatedByUserId = userId,
            Name = dto.Name,
            Description = dto.Description,
        };

        _context.Communities.Add(community);

        // oluşturan kişiyi otomatik olarak yönetici yapma
        _context.CommunityMembers.Add(new CommunityMember
        {
            CommunityId = community.Id,
            UserId = userId,
            Role = CommunityRole.Admin,
        });

        await _context.SaveChangesAsync();

        return Ok(new { id = community.Id, message = "Topluluk oluşturuldu." });
    }

    // api/communities tüm topluluk listesi
    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetCommunities()
    {
        var communities = await _context.Communities
            .Include(c => c.Members) // bu ilişkiyi de ef ile birlikte getir
            .OrderByDescending(c => c.CreatedAt)
            .Select(c => new CommunityListDto // sorgunun şeklini değiştir demek
            {
                Id = c.Id,
                Name = c.Name,
                ProfilePictureUrl = c.ProfilePictureUrl,
                MemberCount = c.Members.Count
            })
            .ToListAsync();
        
        return Ok(communities);
    }

    // api/communities/{id} topluluk detayları
    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetCommunityById(Guid id)
    {
        var community = await _context.Communities
            .Include(c => c.Members)
                .ThenInclude(cm => cm.User)
                .FirstOrDefaultAsync(c => c.Id == id);
        
        if (community == null)
            return NotFound(new { message = "Topluluk bulunamadı."});
        
        var eventCount = await _context.Events.CountAsync(e => e.CommunityId == id); // sadece sayı istediğimiz için 

        var dto = new CommunityDetailDto
        {
            Id = community.Id,
            Name = community.Name,
            Description = community.Description,
            ProfilePictureUrl = community.ProfilePictureUrl,
            CreatedByUserId = community.CreatedByUserId,
            MemberCount = community.Members.Count,
            EventCount = eventCount,
            Members = community.Members
                .OrderByDescending(m => m.Role)
                .Select(m => new CommunityMemberDto
                {
                    UserId = m.UserId,
                    DisplayName = m.User.DisplayName,
                    ProfilePictureUrl = m.User.ProfilePictureUrl,
                    Role = m.Role.ToString()
                })
                .ToList()
        };

        return Ok(dto);
    }

    //api/communities/{id}/join. katılım isteği gönderme
    [Authorize]
    [HttpPost("{id}/join")]
    public async Task<IActionResult> JoinCommunity(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var community = await _context.Communities.FirstOrDefaultAsync(c => c.Id == id);
        if (community == null)
            return NotFound(new { message = "topluluk bulunamadı."});
        
        //zaten üye mi diye
        var alreadyMember = await _context.CommunityMembers
            .AnyAsync(m => m.CommunityId == id && m.UserId == userId);
        if (alreadyMember)
           return BadRequest(new { message = "Bu topluluğa zaten üyesiniz."});
        
        // daha önce istek göndermiş mi 
        var existingRequest = await _context.CommunityJoinRequests
            .FirstOrDefaultAsync(r => r.CommunityId == id && r.UserId == userId);
        if (existingRequest != null)
            return BadRequest(new { message = "Bu topluluğa zaten katılım isteği gönderdiniz."});
        
        _context.CommunityJoinRequests.Add(new CommunityJoinRequest
        {
            CommunityId = id,
            UserId = userId,
        });

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505"})
        {
            return BadRequest(new { message = "Bu topluluğa zaten istek gönderdiniz."});
        }

        return Ok(new { message = "Katılım isteği gönderildi."});
    }

    //api/communities/{id}/join  isteği iptal etme
    [Authorize]
    [HttpDelete("{id}/join")]
    public async Task<IActionResult> CancelJoinRequest (Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var request = await _context.CommunityJoinRequests
            .FirstOrDefaultAsync(r => r.CommunityId == id && r.UserId == userId);
        if (request == null)
            return NotFound(new { message = "İstek bulunamadı."});

        _context.CommunityJoinRequests.Remove(request);
        await _context.SaveChangesAsync();

        return Ok(new { message = "İstek iptal edildi."});
    }

    // api/communities/{id}/leave topluluktan ayrıl
    [Authorize]
    [HttpDelete("{id}/leave")]
    public async Task<IActionResult> LeaveCommunity(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var membership = await _context.CommunityMembers
            .FirstOrDefaultAsync(m => m.CommunityId == id && m.UserId == userId);
        if (membership == null)
            return NotFound(new { message = "Bu topluluğun üyesi değilsiniz."});
        
        _context.CommunityMembers.Remove(membership);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Topluluktan ayrıldınız."});
    }

   // api/communities/{id}/requests. bekleyen istekleri listele
   [Authorize]
   [HttpGet("{id}/requests")]
   public async Task<IActionResult> GetPeddingJoinRequests(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var isAdmin = await _context.CommunityMembers
            .AnyAsync(m => m.CommunityId == id && m.UserId == userId && m.Role == CommunityRole.Admin);
        if (!isAdmin)
            return Forbid();
        
        var requests = await _context.CommunityJoinRequests
            .Include(r => r.User)
            .Where(r => r.CommunityId == id && r.Status == ParticipantStatus.Pending)
            .Select(r => new CommunityJoinRequestDto
            {
                RequestId = r.Id,
                UserId = r.UserId,
                DisplayName = r.User.DisplayName,
                RequestedAt = r.RequestedAt
            })
            .ToListAsync();
        
        return Ok(requests);
    }

    //api/communities/{id}/requests/{requestId}/respond?approve=true.
    //katılım isteğini onayla veya reddet
    [Authorize]
    [HttpPut("{id}/requests/{requestId}/respond")]
    public async Task<IActionResult> RespondToJoinRequest(Guid requestId, [FromQuery]  bool approve)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var request = await _context.CommunityJoinRequests
            .FirstOrDefaultAsync(r => r.Id == requestId);
        if (request == null)
            return NotFound(new { message = "İstek bulunamadı."});
        
        var isAdmin = await _context.CommunityMembers
            .AnyAsync(m => m.CommunityId == request.CommunityId && m.UserId == userId && m.Role == CommunityRole.Admin);
        if (!isAdmin)
            return Forbid();
        
        if (request.Status != ParticipantStatus.Pending)
            return BadRequest(new { message = "Bu istek zaten yanıtlanmış."});
        
        request.Status = approve ? ParticipantStatus.Approved : ParticipantStatus.Rejected;
        request.RespondedAt = DateTime.UtcNow;

        if (approve)
        {
            _context.CommunityMembers.Add(new CommunityMember
            {
                CommunityId = request.CommunityId,
                UserId = request.UserId,
                Role = CommunityRole.Member,
            });
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = approve ? "İstek onaylandı." : "İstek reddedildi."});
    }

}