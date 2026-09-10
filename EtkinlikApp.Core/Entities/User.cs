using System.Diagnostics.Contracts;
using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Core.Entities;

public class User
{
    //Guid (Globally Unique Identifier), her kullanıcıya benzersiz bir kimlik no vermek için 
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty; //Password değil, PasswordHash. Bunun sebebi çok kritik: kullanıcının şifresini asla düz metin (plain text) olarak veritabanında saklamıyoruz.
    public string DisplayName { get; set; } = string.Empty; //kullanıcının uygulamada görünecek adı
    public string? Username { get; set; } // benzersiz kullanıcı
    public string? ProfilePictureUrl { get; set; } // profil fotosu
    public Gender Gender { get; set; } = Gender.Unspecified; //= Gender.Unspecified kısmı da tıpkı Id'de yaptığımız gibi, bir varsayılan değer: kullanıcı cinsiyetini belirtmeden kayıt olursa, otomatik olarak "belirtilmemiş" olarak işaretlensin.
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false; // hesabını sildi mi (FK kısıtlamaları yüzünden gerçek silme yerine anonimleştiriyoruz)
    public string? PasswordResetCode { get; set; } // şifremi unuttum akışı için mailine gönderilen 6 haneli kod
    public DateTime? PasswordResetCodeExpiresAt { get; set; } // kodun geçerlilik süresi (15dk)
    public bool ProfileCompleted { get; set; } = true; // normal kayıtta hep true; Google ile ilk kez giriş yapan hesaplarda false (doğum tarihi/cinsiyet Google'dan gelmiyor, sonradan tamamlatıyoruz)
    public ICollection<Event> CreatedEvents { get; set; } = new List<Event>(); //bir kullanıcı birden fazla etkinlik oluşturabilir
    public ICollection<EventParticipant> Participations { get; set; } = new List<EventParticipant>(); //Participations → bu kullanıcının katıldığı (veya katılım isteği gönderdiği) etkinlikler listesi
    public ICollection<Message> Messages { get; set; } = new List<Message>();  //Messages → bu kullanıcının gönderdiği chat mesajları listesi
    public DateTime BirthDate { get; set; }
    public ICollection<Follow> Followers { get; set; } = new List<Follow>(); //beni takip eden 
    public ICollection<Follow> Following { get; set; } = new List<Follow>(); // takip ettiklerim
    public ICollection<EventPhoto> EventPhotos { get; set; } = new List<EventPhoto>(); // eklediğim anı fotoğrafları
    public ICollection<ProfilePhoto> ProfilePhotos { get; set; } = new List<ProfilePhoto>(); // doğrudan profilime eklediğim fotoğraflar
    public ICollection<Rating> RatingsGiven { get; set; } = new List<Rating>(); // yaptığım değerlendirmeler
    public ICollection<Rating> RatingsReceived { get; set; } = new List<Rating>(); // etkinlik kurucusu olarak aldığım değerlendirmeler
    public ICollection<Community> CreatedCommunities { get; set; } = new List<Community>(); // oluşturduğum topluluklar
    public ICollection<CommunityMember> CommunityMemberships { get; set; } = new List<CommunityMember>(); //üye olduğum topluluklar
    public ICollection<CommunityPhoto> CommunityPhotos { get; set; } = new List<CommunityPhoto>(); //topluluğa eklediğim fotolar
    public ICollection<CommunityJoinRequest> CommunityJoinRequests { get; set; } = new List<CommunityJoinRequest>(); // topluluklara gönderdiğim katılım istekleri
    
}