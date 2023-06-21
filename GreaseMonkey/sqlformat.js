// ==UserScript==
// @name         sqlformat
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       You
// @match        https://www.dpriver.com/pp/sqlformat.htm
// @icon         https://www.google.com/s2/favicons?sz=64&domain=dpriver.com
// @grant        none
// ==/UserScript==

(function() {
    if(window.location.href.includes("dpriver.com/pp/sqlformat")) {
        setInterval(function() {
            try {
                document.querySelector('select[name="tablenamecs"]').value = "Unchanged";
                document.querySelector('select[name="columnnamecs"]').value = "Unchanged"
                document.querySelector('input[name="lnbrwithcomma"][value="before"]').checked = true;
                document.querySelector('input[name="salign"][value="sright"]').checked = true;
                document.querySelector('input[name="andorunderwhere"]').checked = true;
                console.log("Set default values fro Instant SQL Formatter.");
            } catch (e) {}
        });
    }
    // Your code here...
})();
