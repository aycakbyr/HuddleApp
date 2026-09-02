namespace EtkinlikApp.Core.Entities;

public class Category
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Name { get; set; } = string.Empty;
    public string Icon { get; set; } = string.Empty;
    public ICollection<Event> Events { get; set; } = new List<Event>(); //bir kategorinin (örn. "Spor") altında birden fazla etkinlik olabilir, bu yüzden liste tutuyoruz.

}