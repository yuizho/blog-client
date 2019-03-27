'use strict';

require('./main.scss');
import hljs from 'highlight.js';
// elm-explorations/markdown depends on windows.hljs.
// see https://github.com/elm-explorations/markdown#code-blocks
window.hljs = hljs

const { Elm } = require('./elm/Main.elm');
const app = Elm.Main.init({
  node: document.getElementById('main'),
  flags: {
    hostName: process.env.BLOG_HOST_NAME,
    rootPath: process.env.BLOG_ROOT_PATH
  }
});

app.ports.addWidgets.subscribe(function() {
  // https://qiita.com/arowM/items/ff98bce79a7080cbb38a
  // this function is called, afeter view renderring
  requestAnimationFrame(function() {
    let widgets = document.querySelector("#widgets");

    // twitter widget
    let twitterWidget = document.createElement('span');
    let twitterA = document.createElement('a');
    twitterA.setAttribute("href", "https://twitter.com/share?ref_src=twsrc%5Etfw")
    twitterA.setAttribute("class", "twitter-share-button")
    twitterA.setAttribute("data-show-count", "false")
    twitterA.textContent = "Tweet"
    let twitterScript = document.createElement('script');
    twitterScript.setAttribute("async", "")
    twitterScript.setAttribute("src", "https://platform.twitter.com/widgets.js")
    twitterScript.setAttribute("charset", "utf-8")
    twitterWidget.appendChild(twitterA);
    twitterWidget.appendChild(twitterScript);
    widgets.appendChild(twitterWidget);

    // hatena bookmark widget
    let hatenaWidget = document.createElement('span');
    hatenaWidget.setAttribute("style", "margin-left: 5px;");
    let hatenaA = document.createElement('a');
    hatenaA.setAttribute("href", "http://b.hatena.ne.jp/entry/");
    hatenaA.setAttribute("class", "hatena-bookmark-button");
    hatenaA.setAttribute("data-hatena-bookmark-layout", "basic-counter");
    let hatenaImg = document.createElement('img');
    hatenaImg.setAttribute("src", "https://b.st-hatena.com/images/v4/public/entry-button/button-only@2x.png");
    hatenaImg.setAttribute("width", "20");
    hatenaImg.setAttribute("height", "20");
    hatenaImg.setAttribute("style", "border: none;");
    hatenaA.appendChild(hatenaImg);
    let hatenaScript = document.createElement('script');
    hatenaScript.setAttribute("async", "async")
    hatenaScript.setAttribute("src", "https://b.st-hatena.com/js/bookmark_button.js")
    hatenaScript.setAttribute("charset", "utf-8")
    hatenaWidget.appendChild(hatenaA);
    hatenaWidget.appendChild(hatenaScript);
    widgets.appendChild(hatenaWidget);
  });
});
