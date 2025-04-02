import { expect, test } from "@playwright/test";

test.describe("UI Tests", () => {
  test("Modal opens and closes correctly", async ({ page }) => {
    await test.step("Open the client page", async () => {
      await page.goto("http://localhost:4173");
    });

    await test.step("Click the button to open modal", async () => {
      await page.click("#show-modal");
    });

    await test.step("Check if modal appears with correct text", async () => {
      const modal = page.locator("#modal");
      await expect(modal).toBeVisible();
      await expect(modal.locator("p")).toHaveText("Hello, World!");
    });

    await test.step("Click OK to close modal", async () => {
      await page.click("#close-modal");
    });

    await test.step("Ensure modal disappears", async () => {
      const modal = page.locator("#modal");
      await expect(modal).not.toBeVisible();
    });
  });
});
