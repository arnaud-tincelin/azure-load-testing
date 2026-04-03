# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: cart.spec.ts >> Cart API - Shopping Cart Flow >> GET /cart/:sessionId - should return cart with items
- Location: tests/cart.spec.ts:39:7

# Error details

```
Error: expect(received).toBeGreaterThan(expected)

Expected: > 0
Received:   0
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | 
  3  | test.describe('Cart API - Shopping Cart Flow', () => {
  4  |   const sessionId = `test-session-${Date.now()}`;
  5  | 
  6  |   test('GET /cart/:sessionId - should return empty cart for new session', async ({ request }) => {
  7  |     const response = await request.get(`/cart/${sessionId}`);
  8  |     expect(response.status()).toBe(200);
  9  | 
  10 |     const items = await response.json();
  11 |     expect(Array.isArray(items)).toBeTruthy();
  12 |     expect(items.length).toBe(0);
  13 |   });
  14 | 
  15 |   test('POST /cart/:sessionId/items - should add item to cart', async ({ request }) => {
  16 |     // Get an album to add to cart
  17 |     const albumsResponse = await request.get('/albums');
  18 |     const albums = await albumsResponse.json();
  19 |     const album = albums[0];
  20 | 
  21 |     const response = await request.post(`/cart/${sessionId}/items`, {
  22 |       data: { albumId: album.id, quantity: 1 },
  23 |     });
  24 |     expect(response.status()).toBe(201);
  25 | 
  26 |     const cartItem = await response.json();
  27 |     expect(cartItem.albumId).toBe(album.id);
  28 |     expect(cartItem.quantity).toBe(1);
  29 |     expect(cartItem.sessionId).toBe(sessionId);
  30 |   });
  31 | 
  32 |   test('POST /cart/:sessionId/items - should reject invalid album', async ({ request }) => {
  33 |     const response = await request.post(`/cart/${sessionId}/items`, {
  34 |       data: { albumId: 99999, quantity: 1 },
  35 |     });
  36 |     expect(response.status()).toBe(404);
  37 |   });
  38 | 
  39 |   test('GET /cart/:sessionId - should return cart with items', async ({ request }) => {
  40 |     // Add an item first to ensure cart is not empty
  41 |     const albumsResponse = await request.get('/albums');
  42 |     const albums = await albumsResponse.json();
  43 |     await request.post(`/cart/${sessionId}/items`, {
  44 |       data: { albumId: albums[0].id, quantity: 1 },
  45 |     });
  46 | 
  47 |     const response = await request.get(`/cart/${sessionId}`);
  48 |     expect(response.status()).toBe(200);
  49 | 
  50 |     const items = await response.json();
> 51 |     expect(items.length).toBeGreaterThan(0);
     |                          ^ Error: expect(received).toBeGreaterThan(expected)
  52 |   });
  53 | 
  54 |   test('DELETE /cart/:sessionId/items/:itemId - should remove item from cart', async ({ request }) => {
  55 |     // Add an item first
  56 |     const albumsResponse = await request.get('/albums');
  57 |     const albums = await albumsResponse.json();
  58 | 
  59 |     const addResponse = await request.post(`/cart/${sessionId}/items`, {
  60 |       data: { albumId: albums[1].id, quantity: 2 },
  61 |     });
  62 |     const addedItem = await addResponse.json();
  63 | 
  64 |     const response = await request.delete(`/cart/${sessionId}/items/${addedItem.id}`);
  65 |     expect(response.status()).toBe(204);
  66 |   });
  67 | 
  68 |   test('DELETE /cart/:sessionId - should clear the entire cart', async ({ request }) => {
  69 |     const response = await request.delete(`/cart/${sessionId}`);
  70 |     expect(response.status()).toBe(204);
  71 | 
  72 |     // Verify cart is empty
  73 |     const getResponse = await request.get(`/cart/${sessionId}`);
  74 |     const items = await getResponse.json();
  75 |     expect(items.length).toBe(0);
  76 |   });
  77 | });
  78 | 
```