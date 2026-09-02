namespace EtkinlikApp.Api.DTOs;

//herkese açık kullanıcı profili
public class UserProfileDto
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? Username { get; set; }
    public string? ProfilePictureUrl { get; set; }
    public int FollowerCount { get; set; }
    public int FollowingCount { get; set; }
    public bool IsFollowedByMe { get; set; }
    public bool IsMe { get; set; }
    public double? AverageRating { get; set; }
    public int RatingCount { get; set; }
}

//takipçi takip edilen için kısa bilgi
public class FollowUserDto
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? Username { get; set; }
}

//profildeki fotolar
public class EventPhotoDto
{
    public Guid Id { get; set; }
    public Guid? EventId { get; set; } // bir etkinliğe bağlıysa dolu, doğrudan profile eklendiyse null
    public string? EventTitle { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

// değerlendirmeler
public class RatingDto
{
    public Guid Id { get; set; }
    public Guid RaterId { get; set; }
    public string RaterDisplayName { get; set; } = string.Empty;
    public int Score { get; set; }
    public int? CommunicationScore { get; set; }
    public int? OrganizationScore { get; set; }
    public int? WarmthScore { get; set; }
    public string? Comment { get; set; }
    public DateTime CreatedAt { get; set; }
}

// ana değerlendirmeler
public class UserRatingsDto
{
    public double AverageScore { get; set; }
    public int RatingCount { get; set; }
    public List<RatingDto> Ratings { get; set; } = new();
}

// bir kullanıcının oluşturduğu etkinlikler (herkese açık profilde gösterilir)
public class UserEventListDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public DateTime StartTime { get; set; }
    public int ParticipantCount { get; set; }
    public string? ImageUrl { get; set; }
}