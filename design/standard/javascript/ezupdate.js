/*
 * ezupdate: the live output of a Composer run, and the small guards of the forms.
 * Plain JavaScript, no library; each part does nothing on a page without its markup.
 */
(function () {
    'use strict';

    function ready(fn) {
        if (document.readyState !== 'loading') { fn(); } else { document.addEventListener('DOMContentLoaded', fn); }
    }

    // A button stays disabled until its confirmation box is ticked.
    function confirmBoxes() {
        var boxes = document.querySelectorAll('input[data-ezupdate-enables]');
        Array.prototype.forEach.call(boxes, function (box) {
            var button = box.form ? box.form.querySelector('[name="' + box.getAttribute('data-ezupdate-enables') + '"]') : null;
            if (!button) { return; }
            var sync = function () { button.disabled = !box.checked; };
            box.addEventListener('change', sync);
            sync();
        });
    }

    // Forms that change something ask first.
    function confirmForms() {
        var forms = document.querySelectorAll('form[data-ezupdate-confirm]');
        Array.prototype.forEach.call(forms, function (form) {
            form.addEventListener('submit', function (event) {
                if (!window.confirm(form.getAttribute('data-ezupdate-confirm'))) { event.preventDefault(); }
            });
        });
    }

    // The output of a background run, fetched until the run has ended.
    function jobOutput() {
        var pre = document.getElementById('ezupdate-job-output');
        if (!pre || pre.getAttribute('data-ezupdate-done') === '1') { return; }
        var url = pre.getAttribute('data-ezupdate-job');
        var status = document.getElementById('ezupdate-job-status');
        var bytes = -1;
        var classes = { running: 'ezupdate-warn', finished: 'ezupdate-good', failed: 'ezupdate-bad', stopped: 'ezupdate-bad' };

        function atBottom() {
            return pre.scrollHeight - pre.scrollTop - pre.clientHeight < 40;
        }

        function poll() {
            var request = new XMLHttpRequest();
            request.open('GET', url, true);
            request.setRequestHeader('Accept', 'application/json');
            request.onload = function () {
                var data = null;
                try { data = JSON.parse(request.responseText); } catch (e) { data = null; }
                if (!data) { window.setTimeout(poll, 3000); return; }
                if (data.bytes !== bytes) {
                    var follow = atBottom();
                    // Escaped on the server (eZUpdateManager::ansiToHtml) before any span is added.
                    pre.innerHTML = data.html;
                    bytes = data.bytes;
                    if (follow) { pre.scrollTop = pre.scrollHeight; }
                }
                if (status && classes[data.status]) {
                    var label = pre.getAttribute('data-status-' + data.status) || data.status;
                    status.innerHTML = '';
                    var badge = document.createElement('span');
                    badge.className = 'ezupdate-badge ' + classes[data.status];
                    badge.textContent = label;
                    status.appendChild(badge);
                }
                if (data.status === 'queued' || data.status === 'running') {
                    window.setTimeout(poll, 1000);
                }
            };
            request.onerror = function () { window.setTimeout(poll, 3000); };
            request.send();
        }

        pre.scrollTop = pre.scrollHeight;
        poll();
    }

    ready(function () {
        confirmBoxes();
        confirmForms();
        jobOutput();
    });
})();
