using MarketplaceApi.Models;
using MarketplaceApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("cart")]
public class CartController : ControllerBase
{
    private readonly CartStore _cartStore;
    private readonly AlbumStore _albumStore;

    public CartController(CartStore cartStore, AlbumStore albumStore)
    {
        _cartStore = cartStore;
        _albumStore = albumStore;
    }

    [HttpGet("{sessionId}")]
    public ActionResult<IEnumerable<CartItem>> GetCart(string sessionId)
    {
        var items = _cartStore.GetBySession(sessionId);
        return Ok(items);
    }

    [HttpPost("{sessionId}/items")]
    public ActionResult<CartItem> AddToCart(string sessionId, [FromBody] AddToCartRequest request)
    {
        var album = _albumStore.GetById(request.AlbumId);
        if (album is null)
            return NotFound($"Album {request.AlbumId} not found");

        if (album.Stock < request.Quantity)
            return BadRequest($"Insufficient stock. Available: {album.Stock}");

        var item = new CartItem
        {
            SessionId = sessionId,
            AlbumId = request.AlbumId,
            AlbumTitle = album.Title,
            Price = album.Price,
            Quantity = request.Quantity
        };

        var created = _cartStore.Add(item);
        return CreatedAtAction(nameof(GetCart), new { sessionId }, created);
    }

    [HttpDelete("{sessionId}/items/{itemId:int}")]
    public IActionResult RemoveFromCart(string sessionId, int itemId)
    {
        if (!_cartStore.Remove(itemId))
            return NotFound();
        return NoContent();
    }

    [HttpDelete("{sessionId}")]
    public IActionResult ClearCart(string sessionId)
    {
        _cartStore.ClearSession(sessionId);
        return NoContent();
    }
}

public record AddToCartRequest(int AlbumId, int Quantity = 1);
