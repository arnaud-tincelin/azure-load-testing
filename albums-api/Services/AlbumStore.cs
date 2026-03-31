using MarketplaceApi.Models;
using System.Collections.Concurrent;

namespace MarketplaceApi.Services;

public class AlbumStore
{
    private readonly ConcurrentDictionary<int, Album> _albums = new();
    private int _nextId = 1;

    public AlbumStore()
    {
        SeedData();
    }

    private void SeedData()
    {
        var albums = new[]
        {
            new Album { Id = 0, Title = "The Dark Side of the Moon", Artist = "Pink Floyd", Genre = "Progressive Rock", Price = 14.99m, Stock = 50, Description = "Iconic 1973 concept album" },
            new Album { Id = 0, Title = "Thriller", Artist = "Michael Jackson", Genre = "Pop", Price = 12.99m, Stock = 75, Description = "Best-selling album of all time" },
            new Album { Id = 0, Title = "Led Zeppelin IV", Artist = "Led Zeppelin", Genre = "Hard Rock", Price = 13.99m, Stock = 40, Description = "Features Stairway to Heaven" },
            new Album { Id = 0, Title = "Abbey Road", Artist = "The Beatles", Genre = "Rock", Price = 11.99m, Stock = 60, Description = "Penultimate studio album" },
            new Album { Id = 0, Title = "Rumours", Artist = "Fleetwood Mac", Genre = "Soft Rock", Price = 12.49m, Stock = 35, Description = "Classic 1977 album" },
            new Album { Id = 0, Title = "Kind of Blue", Artist = "Miles Davis", Genre = "Jazz", Price = 15.99m, Stock = 25, Description = "Best-selling jazz album" },
            new Album { Id = 0, Title = "Back in Black", Artist = "AC/DC", Genre = "Hard Rock", Price = 13.49m, Stock = 45, Description = "Second best-selling album" },
            new Album { Id = 0, Title = "Purple Rain", Artist = "Prince", Genre = "Pop/Rock", Price = 12.99m, Stock = 30, Description = "Soundtrack to the 1984 film" },
            new Album { Id = 0, Title = "Born to Run", Artist = "Bruce Springsteen", Genre = "Rock", Price = 11.49m, Stock = 20, Description = "Breakthrough album" },
            new Album { Id = 0, Title = "Nevermind", Artist = "Nirvana", Genre = "Grunge", Price = 12.99m, Stock = 55, Description = "Defines 90s alternative rock" },
        };

        foreach (var album in albums)
        {
            Add(album);
        }
    }

    public IEnumerable<Album> GetAll() => _albums.Values.OrderBy(a => a.Id);

    public Album? GetById(int id) => _albums.TryGetValue(id, out var album) ? album : null;

    public Album Add(Album album)
    {
        album.Id = Interlocked.Increment(ref _nextId) - 1;
        album.CreatedAt = DateTimeOffset.UtcNow;
        _albums[album.Id] = album;
        return album;
    }

    public Album? Update(int id, Album updated)
    {
        if (!_albums.ContainsKey(id))
            return null;

        updated.Id = id;
        _albums[id] = updated;
        return updated;
    }

    public bool Delete(int id) => _albums.TryRemove(id, out _);

    public IEnumerable<Album> Search(string? genre = null, decimal? maxPrice = null)
    {
        var query = _albums.Values.AsEnumerable();

        if (!string.IsNullOrWhiteSpace(genre))
            query = query.Where(a => a.Genre.Contains(genre, StringComparison.OrdinalIgnoreCase));

        if (maxPrice.HasValue)
            query = query.Where(a => a.Price <= maxPrice.Value);

        return query.OrderBy(a => a.Id);
    }
}
