import { defineConfig } from '@playwright/test';
import { createAzurePlaywrightConfig } from '@azure/playwright';
import { DefaultAzureCredential } from '@azure/identity';
import dotenv from 'dotenv';

dotenv.config();

const baseURL = process.env.SERVICE_ALBUMS_API_ENDPOINT_URL || 'http://localhost:5080';

const baseConfig = {
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: true,
  retries: 2,
  workers: 20,
  reporter: [
    ['html', { open: 'never' }],
    ['@azure/playwright/reporter'],
  ],
  use: {
    baseURL,
    extraHTTPHeaders: {
      'Content-Type': 'application/json',
    },
    trace: 'on-first-retry',
    video: 'retain-on-failure',
    screenshot: 'on',
  },
  projects: [
    {
      name: 'api',
      testMatch: ['albums.spec.ts', 'cart.spec.ts', 'e2e-journey.spec.ts', 'health.spec.ts'],
    },
    {
      name: 'chromium',
      testMatch: 'frontend.spec.ts',
      use: { browserName: 'chromium' as const },
    },
    {
      name: 'firefox',
      testMatch: 'frontend.spec.ts',
      use: { browserName: 'firefox' as const },
    },
    {
      name: 'webkit',
      testMatch: 'frontend.spec.ts',
      use: { browserName: 'webkit' as const },
    },
  ],
};

export default defineConfig(
  baseConfig,
  createAzurePlaywrightConfig(baseConfig, {
    credential: new DefaultAzureCredential(),
    connectTimeout: 30000,
    useCloudHostedBrowsers: true,
  }),
);
