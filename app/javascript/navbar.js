document.addEventListener("turbo:load", () => {
  const navbarCollapse = document.getElementById("mainNavbar");
  const bsCollapse =
    bootstrap.Collapse.getInstance(navbarCollapse) ||
    new bootstrap.Collapse(navbarCollapse, { toggle: false });

  const isMobile = () => window.innerWidth < 992;

  function closeMenu() {
    if (navbarCollapse.classList.contains("show") && isMobile()) {
      bsCollapse.hide();
    }
  }

  function smoothScrollTo(targetId) {
    const target = document.getElementById(targetId);
    if (target) {
      const offset = 70;
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: "smooth" });
    }
  }

  // Gestione scroll su link con href="#..." o href="/#..."
  document.querySelectorAll('a[href^="#"], a[href^="/#"]').forEach(link => {
    link.addEventListener("click", e => {
      const href = link.getAttribute("href");
      const targetId = href.split("#")[1];

      if (targetId && window.location.pathname === "/") {
        e.preventDefault();
        smoothScrollTo(targetId);
        closeMenu();
      } else if (targetId && !window.location.pathname.startsWith("/#")) {
        // Naviga normalmente verso root_path con anchor
        link.setAttribute("href", `/${"#" + targetId}`);
      }
    });
  });

  // Chiudi menu su click dropdown
  document.querySelectorAll(".dropdown-item").forEach(item => {
    item.addEventListener("click", closeMenu);
  });

  // Rimuove la classe animazione al termine (logo)
  const hoverText = document.querySelector(".hover-text.animate-on-load");
  if (hoverText) {
    hoverText.addEventListener("animationend", () => {
      hoverText.classList.remove("animate-on-load");
    });
  }
});
