using EtkinlikApp.Core.Enums; //TargetGender enum'unu kullanacağız.

namespace EtkinlikApp.Core.Entities;

public class Event
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid CreatorId { get; set; }
    public User Creator { get; set; } = null!;
    public Guid CategoryId { get; set; }
    public Category Category { get; set; } = null!; 
    public Guid? CommunityId { get; set; }
    public Community? Community { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public TargetGender TargetGender { get; set; } = TargetGender.All;
    public DateTime StartTime { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<EventParticipant> Participants { get; set; } = new List<EventParticipant>();
    public ICollection<Message> Messages { get; set; } = new List<Message>();
    public ICollection<EventPhoto> Photos { get; set; } = new List<EventPhoto>(); // katılımcıların eklediği anı fotoğrafları
    public ICollection<Rating> Ratings { get; set; } = new List<Rating>(); // kurucuya yapılan değerlendirmeler
}