import { test, expect } from '@playwright/test';

test.describe('Albums API - End-to-End User Journey', () => {
  const sessionId = `e2e-session-${Date.now()}`;

  test('complete shopping flow: browse → add to cart → review → clear', async ({ request }) => {
    // Step 1: Browse all albums
    const browseResponse = await request.get('/albums');
    expect(browseResponse.status()).toBe(200);
    const albums = await browseResponse.json();
    expect(albums.length).toBeGreaterThan(0);

    // Step 2: Filter by genre
    const rockAlbums = await (await request.get('/albums?genre=Rock')).json();

    // Step 3: View album details
    const albumId = albums[0].id;
    const detailResponse = await request.get(`/albums/${albumId}`);
    expect(detailResponse.status()).toBe(200);
    const albumDetail = await detailResponse.json();
    expect(albumDetail.title).toBeDefined();

    // Step 4: Add items to cart
    const addResponse = await request.post(`/cart/${sessionId}/items`, {
      data: { albumId: albumDetail.id, quantity: 1 },
    });
    expect(addResponse.status()).toBe(201);

    // Add a second item if available
    if (albums.length > 1) {
      const addResponse2 = await request.post(`/cart/${sessionId}/items`, {
        data: { albumId: albums[1].id, quantity: 2 },
      });
      expect(addResponse2.status()).toBe(201);
    }

    // Step 5: Review cart
    const cartResponse = await request.get(`/cart/${sessionId}`);
    expect(cartResponse.status()).toBe(200);
    const cartItems = await cartResponse.json();
    expect(cartItems.length).toBeGreaterThanOrEqual(1);

    // Step 6: Clear cart
    const clearResponse = await request.delete(`/cart/${sessionId}`);
    expect(clearResponse.status()).toBe(204);

    // Step 7: Verify cart is empty
    const emptyCartResponse = await request.get(`/cart/${sessionId}`);
    const emptyCart = await emptyCartResponse.json();
    expect(emptyCart.length).toBe(0);
  });

  test('inventory management: create → update → verify → delete', async ({ request }) => {
    // Step 1: Create a new album
    const newAlbum = {
      title: 'E2E Test Album',
      artist: 'E2E Artist',
      genre: 'Electronic',
      price: 19.99,
      stock: 100,
      description: 'Created during E2E test',
    };

    const createResponse = await request.post('/albums', { data: newAlbum });
    expect(createResponse.status()).toBe(201);
    const created = await createResponse.json();

    // Step 2: Update the album
    const updateResponse = await request.put(`/albums/${created.id}`, {
      data: { ...newAlbum, price: 24.99, stock: 75 },
    });
    expect(updateResponse.status()).toBe(200);
    const updated = await updateResponse.json();
    expect(updated.price).toBe(24.99);

    // Step 3: Verify the update
    const verifyResponse = await request.get(`/albums/${created.id}`);
    expect(verifyResponse.status()).toBe(200);
    const verified = await verifyResponse.json();
    expect(verified.price).toBe(24.99);
    expect(verified.stock).toBe(75);

    // Step 4: Delete the album
    const deleteResponse = await request.delete(`/albums/${created.id}`);
    expect(deleteResponse.status()).toBe(204);

    // Step 5: Verify deletion
    const notFoundResponse = await request.get(`/albums/${created.id}`);
    expect(notFoundResponse.status()).toBe(404);
  });
});
