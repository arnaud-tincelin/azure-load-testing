# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: frontend.spec.ts >> Album Marketplace - Browser Tests >> filter albums by genre
- Location: tests/frontend.spec.ts:31:7

# Error details

```
Error: expect(received).toContain(expected) // indexOf

Expected substring: "grunge"
Received string:    "progressive rock"
```

# Page snapshot

```yaml
- generic [ref=e1]:
  - banner [ref=e2]:
    - heading "🎵 Album Marketplace" [level=1] [ref=e3]
    - generic [ref=e4] [cursor=pointer]: 🛒 0
  - main [ref=e5]:
    - generic [ref=e6]:
      - generic [ref=e7]: "Genre:"
      - combobox "Genre:" [ref=e8]:
        - option "All Genres"
        - option "Grunge" [selected]
        - option "Hard Rock"
        - option "Jazz"
        - option "Pop"
        - option "Pop/Rock"
        - option "Progressive Rock"
        - option "Rock"
        - option "Soft Rock"
      - generic [ref=e9]: "Max Price:"
      - spinbutton "Max Price:" [ref=e10]
      - button "Filter" [active] [ref=e11] [cursor=pointer]
      - button "Clear" [ref=e12] [cursor=pointer]
    - generic [ref=e14]:
      - heading "Nevermind" [level=3] [ref=e15]:
        - link "Nevermind" [ref=e16] [cursor=pointer]:
          - /url: "#"
      - generic [ref=e17]: Nirvana
      - generic [ref=e18]: Grunge
      - generic [ref=e19]: $12.99
      - generic [ref=e20]: 55 in stock
      - button "Add to Cart" [ref=e22] [cursor=pointer]
```

# Test source

