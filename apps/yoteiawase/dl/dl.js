/* 📌 apps/yoteiawase/dl/dl.js */
/* 📄 共有用URLの振り分け処理。端末を判定して <html> に状態を書き込み、
      条件がそろっていればストアへ自動遷移する。
      設定値は app-links.js 側にあるので、通常このファイルは編集しない。 */

(function () {
  var config = window.YOTEIAWASE_APP_LINKS || {};
  var ios = config.ios || {};
  var android = config.android || {};
  var root = document.documentElement;

  /* 🌷 #10 端末判定 */
  /* 🍀 iPadOS 13以降は Macintosh を名乗るため、タッチ点数でiPadを拾う。 */
  function detectPlatform() {
    var ua = window.navigator.userAgent || "";
    if (/iPhone|iPad|iPod/i.test(ua)) return "ios";
    if (/Macintosh/.test(ua) && window.navigator.maxTouchPoints > 1) return "ios";
    if (/Android/i.test(ua)) return "android";
    return "other";
  }

  /* 🌷 #20 状態の反映 */
  /* 🍀 公開状態はURLが入っているときだけ「公開済み」として扱う。
        released を true にしたのにURL未入力、という事故で
        リンク切れのボタンを出さないための保険。 */
  function isLive(entry) {
    return Boolean(entry && entry.released && entry.storeUrl);
  }

  var platform = detectPlatform();
  var iosLive = isLive(ios);
  var androidLive = isLive(android);

  root.setAttribute("data-platform", platform);
  root.setAttribute("data-ios", iosLive ? "released" : "coming");
  root.setAttribute("data-android", androidLive ? "released" : "coming");

  /* 🌷 #30 ストアリンクの流し込み */
  /* 🍀 このファイルは <head> で読み込む（表示のちらつきを防ぐため）ので、
        本文の要素を触る処理だけ DOM の準備完了まで待つ。 */
  function applyStoreLinks() {
    function applyUrl(selector, url) {
      var links = document.querySelectorAll(selector);
      for (var i = 0; i < links.length; i += 1) {
        links[i].setAttribute("href", url);
      }
    }
    if (iosLive) applyUrl("[data-store-link='ios']", ios.storeUrl);
    if (androidLive) applyUrl("[data-store-link='android']", android.storeUrl);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", applyStoreLinks);
  } else {
    applyStoreLinks();
  }

  /* 🌷 #40 自動遷移 */
  /* 🍀 その端末向けのストアが公開済みのときだけ飛ばす。
        未公開なら遷移せず、このページの案内表示のままにする。 */
  if (config.autoRedirect === false) return;

  var target = "";
  if (platform === "ios" && iosLive) target = ios.storeUrl;
  if (platform === "android" && androidLive) target = android.storeUrl;

  if (target) {
    root.setAttribute("data-redirecting", "true");
    window.location.replace(target);
  }
})();
