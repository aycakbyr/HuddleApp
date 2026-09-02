using EtkinlikApp.Core.Enums;

namespace EtkinlikApp.Core.Entities;

public class EventParticipant
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid EventId { get; set; } //EventId hangi etkinliğe ait olduğunu
    public Event Event { get; set; } = null!;
    public Guid UserId { get; set; } //UserId hangi kullanıcının istek gönderdiğini tutuyor.
    public User User { get; set; } = null!;
    public ParticipantStatus Status { get; set; } = ParticipantStatus.Pending; //Pending, çünkü hatırlarsan kararımız şuydu: biri "Katıl" dediğinde önce bekleme durumuna düşüyor, etkinlik sahibi onaylayana kadar.
    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAt { get; set; }
    

}