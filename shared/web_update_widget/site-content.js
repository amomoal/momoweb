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
        var aspectWidth = content.imageAspectWidth || 16;
        var aspectHeight = content.imageAspectHeight || 9;
        var cropScale = content.imageCropScale || 1;
        var cropOffsetX = content.imageCropOffsetX || 0;
        var cropOffsetY = content.imageCropOffsetY || 0;
        var frameElement = imageElement.parentElement;
        if (frameElement) {
          frameElement.style.aspectRatio = aspectWidth + ' / ' + aspectHeight;
          frameElement.style.overflow = 'hidden';
        }
        if (imageElement.tagName.toLowerCase() === 'img') {
          imageElement.src = content.imageUrl;
          imageElement.style.width = '100%';
          imageElement.style.height = '100%';
          imageElement.style.objectFit = 'cover';
          imageElement.style.transformOrigin = 'center center';
          imageElement.style.transform = 'translate(' + cropOffsetX + '%, ' + cropOffsetY + '%) scale(' + cropScale + ')';
        } else {
          imageElement.style.backgroundImage = 'url("' + content.imageUrl + '")';
          imageElement.style.backgroundSize = (cropScale * 100) + '%';
          imageElement.style.backgroundPosition = (50 + cropOffsetX) + '% ' + (50 + cropOffsetY) + '%';
        }
      }
    })
    .catch(function () {
      // Static fallback content remains visible if the update API is unavailable.
    });
})();
