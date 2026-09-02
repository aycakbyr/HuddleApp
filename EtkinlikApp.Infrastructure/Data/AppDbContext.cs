//Bu dosya, EF Core'un kalbi — tüm entity'lerimizi (User, Event vs.) gerçek veritabanı tablolarına bağlayan sınıf.

using EtkinlikApp.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace EtkinlikApp.Infrastructure.Data;

public class AppDbContext : DbContext //inheritance-kalıtım= DbContext kısmı ne demek? Bu, "AppDbContext sınıfı, DbContext sınıfından türüyor/miras alıyor" demek. veritabanı bağlantısı kurma, sorgu çalıştırma gibi bütün temel yetenekler zaten onun içinde yazılı.
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
        
    }

    //DbSet<User> → "veritabanındaki Users tablosunu temsil eden nesne" demek. DbSet, EF Core'un bize sunduğu özel bir tip — içinde o tabloya ait tüm kayıtları sorgulayabilir, yeni kayıt ekleyebilir, silebilirsin.
    //DbSet tanımı "bu class'ı bir tabloya dönüştür" demek.
    public DbSet<User> Users => Set<User>(); 
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Event> Events => Set<Event>();
    public DbSet<EventParticipant> EventParticipants => Set<EventParticipant>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Follow> Follows => Set<Follow>();
    public DbSet<EventPhoto> EventPhotos => Set<EventPhoto>();
    public DbSet<Rating> Ratings => Set<Rating>();
    public DbSet<ProfilePhoto> ProfilePhotos => Set<ProfilePhoto>();
    public DbSet<Community> Communities => Set<Community>();
    public DbSet<CommunityMember> CommunityMembers => Set<CommunityMember>();
    public DbSet<CommunityJoinRequest> CommunityJoinRequests => Set<CommunityJoinRequest>();

    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        //User
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasIndex(u => u.Email).IsUnique(); //benzersiz index aynı email ile ikinci kişi giremez
            entity.Property(u => u.Email).IsRequired().HasMaxLength(256); // null olamaz ve 256 karakter
            entity.Property(u => u.DisplayName).IsRequired().HasMaxLength(100);
            entity.HasIndex(u => u.Username).IsUnique();
            entity.Property(u => u.Username).HasMaxLength(30);
        });

        // Category
        modelBuilder.Entity<Category>(entity =>
        {
            entity.Property(c => c.Name).IsRequired().HasMaxLength(50);
        });

        //event
        modelBuilder.Entity<Event>(entity =>
        {
            entity.Property(e => e.Title).IsRequired().HasMaxLength(150);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.Address).HasMaxLength(300);

            entity.HasOne(e => e.Creator) // ilişkinin hangi alan üzerinde kurulduğu
                  .WithMany(u => u.CreatedEvents)
                  .HasForeignKey(e => e.CreatorId)
                  .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(e => e.Category)
                  .WithMany(c => c.Events) // one to many
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict); //kullanıcı silinirse etkinlikleri de silinsin

            entity.HasIndex(e => new {e.Latitude, e.Longitude}); //konum sorguları hızlandırmak için
            entity.HasIndex(e => e.StartTime);

            entity.HasOne(e => e.Community)
                  .WithMany(c => c.Events)
                  .HasForeignKey(e => e.CommunityId)
                  .OnDelete(DeleteBehavior.SetNull); //topluluk silinirse etkinlikler silinmesin topluluk alanı null olsun
        });

        //eventParticipant
        modelBuilder.Entity<EventParticipant>(entity =>
        {
            //aynı kullanıcı aynı etkinliğe sadece bir kez istek gönderebilir
            entity.HasIndex(ep => new { ep.EventId, ep.UserId }).IsUnique();

            entity.HasOne(ep => ep.Event)
                  .WithMany(e => e.Participants)
                  .HasForeignKey(ep => ep.EventId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ep => ep.User)
                  .WithMany(u => u.Participations)
                  .HasForeignKey(ep => ep.UserId)
                  .OnDelete(DeleteBehavior.Cascade); //birlikte silinme
        });

        // Message 
        modelBuilder.Entity<Message>(entity =>
        {
            entity.Property(m => m.Content).IsRequired().HasMaxLength(1000);

            entity.HasOne(m => m.Event)
                  .WithMany(e => e.Messages)
                  .HasForeignKey(m => m.EventId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(m => m.Sender)
                  .WithMany(u => u.Messages)
                  .HasForeignKey(m => m.SenderId)
                  .OnDelete(DeleteBehavior.Restrict);
            
            entity.HasOne(m => m.Community)
                  .WithMany(c => c.Messages)
                  .HasForeignKey(m => m.CommunityId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasIndex(m => m.SentAt);
        });

        //follow
        modelBuilder.Entity<Follow>(entity =>
        {
            //aynı kişiyi iki kez takip edemez
            entity.HasIndex(f => new {f.FollowerId, f.FollowingId}).IsUnique();

            entity.HasOne(f => f.Follower)
                  .WithMany(u => u.Following)
                  .HasForeignKey(f => f.FollowerId)
                  .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasOne(f => f.Following)
                  .WithMany(u => u.Followers)
                  .HasForeignKey(f => f.FollowingId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // event photo (anı fotoğrafları)
        modelBuilder.Entity<EventPhoto>(entity =>
        {
            entity.HasOne(p => p.Event)
                  .WithMany(e => e.Photos)
                  .HasForeignKey(p => p.EventId)
                  .OnDelete(DeleteBehavior.Cascade); // etkinlik silinirse fotoğrafları da silinsin

            entity.HasOne(p => p.User)
                  .WithMany(u => u.EventPhotos)
                  .HasForeignKey(p => p.UserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // rating (etkinlik kurucusuna değerlendirme)
        modelBuilder.Entity<Rating>(entity =>
        {
            // bir katılımcı aynı etkinliği sadece bir kez değerlendirebilir
            entity.HasIndex(r => new { r.EventId, r.RaterId }).IsUnique();

            entity.HasCheckConstraint("CK_Ratings_Score", "\"Score\" >= 1 AND \"Score\" <= 5");
            entity.HasCheckConstraint("CK_Ratings_CommunicationScore", "\"CommunicationScore\" IS NULL OR (\"CommunicationScore\" >= 1 AND \"CommunicationScore\" <= 5)");
            entity.HasCheckConstraint("CK_Ratings_OrganizationScore", "\"OrganizationScore\" IS NULL OR (\"OrganizationScore\" >= 1 AND \"OrganizationScore\" <= 5)");
            entity.HasCheckConstraint("CK_Ratings_WarmthScore", "\"WarmthScore\" IS NULL OR (\"WarmthScore\" >= 1 AND \"WarmthScore\" <= 5)");

            entity.HasOne(r => r.Event)
                  .WithMany(e => e.Ratings)
                  .HasForeignKey(r => r.EventId)
                  .OnDelete(DeleteBehavior.Cascade); // etkinlik silinirse değerlendirmeleri de silinsin

            entity.HasOne(r => r.Rater)
                  .WithMany(u => u.RatingsGiven)
                  .HasForeignKey(r => r.RaterId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(r => r.RatedUser)
                  .WithMany(u => u.RatingsReceived)
                  .HasForeignKey(r => r.RatedUserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // profile photo (kullanıcının doğrudan profiline eklediği fotoğraflar, bir etkinliğe bağlı değil)
        modelBuilder.Entity<ProfilePhoto>(entity =>
        {
            entity.HasOne(p => p.User)
                  .WithMany(u => u.ProfilePhotos)
                  .HasForeignKey(p => p.UserId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        //Community
        modelBuilder.Entity<Community>(entity =>
        {
            entity.Property(c => c.Name).IsRequired().HasMaxLength(150);
            entity.Property(c => c.Description).HasMaxLength(1000);

            entity.HasOne(c => c.CreatedByUser)
                  .WithMany(u => u.CreatedCommunities)
                  .HasForeignKey(c => c.CreatedByUserId)
                  .OnDelete(DeleteBehavior.Restrict);

        });

        //community member
        modelBuilder.Entity<CommunityMember>(entity =>
        {
            // aynı kullanıcı aynı topluluğa sadece bir kez üye olabilir
            entity.HasIndex(cm => new { cm.CommunityId, cm.UserId }).IsUnique();

            entity.HasOne(cm => cm.Community)
                  .WithMany(c => c.Members)
                  .HasForeignKey(cm => cm.CommunityId)
                  .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasOne(cm => cm.User)
                  .WithMany(u => u.CommunityMemberships)
                  .HasForeignKey(cm => cm.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        //community join requesr
        modelBuilder.Entity<CommunityJoinRequest>(entity =>
        {
            //aynı kullanıcı aynı topluluğa sadece bir kez katılım isteği gönderebilir
            entity.HasIndex(cjr => new {cjr.CommunityId, cjr.UserId }).IsUnique();

            entity.HasOne(cjr => cjr.Community)
                  .WithMany(c => c.JoinRequests)
                  .HasForeignKey(cjr => cjr.CommunityId)
                  .OnDelete(DeleteBehavior.Cascade);
            
            entity.HasOne(cjr => cjr.User)
                  .WithMany(u => u.CommunityJoinRequests)
                  .HasForeignKey(cjr => cjr.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

        });

   
        // Seed Data Kategoriler 
        modelBuilder.Entity<Category>().HasData( //bu kayıtları otomatik tabloya ekler
            new Category { Id = Guid.Parse("11111111-1111-1111-1111-111111111111"), Name = "Spor", Icon = "sports" },
            new Category { Id = Guid.Parse("22222222-2222-2222-2222-222222222222"), Name = "Kitap", Icon = "book" },
            new Category { Id = Guid.Parse("33333333-3333-3333-3333-333333333333"), Name = "Oyun", Icon = "games" },
            new Category { Id = Guid.Parse("44444444-4444-4444-4444-444444444444"), Name = "Müzik", Icon = "music" },
            new Category { Id = Guid.Parse("55555555-5555-5555-5555-555555555555"), Name = "Yemek", Icon = "restaurant" },
            new Category { Id = Guid.Parse("66666666-6666-6666-6666-666666666666"), Name = "Diğer", Icon = "more" }
        );   
    }
}
