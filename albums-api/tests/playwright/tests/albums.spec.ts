import { test, expect } from '@playwright/test';

test.describe('Albums API - CRUD Operations', () => {
  let createdAlbumId: number;

  test('GET /albums - should return a list of albums', async ({ request }) => {
    const response = await request.get('/albums');
    expect(response.status()).toBe(200);

    const albums = await response.json();
    expect(Array.isArray(albums)).toBeTruthy();
    expect(albums.length).toBeGreaterThan(0);
  });

  test('GET /albums?genre=Rock - should filter albums by genre', async ({ request }) => {
    const response = await request.get('/albums?genre=Rock');
    expect(response.status()).toBe(200);

    const albums = await response.json();
    expect(Array.isArray(albums)).toBeTruthy();
    for (const album of albums) {
      expect(album.genre.toLowerCase()).toContain('rock');
    }
  });

  test('GET /albums?maxPrice=15 - should filter albums by max price', async ({ request }) => {
    const response = await request.get('/albums?maxPrice=15');
    expect(response.status()).toBe(200);

    const albums = await response.json();
    expect(Array.isArray(albums)).toBeTruthy();
    for (const album of albums) {
      expect(album.price).toBeLessThanOrEqual(15);
    }
  });

  test('POST /albums - should create a new album', async ({ request }) => {
    const newAlbum = {
      title: 'Test Album',
      artist: 'Test Artist',
      genre: 'Jazz',
      price: 12.99,
      stock: 50,
      description: 'A test album created by Playwright',
    };

    const response = await request.post('/albums', { data: newAlbum });
    expect(response.status()).toBe(201);

    const album = await response.json();
    expect(album.title).toBe(newAlbum.title);
    expect(album.artist).toBe(newAlbum.artist);
    expect(album.id).toBeDefined();

    createdAlbumId = album.id;
  });

  test('GET /albums/:id - should return a single album', async ({ request }) => {
    // Get all albums first to grab a valid ID
    const listResponse = await request.get('/albums');
    const albums = await listResponse.json();
    const albumId = albums[0].id;

    const response = await request.get(`/albums/${albumId}`);
    expect(response.status()).toBe(200);

    const album = await response.json();
    expect(album.id).toBe(albumId);
    expect(album.title).toBeDefined();
  });

  test('GET /albums/:id - should return 404 for non-existent album', async ({ request }) => {
    const response = await request.get('/albums/99999');
    expect(response.status()).toBe(404);
  });

  test('PUT /albums/:id - should update an album', async ({ request }) => {
    // Create an album to update
    const createResponse = await request.post('/albums', {
      data: {
        title: 'Album To Update',
        artist: 'Original Artist',
        genre: 'Pop',
        price: 9.99,
        stock: 10,
      },
    });
    const created = await createResponse.json();

    const updatedData = {
      title: 'Updated Album Title',
      artist: 'Updated Artist',
      genre: 'Rock',
      price: 14.99,
      stock: 20,
    };

    const response = await request.put(`/albums/${created.id}`, { data: updatedData });
    expect(response.status()).toBe(200);

    const updated = await response.json();
    expect(updated.title).toBe(updatedData.title);
    expect(updated.artist).toBe(updatedData.artist);
  });

  test('DELETE /albums/:id - should delete an album', async ({ request }) => {
    // Create an album to delete
    const createResponse = await request.post('/albums', {
      data: {
        title: 'Album To Delete',
        artist: 'Delete Artist',
        genre: 'Blues',
        price: 7.99,
        stock: 5,
      },
    });
    const created = await createResponse.json();

    const response = await request.delete(`/albums/${created.id}`);
    expect(response.status()).toBe(204);

    // Verify it's gone
    const getResponse = await request.get(`/albums/${created.id}`);
    expect(getResponse.status()).toBe(404);
  });
});
