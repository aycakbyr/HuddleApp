namespace EtkinlikApp.Core.Entities;

public class Follow
{
    public Guid Id { get; set;} = Guid.NewGuid();
    public Guid FollowerId { get; set; }
    public User Follower { get; set; } = null!;
    public Guid FollowingId { get; set; }
    public User Following { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}