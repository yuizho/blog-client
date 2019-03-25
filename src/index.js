'use strict';

require('./main.scss');
import hljs from 'highlight.js';
// elm-explorations/markdown depends on windows.hljs.
// see https://github.com/elm-explorations/markdown#code-blocks
window.hljs = hljs

const { Elm } = require('./elm/Main.elm');
Elm.Main.init({
  node: document.getElementById('main'),
  flags: {
    hostName: process.env.BLOG_HOST_NAME,
    rootPath: process.env.BLOG_ROOT_PATH
  }
});
