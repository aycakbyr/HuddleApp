namespace EtkinlikApp.Core.Entities;

public class Community
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ProfilePictureUrl { get; set; }
    public Guid CreatedByUserId { get; set; }
    public User CreatedByUser { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    //bu etkinliğe bağlı olan tüm katılımcılar/mesajlar/fotoğraflar/değerlendirmeler listesi
    public ICollection<CommunityMember> Members { get; set; } = new List<CommunityMember>();
    public ICollection<CommunityJoinRequest> JoinRequests { get; set; } = new List<CommunityJoinRequest>();
    public ICollection<Event> Events { get; set; } = new List<Event>();
    public ICollection<Message> Messages { get; set; } = new List<Message>();
    public ICollection<CommunityPhoto> Photos { get; set; } = new List<CommunityPhoto>(); //topluluktan paylaşılan fotolar
//Bu koleksiyonlar sayesinde ileride kod içinde community.Members.Count yazarak üye sayısını, community.Events yazarak paylaştığı etkinlikleri kolayca alabileceğiz

}