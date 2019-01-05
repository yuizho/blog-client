require('./siimple.min.css');

const { Elm } = require('./Main.elm');

Elm.Main.init({
  node: document.getElementById('main')
});
