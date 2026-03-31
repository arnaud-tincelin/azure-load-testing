using MarketplaceApi.Models;
using MarketplaceApi.Services;
using Microsoft.AspNetCore.Mvc;

namespace MarketplaceApi.Controllers;

[ApiController]
[Route("albums")]
public class AlbumsController : ControllerBase
{
    private readonly AlbumStore _store;

    public AlbumsController(AlbumStore store)
    {
        _store = store;
    }

    [HttpGet]
    public ActionResult<IEnumerable<Album>> GetAll([FromQuery] string? genre, [FromQuery] decimal? maxPrice)
    {
        var albums = _store.Search(genre, maxPrice);
        return Ok(albums);
    }

    [HttpGet("{id:int}")]
    public ActionResult<Album> GetById(int id)
    {
        var album = _store.GetById(id);
        if (album is null)
            return NotFound();
        return Ok(album);
    }

    [HttpPost]
    public ActionResult<Album> Create([FromBody] Album album)
    {
        var created = _store.Add(album);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:int}")]
    public ActionResult<Album> Update(int id, [FromBody] Album album)
    {
        var updated = _store.Update(id, album);
        if (updated is null)
            return NotFound();
        return Ok(updated);
    }

    [HttpDelete("{id:int}")]
    public IActionResult Delete(int id)
    {
        if (!_store.Delete(id))
            return NotFound();
        return NoContent();
    }
}
