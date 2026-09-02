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
public class UsersController : ControllerBase
{
    private readonly AppDbContext _context;

    public UsersController(AppDbContext context)
    {
        _context = context;
    }

    // api/users/{id}   herhangi bir kullanıcının herkese açık profili
    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetProfile(Guid id)
    {
        var myId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        var followerCount = await _context.Follows.CountAsync(f => f.FollowingId == id);
        var followingCount = await _context.Follows.CountAsync(f => f.FollowerId == id);
        var isFollowedByMe = await _context.Follows.AnyAsync(f => f.FollowerId == myId && f.FollowingId == id);

        var ratingCount = await _context.Ratings.CountAsync(r => r.RatedUserId == id);
        var averageRating = ratingCount == 0
            ? (double?)null
            : Math.Round(await _context.Ratings.Where(r => r.RatedUserId == id).AverageAsync(r => r.Score), 1);

        return Ok(new UserProfileDto
        {
            Id = user.Id,
            DisplayName = user.DisplayName,
            Username = user.Username,
            ProfilePictureUrl = user.ProfilePictureUrl,
            FollowerCount = followerCount,
            FollowingCount = followingCount,
            IsFollowedByMe = isFollowedByMe,
            IsMe = user.Id == myId,
            AverageRating = averageRating,
            RatingCount = ratingCount
        });
    }

    // api/users/{id}/follow   kullanıcıyı takip et
    [Authorize]
    [HttpPost("{id}/follow")]
    public async Task<IActionResult> Follow(Guid id)
    {
        var myId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        if (id == myId)
            return BadRequest(new { message = "Kendini takip edemezsin." });

        var targetExists = await _context.Users.AnyAsync(u => u.Id == id);
        if (!targetExists)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        var alreadyFollowing = await _context.Follows
            .AnyAsync(f => f.FollowerId == myId && f.FollowingId == id);
        if (alreadyFollowing)
            return BadRequest(new { message = "Zaten takip ediyorsun." });

        _context.Follows.Add(new Follow
        {
            FollowerId = myId,
            FollowingId = id
        });

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: "23505" }) // 23505 = unique_violation
        {
            // İki istek aynı anda gelmiş olabilir; unique index zaten mükerrer kaydı engelledi.
            return BadRequest(new { message = "Zaten takip ediyorsun." });
        }

        return Ok(new { message = "Takip edildi." });
    }

    // api/users/{id}/follow   takibi bırak
    [Authorize]
    [HttpDelete("{id}/follow")]
    public async Task<IActionResult> Unfollow(Guid id)
    {
        var myId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var follow = await _context.Follows
            .FirstOrDefaultAsync(f => f.FollowerId == myId && f.FollowingId == id);
        if (follow == null)
            return NotFound(new { message = "Takip kaydı bulunamadı." });

        _context.Follows.Remove(follow);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Takipten çıkıldı." });
    }

    // api/users/{id}/followers   bu kullanıcıyı takip edenler
    [Authorize]
    [HttpGet("{id}/followers")]
    public async Task<IActionResult> GetFollowers(Guid id)
    {
        var followers = await _context.Follows
            .Include(f => f.Follower)
            .Where(f => f.FollowingId == id)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FollowUserDto
            {
                Id = f.Follower.Id,
                DisplayName = f.Follower.DisplayName,
                Username = f.Follower.Username
            })
            .ToListAsync();

        return Ok(followers);
    }

    // api/users/{id}/following   bu kullanıcının takip ettikleri
    [Authorize]
    [HttpGet("{id}/following")]
    public async Task<IActionResult> GetFollowing(Guid id)
    {
        var following = await _context.Follows
            .Include(f => f.Following)
            .Where(f => f.FollowerId == id)
            .OrderByDescending(f => f.CreatedAt)
            .Select(f => new FollowUserDto
            {
                Id = f.Following.Id,
                DisplayName = f.Following.DisplayName,
                Username = f.Following.Username
            })
            .ToListAsync();

        return Ok(following);
    }

    // api/users/{id}/photos anı fotoları
    [Authorize]
    [HttpGet("{id}/photos")]
    public async Task<IActionResult> GetUserPhotos(Guid id)
    {
        // etkinlik anı fotoğrafları
        var eventPhotos = await _context.EventPhotos
            .Include(p => p.Event)
            .Where(p => p.UserId == id)
            .Select(p => new EventPhotoDto
            {
                Id = p.Id,
                EventId = p.EventId,
                EventTitle = p.Event.Title,
                ImageUrl = p.ImageUrl,
                CreatedAt = p.CreatedAt
            })
            .ToListAsync();

        // doğrudan profile eklenen fotoğraflar (bir etkinliğe bağlı değil)
        var profilePhotos = await _context.ProfilePhotos
            .Where(p => p.UserId == id)
            .Select(p => new EventPhotoDto
            {
                Id = p.Id,
                EventId = null,
                EventTitle = null,
                ImageUrl = p.ImageUrl,
                CreatedAt = p.CreatedAt
            })
            .ToListAsync();

        var photos = eventPhotos
            .Concat(profilePhotos)
            .OrderByDescending(p => p.CreatedAt)
            .ToList();

        return Ok(photos);
    }

    //api/users/{id}/ratings etkinlik için aldığı değerlendirmeler
    [Authorize]
    [HttpGet("{id}/ratings")]
    public async Task<IActionResult> GetUserRatings(Guid id)
    {
        var ratings = await _context.Ratings
            .Include(r => r.Rater)
            .Where(r => r.RatedUserId == id)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync();
        
        return Ok(new UserRatingsDto
        {
            AverageScore = ratings.Count == 0 ? 0 : Math.Round(ratings.Average(r => r.Score), 1),
            RatingCount = ratings.Count,
            Ratings = ratings.Select(r => new RatingDto
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
            }).ToList()
        });
    }

    // api/users/{id}/events   bu kullanıcının oluşturduğu etkinlikler (herkese açık profilde gösterilir)
    [Authorize]
    [HttpGet("{id}/events")]
    public async Task<IActionResult> GetUserEvents(Guid id)
    {
        var events = await _context.Events
            .Include(e => e.Category)
            .Include(e => e.Participants)
            .Where(e => e.CreatorId == id)
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
}