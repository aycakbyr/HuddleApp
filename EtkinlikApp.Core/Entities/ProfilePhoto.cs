namespace EtkinlikApp.Core.Entities;

// kullanıcının doğrudan kendi profiline eklediği fotoğraf (bir etkinliğe bağlı değil)
public class ProfilePhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
