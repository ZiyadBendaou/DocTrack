document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll("form.form-styled").forEach(form => {
    form.addEventListener("submit", (e) => {
      const buttons = form.querySelectorAll("button, input[type=submit]");
      buttons.forEach(btn => {
        btn.disabled = true;
        btn.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span> Saving...`;
      });
    });
  });
});
