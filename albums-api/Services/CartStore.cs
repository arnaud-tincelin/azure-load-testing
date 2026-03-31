using MarketplaceApi.Models;
using System.Collections.Concurrent;

namespace MarketplaceApi.Services;

public class CartStore
{
    private readonly ConcurrentDictionary<int, CartItem> _items = new();
    private int _nextId = 1;

    public IEnumerable<CartItem> GetBySession(string sessionId) =>
        _items.Values.Where(i => i.SessionId == sessionId).OrderBy(i => i.Id);

    public CartItem Add(CartItem item)
    {
        item.Id = Interlocked.Increment(ref _nextId) - 1;
        item.AddedAt = DateTimeOffset.UtcNow;
        _items[item.Id] = item;
        return item;
    }

    public bool Remove(int id) => _items.TryRemove(id, out _);

    public bool ClearSession(string sessionId)
    {
        var keys = _items.Where(kvp => kvp.Value.SessionId == sessionId).Select(kvp => kvp.Key).ToList();
        foreach (var key in keys)
            _items.TryRemove(key, out _);
        return true;
    }
}
