document.addEventListener("DOMContentLoaded", () => {
  const carousels = document.querySelectorAll(".carousel");

  carousels.forEach((carousel) => {
    const track = carousel.querySelector(".carousel__track");
    const items = Array.from(carousel.querySelectorAll(".carousel__item"));
    const dotsWrap = carousel.querySelector(".carousel__dots");
    const prevBtn = carousel.querySelector(".carousel__button--prev");
    const nextBtn = carousel.querySelector(".carousel__button--next");

    if (!track || items.length === 0 || !dotsWrap) return;

    let currentIndex = 0;

    const dots = items.map((_, index) => {
      const dot = document.createElement("button");
      dot.type = "button";
      dot.className = "carousel__dot";
      dot.setAttribute("aria-label", `${index + 1}枚目へ`);
      dot.addEventListener("click", () => scrollToIndex(index));
      dotsWrap.appendChild(dot);
      return dot;
    });

    function getItemScrollLeft(index) {
      return items[index].offsetLeft - track.offsetLeft;
    }

    function scrollToIndex(index) {
      const safeIndex = Math.max(0, Math.min(index, items.length - 1));
      track.scrollTo({
        left: getItemScrollLeft(safeIndex),
        behavior: "smooth",
      });
      currentIndex = safeIndex;
      updateUI();
    }

    function updateUI() {
      dots.forEach((dot, index) => {
        dot.classList.toggle("is-active", index === currentIndex);
      });

      if (prevBtn) prevBtn.disabled = currentIndex === 0;
      if (nextBtn) nextBtn.disabled = currentIndex === items.length - 1;
    }

    function detectCurrentIndex() {
      const trackCenter = track.scrollLeft + track.clientWidth / 2;

      let nearestIndex = 0;
      let nearestDistance = Infinity;

      items.forEach((item, index) => {
        const itemCenter =
          item.offsetLeft - track.offsetLeft + item.clientWidth / 2;
        const distance = Math.abs(trackCenter - itemCenter);

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestIndex = index;
        }
      });

      currentIndex = nearestIndex;
      updateUI();
    }

    if (prevBtn) {
      prevBtn.addEventListener("click", () => {
        scrollToIndex(currentIndex - 1);
      });
    }

    if (nextBtn) {
      nextBtn.addEventListener("click", () => {
        scrollToIndex(currentIndex + 1);
      });
    }

    let scrollTimer = null;
    track.addEventListener("scroll", () => {
      window.clearTimeout(scrollTimer);
      scrollTimer = window.setTimeout(detectCurrentIndex, 80);
    });

    window.addEventListener("resize", () => {
      scrollToIndex(currentIndex);
    });

    updateUI();
  });
});