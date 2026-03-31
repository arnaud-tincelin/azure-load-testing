namespace MarketplaceApi.Models;

public class CartItem
{
    public int Id { get; set; }
    public required string SessionId { get; set; }
    public int AlbumId { get; set; }
    public required string AlbumTitle { get; set; }
    public decimal Price { get; set; }
    public int Quantity { get; set; }
    public DateTimeOffset AddedAt { get; set; } = DateTimeOffset.UtcNow;
}
