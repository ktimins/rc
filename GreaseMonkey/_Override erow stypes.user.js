// ==UserScript==
// @name         _Override erow stypes
// @namespace    https://portal.insurity.com/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://portal.insurity.com/itg/*
// @grant        none
// @run-at     document-start
// ==/UserScript==

(function addGlobalStyle(css) {
   var head, style;
   head = document.getElementsByTagName('head')[0];
   if (!head) { return; }
   style = document.createElement('style');
   style.type = 'text/css';
   style.innerHTML = css;
   head.appendChild(style);
})('.erow { background: #B3B3CC !important; }');
