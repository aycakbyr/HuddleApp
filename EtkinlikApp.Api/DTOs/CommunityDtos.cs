namespace EtkinlikApp.Api.DTOs;
//Yani DTO, entity'nin birebir kopyası değil, "bu ekran için gereken şekilde yeniden paketlenmiş" hali.


// topluluk oluştururken Flutter'dan gelecek veri
public class CreateCommunityDto
{
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

// Topluluklar sekmesinde listelenirken her topluluk için gönderilecek özet bilgi
public class CommunityListDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? ProfilePictureUrl { get; set; }
    public int MemberCount { get; set; }
}

// topluluk bilgileri sayfasında gösterilecek detaylı bilgi
public class CommunityDetailDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ProfilePictureUrl { get; set; }
    public Guid CreatedByUserId { get; set; }
    public int MemberCount { get; set; }
    public int EventCount { get; set; }
    public double? AverageRating { get; set; }
    public int RatingCount { get; set; }
    public List<CommunityMemberDto> Members { get; set; } = new();
}

// üye listesindeki her bir kişi için gönderilecek özet bilgi
public class CommunityMemberDto
{
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? ProfilePictureUrl { get; set; }
    public string Role { get; set; } = string.Empty; // member ya da admin
}

//yöneticinin gördüğü bekleyen katılma isteği
public class CommunityJoinRequestDto
{
    public Guid RequestId { get; set; }
    public Guid UserId { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public DateTime RequestedAt { get; set; }
}