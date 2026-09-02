namespace EtkinlikApp.Core.Entities;

// bir katılımcının etkinlikten sonra eklediği anı fotoğrafı
public class EventPhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EventId { get; set; }
    public Event Event { get; set; } = null!;
    public Guid UserId { get; set; } // fotoğrafı ekleyen katılımcı
    public User User { get; set; } = null!;
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
