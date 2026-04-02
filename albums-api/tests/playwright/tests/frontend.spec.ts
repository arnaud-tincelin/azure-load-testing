import { test, expect } from '@playwright/test';

const API_BASE = process.env.SERVICE_ALBUMS_API_ENDPOINT_URL || 'http://localhost:5080';
const FRONTEND_URL = process.env.SERVICE_ALBUMS_FRONTEND_ENDPOINT_URL || 'http://localhost:8080';

test.describe('Album Marketplace - Browser Tests', () => {
  test.beforeEach(async ({ page }) => {    // Inject API_BASE for local dev (in production, nginx proxies /albums and /cart)
    await page.addInitScript((apiBase) => {
      (window as any).__API_BASE__ = apiBase;
    }, FRONTEND_URL === API_BASE ? '' : API_BASE);    await page.goto(FRONTEND_URL);
  });

  test('homepage loads with albums displayed', async ({ page }) => {
    await expect(page).toHaveTitle('Album Marketplace');
    const grid = page.getByTestId('album-grid');
    await expect(grid).toBeVisible();
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    expect(await cards.count()).toBeGreaterThan(0);
  });

  test('album cards show title, artist, genre, and price', async ({ page }) => {
    const card = page.getByTestId('album-card').first();
    await expect(card).toBeVisible({ timeout: 10000 });
    await expect(card.getByTestId('album-title')).not.toBeEmpty();
    await expect(card.getByTestId('album-artist')).not.toBeEmpty();
    await expect(card.getByTestId('album-genre')).not.toBeEmpty();
    await expect(card.getByTestId('album-price')).toContainText('$');
  });

  test('filter albums by genre', async ({ page }) => {
    const genreFilter = page.getByTestId('genre-filter');
    await expect(genreFilter).toBeVisible();

    // Wait for genres to load
    await page.waitForFunction(() => {
      const select = document.querySelector('[data-testid="genre-filter"]') as HTMLSelectElement;
      return select && select.options.length > 1;
    });

    // Select a genre
    const options = await genreFilter.locator('option').allTextContents();
    const genre = options.find(o => o !== 'All Genres')!;
    await genreFilter.selectOption({ label: genre });
    await page.getByTestId('apply-filters').click();

    // Verify filtered results
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    const genres = await cards.getByTestId('album-genre').allTextContents();
    for (const g of genres) {
      expect(g.toLowerCase()).toContain(genre.toLowerCase());
    }
  });

  test('filter albums by max price', async ({ page }) => {
    await page.getByTestId('price-filter').fill('15');
    await page.getByTestId('apply-filters').click();

    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    const prices = await cards.getByTestId('album-price').allTextContents();
    for (const p of prices) {
      const value = parseFloat(p.replace('$', ''));
      expect(value).toBeLessThanOrEqual(15);
    }
  });

  test('clear filters restores all albums', async ({ page }) => {
    // Get initial count
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    const initialCount = await cards.count();

    // Apply a restrictive filter
    await page.getByTestId('price-filter').fill('5');
    await page.getByTestId('apply-filters').click();
    await page.waitForTimeout(500);

    // Clear filters
    await page.getByTestId('clear-filters').click();
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    const restoredCount = await cards.count();
    expect(restoredCount).toBe(initialCount);
  });

  test('view album detail', async ({ page }) => {
    const firstTitle = page.getByTestId('album-card').first().getByTestId('album-title');
    await expect(firstTitle).toBeVisible({ timeout: 10000 });
    await firstTitle.click();

    const modal = page.getByTestId('album-detail-modal');
    await expect(modal).toHaveClass(/open/);
    await expect(page.locator('#detail-title')).not.toBeEmpty();
    await expect(page.locator('#detail-artist')).not.toBeEmpty();
    await expect(page.locator('#detail-price')).toContainText('$');

    // Close modal
    await page.getByTestId('close-detail').click();
    await expect(modal).not.toHaveClass(/open/);
  });

  test('add item to cart from album card', async ({ page }) => {
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    await cards.first().getByTestId('add-to-cart').click();

    // Cart badge updates
    const count = page.locator('#cart-count');
    await expect(count).toHaveText('1', { timeout: 5000 });
  });

  test('add item to cart from detail view', async ({ page }) => {
    const firstTitle = page.getByTestId('album-card').first().getByTestId('album-title');
    await expect(firstTitle).toBeVisible({ timeout: 10000 });
    await firstTitle.click();

    await expect(page.getByTestId('album-detail-modal')).toHaveClass(/open/);
    await page.getByTestId('detail-add-to-cart').click();

    // Modal closes and cart updates
    await expect(page.getByTestId('album-detail-modal')).not.toHaveClass(/open/);
    await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });
  });

  test('open cart panel and see items', async ({ page }) => {
    // Add an item first
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    await cards.first().getByTestId('add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });

    // Open cart
    await page.getByTestId('cart-badge').click();
    const cartItems = page.getByTestId('cart-item');
    await expect(cartItems.first()).toBeVisible();
    await expect(page.getByTestId('cart-total')).toContainText('$');
  });

  test('remove item from cart', async ({ page }) => {
    // Add an item
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    await cards.first().getByTestId('add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });

    // Open cart and remove
    await page.getByTestId('cart-badge').click();
    await page.getByTestId('remove-from-cart').first().click();
    await expect(page.getByTestId('empty-cart')).toBeVisible();
    await expect(page.locator('#cart-count')).toHaveText('0');
  });

  test('clear entire cart', async ({ page }) => {
    // Add two items
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    await cards.nth(0).getByTestId('add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });
    await cards.nth(1).getByTestId('add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('2', { timeout: 5000 });

    // Open cart and clear
    await page.getByTestId('cart-badge').click();
    await page.getByTestId('clear-cart').click();
    await expect(page.getByTestId('empty-cart')).toBeVisible();
    await expect(page.locator('#cart-count')).toHaveText('0');
  });

  test('full shopping journey: browse → filter → detail → cart → clear', async ({ page }) => {
    // Browse albums
    const cards = page.getByTestId('album-card');
    await expect(cards.first()).toBeVisible({ timeout: 10000 });

    // Filter by genre
    await page.waitForFunction(() => {
      const select = document.querySelector('[data-testid="genre-filter"]') as HTMLSelectElement;
      return select && select.options.length > 1;
    });
    const genreFilter = page.getByTestId('genre-filter');
    const options = await genreFilter.locator('option').allTextContents();
    const genre = options.find(o => o !== 'All Genres')!;
    await genreFilter.selectOption({ label: genre });
    await page.getByTestId('apply-filters').click();
    await expect(cards.first()).toBeVisible({ timeout: 10000 });

    // View detail
    await cards.first().getByTestId('album-title').click();
    await expect(page.getByTestId('album-detail-modal')).toHaveClass(/open/);
    const albumTitle = await page.locator('#detail-title').textContent();

    // Add from detail
    await page.getByTestId('detail-add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('1', { timeout: 5000 });

    // Clear filters and add another
    await page.getByTestId('clear-filters').click();
    await expect(cards.first()).toBeVisible({ timeout: 10000 });
    await cards.first().getByTestId('add-to-cart').click();
    await expect(page.locator('#cart-count')).toHaveText('2', { timeout: 5000 });

    // Open cart, verify items, clear
    await page.getByTestId('cart-badge').click();
    const cartItemCount = await page.getByTestId('cart-item').count();
    expect(cartItemCount).toBe(2);
    await expect(page.getByTestId('cart-total')).toContainText('$');

    // Take a screenshot for visual evidence
    await page.screenshot({ path: 'test-results/cart-with-items.png' });

    await page.getByTestId('clear-cart').click();
    await expect(page.getByTestId('empty-cart')).toBeVisible();
  });
});
