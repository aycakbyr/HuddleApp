using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Core.Entities;

public class CommunityJoinRequest
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CommunityId { get; set; }
    public Community Community { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public ParticipantStatus Status { get; set; } = ParticipantStatus.Pending;
    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAt { get; set; }
}