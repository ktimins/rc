// ==UserScript==
// @name         YouTube - hide "Ask" AI button
// @namespace    kyle.userscripts
// @version      1.0.0
// @description  Hides (or removes) YouTube's AI "Ask" entrypoint in the watch page action row
// @match        https://www.youtube.com/*
// @run-at       document-start
// @grant        none
// @noframes
// ==/UserScript==

(() => {
  'use strict';

  // true  = CSS hide. Recommended: idempotent, zero per-mutation cost, and it
  //         can't fight YouTube's renderer.
  // false = actually detach the node, re-checking on DOM mutations.
  const HIDE_WITH_CSS = true;

  // Primary match: the internal class YouTube stamps on the entrypoint's
  // <button-view-model>. Language-independent, and the Save/Share/Download
  // siblings don't have it.
  // Fallback match: aria-label, in case that class gets renamed. English UI only.
  const SELECTOR = [
    'yt-button-view-model:has(button-view-model.you-chat-entrypoint-button)',
    'yt-button-view-model:has(button[aria-label="Ask"])',
  ].join(',');

  if (HIDE_WITH_CSS) {
    const style = document.createElement('style');
    style.textContent = `${SELECTOR} { display: none !important; }`;
    // document.head does not exist yet at document-start.
    (document.head || document.documentElement).append(style);
    return;
  }

  let queued = false;

  const purge = () => {
    queued = false;
    for (const el of document.querySelectorAll(SELECTOR)) el.remove();
  };

  const schedule = () => {
    if (queued) return;
    queued = true;
    requestAnimationFrame(purge);
  };

  new MutationObserver(schedule).observe(document.documentElement, {
    childList: true,
    subtree: true,
  });

  schedule();
})();