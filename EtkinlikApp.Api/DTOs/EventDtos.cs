using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Api.DTOs;

// Etkinlik oluştururken dışarıdan gelen veri
public class CreateEventDto // kullanıcının göndereceği alanlar
{
    public Guid CategoryId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public TargetGender TargetGender { get; set; } = TargetGender.All;
    public DateTime StartTime { get; set; }
}

// Etkinlik listelenirken dışarıya giden veri
public class EventListDto //listede gösterilecek alanlar
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string TargetGender { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public int ParticipantCount { get; set; }
    public string OrganizerName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public double? OrganizerAverageRating { get; set; } // haritada/listede kurucunun ortalama puanı
}

public class EventDetailDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public Guid CategoryId { get; set; }
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string TargetGender { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public Guid OrganizerId { get; set; }
    public string OrganizerName { get; set; } = string.Empty;
    public string? ImageUrl { get; set; }
    public string? CurrentUserStatus { get; set; }
    public List<ParticipantDto> Participants { get; set; } = new();
    public bool CanAddMemoryPhoto { get; set; }
    public bool CanRateOrganizer { get; set; }
    public int? MyRatingScore { get; set; }
    public string? MyRatingComment { get; set; }
    public int? MyRatingCommunicationScore { get; set; }
    public int? MyRatingOrganizationScore { get; set; }
    public int? MyRatingWarmthScore { get; set; }
    public double? OrganizerAverageRating { get; set; }
    public int OrganizerRatingCount { get; set; }
    public List<RatingDto> EventRatings { get; set; } = new(); // bu etkinliğe yapılmış değerlendirmeler (yorumlar)
}


public class ParticipantDto
{
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
}

//bekleyen katılım istekleri
public class PendingRequestDto
{
    public Guid ParticipantId { get; set; }
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
}

// "Etkinliklerim" listesi - kullanıcının oluşturduğu etkinlikler
public class MyEventListDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public int ParticipantCount { get; set; }
    public int PendingRequestCount { get; set; }
    public string? ImageUrl { get; set; }
}

// Bildirimler - kullanıcının sahip olduğu tüm etkinlikler için bekleyen istekler
public class PendingRequestWithEventDto
{
    public Guid ParticipantId { get; set; }
    public Guid EventId { get; set; }
    public string EventTitle { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
}

// değerlendirilirken mobilden gelen veri
public class RateEventDto
{
    public int Score { get; set; }
    public int? CommunicationScore { get; set; }
    public int? OrganizationScore { get; set; }
    public int? WarmthScore { get; set; }
    public string? Comment { get; set; }
}

