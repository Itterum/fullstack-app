document.getElementById("show-modal").addEventListener("click", async () => {
  const response = await fetch("/api/message");
  const data = await response.json();

  const modal = document.getElementById("modal");
  modal.querySelector("p").textContent = data.message;
  modal.style.display = "block";
});

document.getElementById("close-modal").addEventListener("click", () => {
  document.getElementById("modal").style.display = "none";
});
