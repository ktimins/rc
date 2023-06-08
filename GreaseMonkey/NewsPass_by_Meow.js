// ==UserScript==
// @name         News Pass
// @namespace    http://tampermonkey.net/
// @version      0.4
// @description  Removes "you can't continue reading" popups on news articles.
// @author       Meow
// @match        https://*.telegraph.co.uk/*
// @grant        none
// ==/UserScript==

(function() {
    if(window.location.href.includes("telegraph.co.uk")) {
        setInterval(function() {
            try {
                let st = document.createElement('style');
                st.innerHTML = ".martech-overlay-not-visible {overflow-y: visible !important}";
                document.head.appendChild(st);
                document.querySelector('.martech-modal-component-overlay').remove();
                console.log("Removed paywall");
            } catch(e) {}
            try {
                document.querySelector('.martech-general-sticky-footer__wrapper').remove();
            } catch (e) {}
            try {
                document.querySelector('.martech-general-sticky-footer__content').remove();
            } catch(e) {}
            try {
                document.querySelector('.tpl-article__sidebar').remove();
            } catch(e) {}
        })
    }
})()

//https://greasyfork.org/en/scripts/402153-news-pass
