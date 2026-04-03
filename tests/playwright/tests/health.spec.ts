import { test, expect } from '@playwright/test';

test.describe('Health Check', () => {
  test('GET /health - should return healthy status', async ({ request }) => {
    const response = await request.get('/health');
    expect(response.status()).toBe(200);
  });
});
