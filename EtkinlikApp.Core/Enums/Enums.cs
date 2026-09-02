//sabit değer listeleri (enum). Örneğin bir kullanıcının cinsiyeti sadece 3 değerden biri olabilir, bunu enum ile ifade ediyoruz.

namespace EtkinlikApp.Core.Enums; //ileride başka bir dosyada bu enum'ları kullanmak istediğimizde using EtkinlikApp.Core.Enums; yazarak buraya erişeceğiz.
public enum Gender //Gender, bir kullanıcının kendi cinsiyeti.
{
    Unspecified,
    Male,
    Female
}

public enum TargetGender //TargetGender ise bir etkinliğin kimlere açık olduğu
{
    All,
    Male,
    Female
}

public enum ParticipantStatus //katılım isteklerinin durumunu tutacak
{
    Pending,
    Approved,
    Rejected
}
public enum CommunityRole
{
    Member,
    Admin
}