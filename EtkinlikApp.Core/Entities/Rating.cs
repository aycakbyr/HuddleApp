namespace EtkinlikApp.Core.Entities;

// bir katılımcının, katıldığı etkinliğin kurucusuna verdiği değerlendirme
public class Rating
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EventId { get; set; }
    public Event Event { get; set; } = null!;
    public Guid RaterId { get; set; } // değerlendirmeyi yapan katılımcı
    public User Rater { get; set; } = null!;
    public Guid RatedUserId { get; set; } // değerlendirilen kişi (etkinlik kurucusu)
    public User RatedUser { get; set; } = null!;
    public int Score { get; set; } // 1-5 yıldız
    public int? CommunicationScore { get; set; } //iletişim 1-5
    public int? OrganizationScore { get; set; }
    public int? WarmthScore { get; set; } //samimiyet için
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
