# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: albums.spec.ts >> Albums API - CRUD Operations >> DELETE /albums/:id - should delete an album
- Location: tests/albums.spec.ts:106:7

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 204
Received: 404
```

# Test source

```ts
  20  |     expect(Array.isArray(albums)).toBeTruthy();
  21  |     for (const album of albums) {
  22  |       expect(album.genre.toLowerCase()).toContain('rock');
  23  |     }
  24  |   });
  25  | 
  26  |   test('GET /albums?maxPrice=15 - should filter albums by max price', async ({ request }) => {
  27  |     const response = await request.get('/albums?maxPrice=15');
  28  |     expect(response.status()).toBe(200);
  29  | 
  30  |     const albums = await response.json();
  31  |     expect(Array.isArray(albums)).toBeTruthy();
  32  |     for (const album of albums) {
  33  |       expect(album.price).toBeLessThanOrEqual(15);
  34  |     }
  35  |   });
  36  | 
  37  |   test('POST /albums - should create a new album', async ({ request }) => {
  38  |     const newAlbum = {
  39  |       title: 'Test Album',
  40  |       artist: 'Test Artist',
  41  |       genre: 'Jazz',
  42  |       price: 12.99,
  43  |       stock: 50,
  44  |       description: 'A test album created by Playwright',
  45  |     };
  46  | 
  47  |     const response = await request.post('/albums', { data: newAlbum });
  48  |     expect(response.status()).toBe(201);
  49  | 
  50  |     const album = await response.json();
  51  |     expect(album.title).toBe(newAlbum.title);
  52  |     expect(album.artist).toBe(newAlbum.artist);
  53  |     expect(album.id).toBeDefined();
  54  | 
  55  |     createdAlbumId = album.id;
  56  |   });
  57  | 
  58  |   test('GET /albums/:id - should return a single album', async ({ request }) => {
  59  |     // Get all albums first to grab a valid ID
  60  |     const listResponse = await request.get('/albums');
  61  |     const albums = await listResponse.json();
  62  |     const albumId = albums[0].id;
  63  | 
  64  |     const response = await request.get(`/albums/${albumId}`);
  65  |     expect(response.status()).toBe(200);
  66  | 
  67  |     const album = await response.json();
  68  |     expect(album.id).toBe(albumId);
  69  |     expect(album.title).toBeDefined();
  70  |   });
  71  | 
  72  |   test('GET /albums/:id - should return 404 for non-existent album', async ({ request }) => {
  73  |     const response = await request.get('/albums/99999');
  74  |     expect(response.status()).toBe(404);
  75  |   });
  76  | 
  77  |   test('PUT /albums/:id - should update an album', async ({ request }) => {
  78  |     // Create an album to update
  79  |     const createResponse = await request.post('/albums', {
  80  |       data: {
  81  |         title: 'Album To Update',
  82  |         artist: 'Original Artist',
  83  |         genre: 'Pop',
  84  |         price: 9.99,
  85  |         stock: 10,
  86  |       },
  87  |     });
  88  |     const created = await createResponse.json();
  89  | 
  90  |     const updatedData = {
  91  |       title: 'Updated Album Title',
  92  |       artist: 'Updated Artist',
  93  |       genre: 'Rock',
  94  |       price: 14.99,
  95  |       stock: 20,
  96  |     };
  97  | 
  98  |     const response = await request.put(`/albums/${created.id}`, { data: updatedData });
  99  |     expect(response.status()).toBe(200);
  100 | 
  101 |     const updated = await response.json();
  102 |     expect(updated.title).toBe(updatedData.title);
  103 |     expect(updated.artist).toBe(updatedData.artist);
  104 |   });
  105 | 
  106 |   test('DELETE /albums/:id - should delete an album', async ({ request }) => {
  107 |     // Create an album to delete
  108 |     const createResponse = await request.post('/albums', {
  109 |       data: {
  110 |         title: 'Album To Delete',
  111 |         artist: 'Delete Artist',
  112 |         genre: 'Blues',
  113 |         price: 7.99,
  114 |         stock: 5,
  115 |       },
  116 |     });
  117 |     const created = await createResponse.json();
  118 | 
  119 |     const response = await request.delete(`/albums/${created.id}`);
> 120 |     expect(response.status()).toBe(204);
      |                               ^ Error: expect(received).toBe(expected) // Object.is equality
  121 | 
  122 |     // Verify it's gone
  123 |     const getResponse = await request.get(`/albums/${created.id}`);
  124 |     expect(getResponse.status()).toBe(404);
  125 |   });
  126 | });
  127 | 
```