```ts
  1   | import { test, expect } from '@playwright/test';
  2   | 
  3   | const API_BASE = process.env.SERVICE_ALBUMS_API_ENDPOINT_URL || 'http://localhost:5080';
  4   | const FRONTEND_URL = process.env.SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL || 'http://localhost:8080';
  5   | 
  6   | test.describe('Album Marketplace - Browser Tests', () => {
  7   |   test.beforeEach(async ({ page }) => {    // Inject API_BASE for local dev (in production, nginx proxies /albums and /cart)
  8   |     await page.addInitScript((apiBase) => {
  9   |       (window as any).__API_BASE__ = apiBase;
  10  |     }, FRONTEND_URL === API_BASE ? '' : API_BASE);    await page.goto(FRONTEND_URL);
  11  |   });
  12  | 
  13  |   test('homepage loads with albums displayed', async ({ page }) => {
  14  |     await expect(page).toHaveTitle('Album Marketplace');
  15  |     const grid = page.getByTestId('album-grid');
  16  |     await expect(grid).toBeVisible();
  17  |     const cards = page.getByTestId('album-card');
  18  |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  19  |     expect(await cards.count()).toBeGreaterThan(0);
  20  |   });
  21  | 
  22  |   test('album cards show title, artist, genre, and price', async ({ page }) => {
  23  |     const card = page.getByTestId('album-card').first();
  24  |     await expect(card).toBeVisible({ timeout: 10000 });
  25  |     await expect(card.getByTestId('album-title')).not.toBeEmpty();
  26  |     await expect(card.getByTestId('album-artist')).not.toBeEmpty();
  27  |     await expect(card.getByTestId('album-genre')).not.toBeEmpty();
  28  |     await expect(card.getByTestId('album-price')).toContainText('$');
  29  |   });
  30  | 
  31  |   test('filter albums by genre', async ({ page }) => {
  32  |     const genreFilter = page.getByTestId('genre-filter');
  33  |     await expect(genreFilter).toBeVisible();
  34  | 
  35  |     // Wait for genres to load
  36  |     await page.waitForFunction(() => {
  37  |       const select = document.querySelector('[data-testid="genre-filter"]') as HTMLSelectElement;
  38  |       return select && select.options.length > 1;
  39  |     });
  40  | 
  41  |     // Select a genre
  42  |     const options = await genreFilter.locator('option').allTextContents();
  43  |     const genre = options.find(o => o !== 'All Genres')!;
  44  |     await genreFilter.selectOption({ label: genre });
  45  |     await page.getByTestId('apply-filters').click();
  46  | 
  47  |     // Verify filtered results
  48  |     const cards = page.getByTestId('album-card');
  49  |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  50  |     const genres = await cards.getByTestId('album-genre').allTextContents();
  51  |     for (const g of genres) {
> 52  |       expect(g.toLowerCase()).toContain(genre.toLowerCase());
      |                               ^ Error: expect(received).toContain(expected) // indexOf
  53  |     }
  54  |   });
  55  | 
  56  |   test('filter albums by max price', async ({ page }) => {
  57  |     await page.getByTestId('price-filter').fill('15');
  58  |     await page.getByTestId('apply-filters').click();
  59  | 
  60  |     const cards = page.getByTestId('album-card');
  61  |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  62  |     const prices = await cards.getByTestId('album-price').allTextContents();
  63  |     for (const p of prices) {
  64  |       const value = parseFloat(p.replace('$', ''));
  65  |       expect(value).toBeLessThanOrEqual(15);
  66  |     }
  67  |   });
  68  | 
  69  |   test('clear filters restores all albums', async ({ page }) => {
  70  |     // Get initial count
  71  |     const cards = page.getByTestId('album-card');
  72  |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  73  |     const initialCount = await cards.count();
  74  | 
  75  |     // Apply a restrictive filter
  76  |     await page.getByTestId('price-filter').fill('5');
  77  |     await page.getByTestId('apply-filters').click();
  78  |     await page.waitForTimeout(500);
  79  | 
  80  |     // Clear filters
  81  |     await page.getByTestId('clear-filters').click();
  82  |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  83  |     const restoredCount = await cards.count();
  84  |     expect(restoredCount).toBe(initialCount);
  85  |   });
  86  | 
  87  |   test('view album detail', async ({ page }) => {
  88  |     const firstTitle = page.getByTestId('album-card').first().getByTestId('album-title');
  89  |     await expect(firstTitle).toBeVisible({ timeout: 10000 });
  90  |     await firstTitle.click();
  91  | 
  92  |     const modal = page.getByTestId('album-detail-modal');
  93  |     await expect(modal).toHaveClass(/open/);
  94  |     await expect(page.locator('#detail-title')).not.toBeEmpty();
  95  |     await expect(page.locator('#detail-artist')).not.toBeEmpty();
  96  |     await expect(page.locator('#detail-price')).toContainText('$');
  97  | 
  98  |     // Close modal
  99  |     await page.getByTestId('close-detail').click();
  100 |     await expect(modal).not.toHaveClass(/open/);
  101 |   });
  102 | 
  103 |   test('add item to cart from album card', async ({ page }) => {
  104 |     const cards = page.getByTestId('album-card');
  105 |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  106 |     await cards.first().getByTestId('add-to-cart').click();
  107 | 
  108 |     // Cart badge updates
  109 |     const count = page.locator('#cart-count');
  110 |     await expect(count).toHaveText('1', { timeout: 5000 });
  111 |   });
  112 | 
  113 |   test('add item to cart from detail view', async ({ page }) => {
  114 |     const firstTitle = page.getByTestId('album-card').first().getByTestId('album-title');
  115 |     await expect(firstTitle).toBeVisible({ timeout: 10000 });
  116 |     await firstTitle.click();
  117 | 
  118 |     await expect(page.getByTestId('album-detail-modal')).toHaveClass(/open/);
  119 |     await page.getByTestId('detail-add-to-cart').click();
  120 | 
  121 |     // Modal closes and cart updates
  122 |     await expect(page.getByTestId('album-detail-modal')).not.toHaveClass(/open/);
  123 |     await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });
  124 |   });
  125 | 
  126 |   test('open cart panel and see items', async ({ page }) => {
  127 |     // Add an item first
  128 |     const cards = page.getByTestId('album-card');
  129 |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  130 |     await cards.first().getByTestId('add-to-cart').click();
  131 |     await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });
  132 | 
  133 |     // Open cart
  134 |     await page.getByTestId('cart-badge').click();
  135 |     const cartItems = page.getByTestId('cart-item');
  136 |     await expect(cartItems.first()).toBeVisible();
  137 |     await expect(page.getByTestId('cart-total')).toContainText('$');
  138 |   });
  139 | 
  140 |   test('remove item from cart', async ({ page }) => {
  141 |     // Add an item
  142 |     const cards = page.getByTestId('album-card');
  143 |     await expect(cards.first()).toBeVisible({ timeout: 10000 });
  144 |     await cards.first().getByTestId('add-to-cart').click();
  145 |     await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });
  146 | 
  147 |     // Open cart and remove
  148 |     await page.getByTestId('cart-badge').click();
  149 |     await page.getByTestId('remove-from-cart').first().click();
  150 |     await expect(page.getByTestId('empty-cart')).toBeVisible();
  151 |     await expect(page.locator('#cart-count')).toHaveText('0');
  152 |   });
```