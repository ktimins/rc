// ==UserScript==
// @name         ShoeGazing - Remove Sidebar
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://shoegazing.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=shoegazing.com
// @grant        none
// ==/UserScript==

(function() {
    if(window.location.href.includes("shoegazing.com")) {
        setInterval(function() {
            try {
                document.querySelector('.post-sidebar').remove();
                console.log("Removed post sidebar");
            } catch(e) {}
            try {
                document.querySelector('.sidebar').remove();
                console.log("Removed sidebar");
            } catch(e) {}
        });
    }
})();
