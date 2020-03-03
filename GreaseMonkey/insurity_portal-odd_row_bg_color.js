// ==UserScript==
// @name       _Override erow standardHeight stypes
// @include    https://portal.insurity.com/itg/*
// @grant      GM_addStype
// @run-at     document-start
// ==/UserScript ==

function addGlobalStyle(css) {
   var head, style;
   head = document.getElementsByTagName('head')[0];
   if (!head) { return; }
   style = document.createElement('style');
   style.type = 'text/css';
   style.innerHTML = css;
   head.appendChild(style);
}

addGlobalStyle('.erow { background: #B3B3CC !important; }');
