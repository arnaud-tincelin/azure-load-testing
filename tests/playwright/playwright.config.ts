import { defineConfig } from '@playwright/test';
import dotenv from 'dotenv';

dotenv.config();

const baseURL = process.env.SERVICE_ALBUMS_API_ENDPOINT_URL || 'http://localhost:5080';

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  reporter: [['html'], ['list']],
  use: {
    baseURL,
    extraHTTPHeaders: {
      'Content-Type': 'application/json',
    },
    trace: 'on-first-retry',
    video:'retain-on-failure',
    screenshot: 'on',
  },
  projects: [
    {
      name: 'api',
      testMatch: ['albums.spec.ts', 'cart.spec.ts', 'e2e-journey.spec.ts', 'health.spec.ts'],
      use: { browserName: 'chromium' },
    },
    {
      name: 'chromium',
      testMatch: 'frontend.spec.ts',
      use: { browserName: 'chromium' },
    },
  ],
});
