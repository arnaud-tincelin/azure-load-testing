# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-journey.spec.ts >> Albums API - End-to-End User Journey >> inventory management: create → update → verify → delete
- Location: tests/e2e-journey.spec.ts:53:7

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 200
Received: 404
```

# Test source

```ts
  1  | import { test, expect } from '@playwright/test';
  2  | 
  3  | test.describe('Albums API - End-to-End User Journey', () => {
  4  |   const sessionId = `e2e-session-${Date.now()}`;
  5  | 
  6  |   test('complete shopping flow: browse → add to cart → review → clear', async ({ request }) => {
  7  |     // Step 1: Browse all albums
  8  |     const browseResponse = await request.get('/albums');
  9  |     expect(browseResponse.status()).toBe(200);
  10 |     const albums = await browseResponse.json();
  11 |     expect(albums.length).toBeGreaterThan(0);
  12 | 
  13 |     // Step 2: Filter by genre
  14 |     const rockAlbums = await (await request.get('/albums?genre=Rock')).json();
  15 | 
  16 |     // Step 3: View album details
  17 |     const albumId = albums[0].id;
  18 |     const detailResponse = await request.get(`/albums/${albumId}`);
  19 |     expect(detailResponse.status()).toBe(200);
  20 |     const albumDetail = await detailResponse.json();
  21 |     expect(albumDetail.title).toBeDefined();
  22 | 
  23 |     // Step 4: Add items to cart
  24 |     const addResponse = await request.post(`/cart/${sessionId}/items`, {
  25 |       data: { albumId: albumDetail.id, quantity: 1 },
  26 |     });
  27 |     expect(addResponse.status()).toBe(201);
  28 | 
  29 |     // Add a second item if available
  30 |     if (albums.length > 1) {
  31 |       const addResponse2 = await request.post(`/cart/${sessionId}/items`, {
  32 |         data: { albumId: albums[1].id, quantity: 2 },
  33 |       });
  34 |       expect(addResponse2.status()).toBe(201);
  35 |     }
  36 | 
  37 |     // Step 5: Review cart
  38 |     const cartResponse = await request.get(`/cart/${sessionId}`);
  39 |     expect(cartResponse.status()).toBe(200);
  40 |     const cartItems = await cartResponse.json();
  41 |     expect(cartItems.length).toBeGreaterThanOrEqual(1);
  42 | 
  43 |     // Step 6: Clear cart
  44 |     const clearResponse = await request.delete(`/cart/${sessionId}`);
  45 |     expect(clearResponse.status()).toBe(204);
  46 | 
  47 |     // Step 7: Verify cart is empty
  48 |     const emptyCartResponse = await request.get(`/cart/${sessionId}`);
  49 |     const emptyCart = await emptyCartResponse.json();
  50 |     expect(emptyCart.length).toBe(0);
  51 |   });
  52 | 
  53 |   test('inventory management: create → update → verify → delete', async ({ request }) => {
  54 |     // Step 1: Create a new album
  55 |     const newAlbum = {
  56 |       title: 'E2E Test Album',
  57 |       artist: 'E2E Artist',
  58 |       genre: 'Electronic',
  59 |       price: 19.99,
  60 |       stock: 100,
  61 |       description: 'Created during E2E test',
  62 |     };
  63 | 
  64 |     const createResponse = await request.post('/albums', { data: newAlbum });
  65 |     expect(createResponse.status()).toBe(201);
  66 |     const created = await createResponse.json();
  67 | 
  68 |     // Step 2: Update the album
  69 |     const updateResponse = await request.put(`/albums/${created.id}`, {
  70 |       data: { ...newAlbum, price: 24.99, stock: 75 },
  71 |     });
> 72 |     expect(updateResponse.status()).toBe(200);
     |                                     ^ Error: expect(received).toBe(expected) // Object.is equality
  73 |     const updated = await updateResponse.json();
  74 |     expect(updated.price).toBe(24.99);
  75 | 
  76 |     // Step 3: Verify the update
  77 |     const verifyResponse = await request.get(`/albums/${created.id}`);
  78 |     expect(verifyResponse.status()).toBe(200);
  79 |     const verified = await verifyResponse.json();
  80 |     expect(verified.price).toBe(24.99);
  81 |     expect(verified.stock).toBe(75);
  82 | 
  83 |     // Step 4: Delete the album
  84 |     const deleteResponse = await request.delete(`/albums/${created.id}`);
  85 |     expect(deleteResponse.status()).toBe(204);
  86 | 
  87 |     // Step 5: Verify deletion
  88 |     const notFoundResponse = await request.get(`/albums/${created.id}`);
  89 |     expect(notFoundResponse.status()).toBe(404);
  90 |   });
  91 | });
  92 | 
```