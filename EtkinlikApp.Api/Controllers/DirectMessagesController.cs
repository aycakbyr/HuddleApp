using System.Security.Claims;
using EtkinlikApp.Api.DTOs;
using EtkinlikApp.Api.Services;
using EtkinlikApp.Core.Entities;
using EtkinlikApp.Infrastructure.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace EtkinlikApp.Api.Controllers;

[ApiController]
[Route("api/direct-messages")]
public class DirectMessagesController : ControllerBase
{
    private readonly AppDbContext _context;
    private readonly TypingIndicatorService _typingIndicator;
    public DirectMessagesController(AppDbContext context, TypingIndicatorService typingIndicator)
    {
        _context = context;
        _typingIndicator = typingIndicator;
    }

    // api/direct-messages/conversations - Sohbet sekmesindeki DM listesi (kiminle, en son ne konuşulmuş)
    [Authorize]
    [HttpGet("conversations")]
    public async Task<IActionResult> GetConversations()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var directMessages = await _context.Messages
            .Where(m => m.ReceiverId != null && (m.SenderId == userId || m.ReceiverId == userId))
            .OrderByDescending(m => m.SentAt)
            .ToListAsync();

        // her karşı taraf için en son mesajı buluyoruz (liste zaten en yeniden eskiye sıralı, o yüzden gruptaki ilk eleman en son mesaj)
        var lastMessagePerUser = directMessages
            .GroupBy(m => m.SenderId == userId ? m.ReceiverId!.Value : m.SenderId)
            .Select(g => g.First())
            .ToList();

        var result = new List<ConversationSummaryDto>();
        foreach (var m in lastMessagePerUser)
        {
            var otherUserId = m.SenderId == userId ? m.ReceiverId!.Value : m.SenderId;
            var otherUser = await _context.Users.FindAsync(otherUserId);
            if (otherUser == null)
                continue;

            var unreadCount = await _context.Messages.CountAsync(msg =>
                msg.SenderId == otherUserId && msg.ReceiverId == userId && !msg.IsRead && !msg.IsDeleted);

            result.Add(new ConversationSummaryDto
            {
                OtherUserId = otherUserId,
                OtherUserDisplayName = otherUser.DisplayName,
                OtherUserProfilePictureUrl = otherUser.ProfilePictureUrl,
                LastMessageContent = m.IsDeleted ? string.Empty : m.Content,
                LastMessageIsDeleted = m.IsDeleted,
                LastMessageSentAt = m.SentAt,
                IsLastMessageMine = m.SenderId == userId,
                UnreadCount = unreadCount
            });
        }

