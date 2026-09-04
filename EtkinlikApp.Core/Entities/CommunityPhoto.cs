namespace EtkinlikApp.Core.Entities;

public class CommunityPhoto
{
    
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CommunityId { get; set; }
    public Community Community { get; set; } = null!;
    public Guid UserId { get; set; } //foto ekleyen üye
    public User User { get; set; } = null!;
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
}