import { expect, test } from "@playwright/test";

test.describe("API Tests", () => {
  test("Check API response", async ({ request }) => {
    await test.step("Send request to API", async () => {
      const response = await request.get("http://localhost:3000/api/message");
      expect(response.status()).toBe(200);

      const data = await response.json();
      expect(data).toEqual({ message: "Hello, World!" });
    });
  });
});