        return Ok(result.OrderByDescending(c => c.LastMessageSentAt));
    }

    // api/direct-messages/{otherUserId} - belirli bir kullanıcıyla mesaj geçmişi
    [Authorize]
    [HttpGet("{otherUserId}")]
    public async Task<IActionResult> GetDirectMessages(Guid otherUserId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var messages = await _context.Messages
            .Include(m => m.Sender)
            .Where(m => m.ReceiverId != null &&
                ((m.SenderId == userId && m.ReceiverId == otherUserId) ||
                 (m.SenderId == otherUserId && m.ReceiverId == userId)))
            .OrderBy(m => m.SentAt)
            .ToListAsync();

        // karşı taraftan bana gelen ve henüz okunmamış mesajları, ben bu sohbeti açtığım anda okundu olarak işaretliyoruz (okundu tiki için)
        var unread = messages.Where(m => m.SenderId == otherUserId && m.ReceiverId == userId && !m.IsRead).ToList();
        if (unread.Count > 0)
        {
            foreach (var m in unread)
            {
                m.IsRead = true;
                m.ReadAt = DateTime.UtcNow;
            }
            await _context.SaveChangesAsync();
        }

        var result = messages.Select(m => new MessageDto
        {
            Id = m.Id,
            Content = m.IsDeleted ? string.Empty : m.Content,
            SentAt = m.SentAt,
            SenderId = m.SenderId,
            SenderDisplayName = m.Sender.DisplayName,
            SenderProfilePictureUrl = m.Sender.ProfilePictureUrl,
            IsAnnouncement = false,
            IsDeleted = m.IsDeleted,
            IsRead = m.IsRead
        }).ToList();

        return Ok(result);
    }

    // api/direct-messages/{otherUserId} - o kullanıcıya yeni mesaj gönder
    [Authorize]
    [HttpPost("{otherUserId}")]
    public async Task<IActionResult> SendDirectMessage(Guid otherUserId, SendMessageDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        if (otherUserId == userId)
            return BadRequest(new { message = "Kendine mesaj gönderemezsin." });

        var receiverExists = await _context.Users.AnyAsync(u => u.Id == otherUserId);
        if (!receiverExists)
            return NotFound(new { message = "Kullanıcı bulunamadı." });

        // dm izin modeli: birbirini hiç takip etmeyen iki kullanıcı arasında ilk mesaj atılamaz (spam/istenmeyen mesajı önlemek için)
        // zaten devam eden bir sohbet varsa (daha önce mesajlaşılmışsa) takip ilişkisi sonradan bozulsa bile mesajlaşmaya izin veriyoruz
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
                return StatusCode(403, new { message = "Bu kullanıcıya mesaj gönderebilmen için birbirinizi takip etmeniz gerekiyor." });
        }

        if (string.IsNullOrWhiteSpace(dto.Content))
            return BadRequest(new { message = "Mesaj boş olamaz." });

        var message = new Message
        {
            SenderId = userId,
            ReceiverId = otherUserId,
            Content = dto.Content,
            SentAt = DateTime.UtcNow,
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
            SenderProfilePictureUrl = sender.ProfilePictureUrl,
            IsAnnouncement = false,
            IsDeleted = false,
            IsRead = false
        };

        return Ok(result);
    }

    // api/direct-messages/{otherUserId}/typing - "yazıyorum" bildirimi (istemci text kutusuna yazarken birkaç saniyede bir çağırır)
    [Authorize]
    [HttpPost("{otherUserId}/typing")]
    public IActionResult NotifyTyping(Guid otherUserId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        _typingIndicator.MarkTyping(userId, otherUserId);
        return Ok();
    }

    // api/direct-messages/{otherUserId}/typing - karşı taraf şu an bana yazıyor mu (istemci polling ile birlikte sorar)
    [Authorize]
    [HttpGet("{otherUserId}/typing")]
    public IActionResult GetTypingStatus(Guid otherUserId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var isTyping = _typingIndicator.IsTyping(otherUserId, userId);
        return Ok(new { isTyping });
    }

    // api/direct-messages/{otherUserId}/photos - iki kullanıcı arasında paylaşılan fotoğraflar (CommunityPhoto tablosu dm için de kullanılıyor, DRY)
    [Authorize]
    [HttpGet("{otherUserId}/photos")]
    public async Task<IActionResult> GetDirectPhotos(Guid otherUserId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var photos = await _context.CommunityPhotos
            .Include(p => p.User)
            .Where(p => p.CommunityId == null &&
                ((p.UserId == userId && p.ReceiverId == otherUserId) ||
                 (p.UserId == otherUserId && p.ReceiverId == userId)))
            .OrderByDescending(p => p.CreatedAt)
            .Select(p => new CommunityPhotoDto
            {
                Id = p.Id,
                ImageUrl = p.ImageUrl,
                UserId = p.UserId,
                UploaderDisplayName = p.User.DisplayName,
                CreatedAt = p.CreatedAt
            })
            .ToListAsync();

        return Ok(photos);
    }

    // api/direct-messages/{otherUserId}/{messageId} - DM mesajını sil (sadece gönderen silebilir, DM'de yönetici yok)
    [Authorize]
    [HttpDelete("{otherUserId}/{messageId}")]
    public async Task<IActionResult> DeleteDirectMessage(Guid otherUserId, Guid messageId)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);

        var message = await _context.Messages
            .FirstOrDefaultAsync(m => m.Id == messageId && m.ReceiverId != null &&
                ((m.SenderId == userId && m.ReceiverId == otherUserId) ||
                 (m.SenderId == otherUserId && m.ReceiverId == userId)));
        if (message == null)
            return NotFound(new { message = "Mesaj bulunamadı." });

        if (message.SenderId != userId)
            return Forbid();

        message.IsDeleted = true;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Mesaj silindi." });
    }
}