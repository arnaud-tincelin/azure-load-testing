# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: e2e-journey.spec.ts >> Albums API - End-to-End User Journey >> complete shopping flow: browse → add to cart → review → clear
- Location: tests/e2e-journey.spec.ts:6:7

# Error details

```
Error: apiRequestContext.get: connect ECONNREFUSED ::1:5080
Call log:
  - → GET http://localhost:5080/albums
    - user-agent: Playwright/1.59.0 (x64; debian 12) node/24.14
    - accept: */*
    - accept-encoding: gzip,deflate,br
    - Content-Type: application/json

```