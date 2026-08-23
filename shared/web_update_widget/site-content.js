(function () {
  var script = document.currentScript;
  if (!script) return;

  var apiBase = script.dataset.apiBase || '';
  var siteId = script.dataset.siteId || '';
  var infoTarget = script.dataset.infoTarget || '[data-update-info]';
  var imageTarget = script.dataset.imageTarget || '[data-update-image]';

  if (!apiBase || !siteId) return;

  fetch(apiBase.replace(/\/$/, '') + '/public/sites/' + encodeURIComponent(siteId) + '/content')
    .then(function (response) {
      if (!response.ok) throw new Error('content fetch failed');
      return response.json();
    })
    .then(function (content) {
      var infoElement = document.querySelector(infoTarget);
      if (infoElement && typeof content.info === 'string') {
        infoElement.textContent = content.info;
        infoElement.style.whiteSpace = 'pre-line';
      }

      var imageElement = document.querySelector(imageTarget);
      if (imageElement && content.imageUrl) {
        if (imageElement.tagName.toLowerCase() === 'img') {
          imageElement.src = content.imageUrl;
        } else {
          imageElement.style.backgroundImage = 'url("' + content.imageUrl + '")';
        }
      }
    })
    .catch(function () {
      // Static fallback content remains visible if the update API is unavailable.
    });
})();
