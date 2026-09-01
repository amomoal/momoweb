/* 📌 apps/yoteiawase/dl/app-links.js */
/* 📄 共有用URL（/apps/yoteiawase/dl/）の唯一の設定ファイル。
      ストアURLと公開状態はこのファイルだけを書き換えれば切り替わる。
      HTML・CSS・dl.js は触らなくてよい。 */

window.YOTEIAWASE_APP_LINKS = {
  /* 🍀 iOS版
        released : App Store 公開後に true にする
        storeUrl : App Store の URL（例: "https://apps.apple.com/jp/app/id0000000000"）
        released を true にして storeUrl を入れると、
        ・iOS端末 → 自動で App Store へ遷移
        ・その他の端末 → 「iOS版をダウンロード」ボタン表示
        になる。 */
  ios: {
    released: false,
    storeUrl: ""
  },

  /* 🍀 Android版
        公開するまでは released:false のままにする（ストアへは飛ばさず案内文だけ出る）。
        公開時は released:true + storeUrl を入れるだけで、
        アプリを更新しなくても Android からのアクセスがストアへ流れる。 */
  android: {
    released: false,
    storeUrl: ""
  },

  /* 🍀 対応端末で自動遷移させるかどうか。
        false にすると自動遷移せず、ボタンを押したときだけストアへ飛ぶ。 */
  autoRedirect: true
};
