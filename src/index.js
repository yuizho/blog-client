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
    rootPath: process.env.BLOG_ROOT_PATH,
    defaultTitle: process.env.BLOG_TITLE
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
  });
});
