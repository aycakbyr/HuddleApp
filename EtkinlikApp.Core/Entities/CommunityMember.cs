using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Core.Entities;

public class CommunityMember
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CommunityId { get; set; }
    public Community Community { get; set; } = null!;
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public CommunityRole Role { get; set; } = CommunityRole.Member;
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}