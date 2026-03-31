namespace MarketplaceApi.Models;

public class Album
{
    public int Id { get; set; }
    public required string Title { get; set; }
    public required string Artist { get; set; }
    public required string Genre { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public string? Description { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
