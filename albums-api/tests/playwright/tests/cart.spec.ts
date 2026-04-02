import { test, expect } from '@playwright/test';

test.describe('Cart API - Shopping Cart Flow', () => {
  const sessionId = `test-session-${Date.now()}`;

  test('GET /cart/:sessionId - should return empty cart for new session', async ({ request }) => {
    const response = await request.get(`/cart/${sessionId}`);
    expect(response.status()).toBe(200);

    const items = await response.json();
    expect(Array.isArray(items)).toBeTruthy();
    expect(items.length).toBe(0);
  });

  test('POST /cart/:sessionId/items - should add item to cart', async ({ request }) => {
    // Get an album to add to cart
    const albumsResponse = await request.get('/albums');
    const albums = await albumsResponse.json();
    const album = albums[0];

    const response = await request.post(`/cart/${sessionId}/items`, {
      data: { albumId: album.id, quantity: 1 },
    });
    expect(response.status()).toBe(201);

    const cartItem = await response.json();
    expect(cartItem.albumId).toBe(album.id);
    expect(cartItem.quantity).toBe(1);
    expect(cartItem.sessionId).toBe(sessionId);
  });

  test('POST /cart/:sessionId/items - should reject invalid album', async ({ request }) => {
    const response = await request.post(`/cart/${sessionId}/items`, {
      data: { albumId: 99999, quantity: 1 },
    });
    expect(response.status()).toBe(404);
  });

  test('GET /cart/:sessionId - should return cart with items', async ({ request }) => {
    // Add an item first to ensure cart is not empty
    const albumsResponse = await request.get('/albums');
    const albums = await albumsResponse.json();
    await request.post(`/cart/${sessionId}/items`, {
      data: { albumId: albums[0].id, quantity: 1 },
    });

    const response = await request.get(`/cart/${sessionId}`);
    expect(response.status()).toBe(200);

    const items = await response.json();
    expect(items.length).toBeGreaterThan(0);
  });

  test('DELETE /cart/:sessionId/items/:itemId - should remove item from cart', async ({ request }) => {
    // Add an item first
    const albumsResponse = await request.get('/albums');
    const albums = await albumsResponse.json();

    const addResponse = await request.post(`/cart/${sessionId}/items`, {
      data: { albumId: albums[1].id, quantity: 2 },
    });
    const addedItem = await addResponse.json();

    const response = await request.delete(`/cart/${sessionId}/items/${addedItem.id}`);
    expect(response.status()).toBe(204);
  });

  test('DELETE /cart/:sessionId - should clear the entire cart', async ({ request }) => {
    const response = await request.delete(`/cart/${sessionId}`);
    expect(response.status()).toBe(204);

    // Verify cart is empty
    const getResponse = await request.get(`/cart/${sessionId}`);
    const items = await getResponse.json();
    expect(items.length).toBe(0);
  });
});
