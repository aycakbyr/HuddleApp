namespace EtkinlikApp.Core.Entities;

public class CommunityPhoto
{
    
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid? CommunityId { get; set; } // dm fotoğrafında boş kalır
    public Community? Community { get; set; }
    public Guid? ReceiverId { get; set; } // dm fotoğrafı ise karşı taraf, topluluk fotoğrafıysa boş
    public User? Receiver { get; set; }
    public Guid UserId { get; set; } //foto ekleyen/gönderen kişi
    public User User { get; set; } = null!;
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
}