using System.Security.Claims;
using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/communities/{communityId}/messages")] //mesajların topluluğa bağlı olmasını url e yansıtıyoruz
public class MessagesController : ControllerBase
{
    private readonly AppDbContext _context;
    public MessagesController(AppDbContext context)
    {
        _context = context;
    }

    // api/communities/{communityId}/messages - topluluğun sohbet geçmişini listele
    [Authorize]
    [HttpGet]
    public async Task<IActionResult> GetMessages(Guid communityId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var isMember = await _context.CommunityMembers
            .AnyAsync(m => m.CommunityId == communityId && m.UserId == userId);
        if (!isMember)
            return Forbid();

        var messages = await _context.Messages
            .Where(m => m.CommunityId == communityId)
            .OrderBy(m => m.SentAt)
            .Select(m => new MessageDto
            {
                Id = m.Id,
                Content = m.Content,
                SentAt = m.SentAt,
                SenderId = m.SenderId,
                SenderDisplayName = m.Sender.DisplayName,
                SenderProfilePictureUrl = m.Sender.ProfilePictureUrl
            })
            .ToListAsync();

        return Ok(messages);
    }

    // api/communities/{communityId}/messages - topluluğa yeni mesaj gönder
    [Authorize]
    [HttpPost]
    public async Task<IActionResult> SendMessage(Guid communityId, SendMessageDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var isMember = await _context.CommunityMembers
            .AnyAsync(m => m.CommunityId == communityId && m.UserId == userId);
        if (!isMember)
            return Forbid();

        if (string.IsNullOrWhiteSpace(dto.Content))
            return BadRequest(new { message = "Mesaj boş olamaz." });

        var message = new Message
        {
            CommunityId = communityId,
            SenderId = userId,
            Content = dto.Content,
            SentAt = DateTime.UtcNow
        };

        _context.Messages.Add(message);
        await _context.SaveChangesAsync();

        var sender = await _context.Users.FindAsync(userId);

        var result = new MessageDto
        {
            Id = message.Id,
            Content = message.Content,
            SentAt = message.SentAt,
            SenderId = userId,
            SenderDisplayName = sender!.DisplayName,
            SenderProfilePictureUrl = sender.ProfilePictureUrl
        };

        return Ok(result);
    }
}