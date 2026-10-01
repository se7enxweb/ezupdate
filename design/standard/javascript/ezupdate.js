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
        // Why the output cannot be followed, said on the page rather than
        // retried in silence: a run that looked frozen was often a session
        // that had ended, or a server error.
        var notice = document.getElementById('ezupdate-job-notice');
        var failures = 0;
        var maxFailures = 10;

        function say(kind, httpStatus) {
            if (!notice) { return; }
            if (!kind) { notice.hidden = true; notice.textContent = ''; return; }
            var text = pre.getAttribute('data-notice-' + kind) || kind;
            notice.textContent = text.replace('%status', httpStatus).replace('%count', maxFailures);
            notice.className = 'ezupdate-notice ' + (kind === 'server' || kind === 'noanswer' ? 'ezupdate-warn' : 'ezupdate-bad');
            notice.hidden = false;
        }

        // One failed poll: explained, and tried again unless it cannot get
        // better by waiting or has failed too often.
        function failed(kind, httpStatus) {
            failures++;
            if (kind === 'signedout' || kind === 'refused') { say(kind, httpStatus); return; }
            if (failures >= maxFailures) { say('gaveup', httpStatus); return; }
            say(kind, httpStatus);
            window.setTimeout(poll, Math.min(3000 * failures, 15000));
        }
        var classes = { running: 'ezupdate-warn ezupdate-running', finished: 'ezupdate-good', failed: 'ezupdate-bad', stopped: 'ezupdate-bad' };
        var follow = document.querySelector('[data-ezx-follow]');
        var elapsed = document.querySelector('[data-ezx-elapsed]');

        function atBottom() {
            return pre.scrollHeight - pre.scrollTop - pre.clientHeight < 40;
        }

        function poll() {
            var request = new XMLHttpRequest();
            request.open('GET', url, true);
            request.setRequestHeader('Accept', 'application/json');
            request.onload = function () {
                if (request.status === 403) { failed('refused', 403); return; }
                if (request.status >= 500) { failed('server', request.status); return; }
                var data = null;
                try { data = JSON.parse(request.responseText); } catch (e) { data = null; }
                if (!data) {
                    // HTML where JSON was asked for: the login page, when the
                    // session has ended; anything else is a server error.
                    var signedOut = /user\/login/.test(request.responseURL || '') || /name="Login"/.test(request.responseText);
                    failed(signedOut ? 'signedout' : 'server', request.status);
                    return;
                }
                failures = 0;
                say(null);
                if (data.bytes !== bytes) {
                    var keep = follow ? follow.checked : atBottom();
                    // Escaped on the server (eZUpdateManager::ansiToHtml) before any span is added.
                    pre.innerHTML = data.html;
                    bytes = data.bytes;
                    if (keep) { pre.scrollTop = pre.scrollHeight; }
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
                } else {
                    if (elapsed && data.finished) { elapsed.setAttribute('data-finished', data.finished); }
                    // The run has ended: its "run again" buttons may be used now.
                    var waiting = document.querySelectorAll('[data-ezupdate-when-done]');
                    Array.prototype.forEach.call(waiting, function (button) { button.disabled = false; });
                }
            };
            request.onerror = function () { failed('noanswer', 0); };
            request.send();
        }

        pre.scrollTop = pre.scrollHeight;
        poll();
    }

    // Installed packages (update/installed): the filter chips and cards, the search, the sortable columns and the
    // details of a row, all in the page.
    function installedPackages() {
        var root = document.querySelector('[data-ezupdate-installed]');
        if (!root) { return; }
        var rows = Array.prototype.slice.call(root.querySelectorAll('tbody.ezupdate-inv-row'));
        var table = root.querySelector('.ezupdate-inv-table');
        var empty = root.querySelector('.ezupdate-inv-empty');
        var count = root.querySelector('[data-count]');
        var search = root.querySelector('[data-search]');
        var filter = 'all', text = '', sortKey = 'name', sortDir = 1;
        var version = function (v) {
            return (v || '').replace(/^v/, '').split(/[.\-]/).map(function (p) { return /^\d+$/.test(p) ? ('0000000000' + p).slice(-10) : p; }).join('.');
        };
        var apply = function () {
            var shown = 0;
            rows.forEach(function (row) {
                var on = (' ' + row.getAttribute('data-filters') + ' ').indexOf(' ' + filter + ' ') !== -1
                    && (!text || row.getAttribute('data-text').indexOf(text) !== -1);
                row.hidden = !on;
                if (on) { shown++; }
            });
            if (count) { count.textContent = shown; }
            if (empty) { empty.hidden = shown !== 0; }
            Array.prototype.forEach.call(root.querySelectorAll('[data-filter]'), function (b) {
                var is = b.getAttribute('data-filter') === filter;
                b.classList.toggle('is-on', is);
                if (b.classList.contains('ezupdate-inv-chip')) { b.setAttribute('aria-pressed', is ? 'true' : 'false'); }
            });
        };
        var sort = function () {
            rows.sort(function (a, b) {
                var x = a.getAttribute('data-' + sortKey) || '', y = b.getAttribute('data-' + sortKey) || '';
                if (sortKey === 'issues') { x = +x; y = +y; return (x - y) * sortDir || a.getAttribute('data-name').localeCompare(b.getAttribute('data-name')); }
                if (sortKey === 'required' || sortKey === 'locked' || sortKey === 'installed') { x = version(x.replace(/^[~^>=<\s]+/, '')); y = version(y.replace(/^[~^>=<\s]+/, '')); }
                if (!x && y) { return 1; }
                if (x && !y) { return -1; }
                return x.localeCompare(y) * sortDir;
            });
            rows.forEach(function (row) { table.insertBefore(row, empty); });
            Array.prototype.forEach.call(root.querySelectorAll('[data-sort]'), function (b) {
                var th = b.parentNode;
                th.setAttribute('aria-sort', b.getAttribute('data-sort') === sortKey ? (sortDir > 0 ? 'ascending' : 'descending') : 'none');
            });
            if (sortSelect && sortSelect.querySelector('option[value="' + sortKey + '"]')) { sortSelect.value = sortKey; }
        };
        var sortSelect = root.querySelector('[data-sort-select]');
        if (sortSelect) {
            sortSelect.addEventListener('change', function () {
                sortKey = sortSelect.value;
                sortDir = sortKey === 'issues' ? -1 : 1;
                sort();
                save();
            });
        }
        // the filter, the search and the sort live in the address: #issues, #extension&q=tags&sort=issues
        var save = function () {
            var parts = [];
            if (filter !== 'all') { parts.push(filter); }
            if (text) { parts.push('q=' + encodeURIComponent(text)); }
            if (sortKey !== 'name') { parts.push('sort=' + sortKey); }
            if (window.history && history.replaceState) { history.replaceState(null, '', parts.length ? '#' + parts.join('&') : location.pathname + location.search); }
        };
        var load = function () {
            location.hash.replace(/^#/, '').split('&').forEach(function (part) {
                if (!part) { return; }
                if (part.indexOf('q=') === 0) { text = decodeURIComponent(part.slice(2)).toLowerCase(); if (search) { search.value = text; } }
                else if (part.indexOf('sort=') === 0) { sortKey = part.slice(5); sortDir = sortKey === 'issues' ? -1 : 1; }
                else if (root.querySelector('[data-filter="' + part + '"]')) { filter = part; }
            });
        };
        root.addEventListener('click', function (e) {
            var f = e.target.closest('[data-filter]');
            if (f) { filter = filter === f.getAttribute('data-filter') && filter !== 'all' ? 'all' : f.getAttribute('data-filter'); apply(); save(); return; }
            var s = e.target.closest('[data-sort]');
            if (s) {
                var key = s.getAttribute('data-sort');
                sortDir = key === sortKey ? -sortDir : (key === 'issues' ? -1 : 1);
                sortKey = key;
                sort();
                save();
                return;
            }
            var more = e.target.closest('.ezupdate-inv-more button');
            if (more) {
                var detail = document.getElementById(more.getAttribute('aria-controls'));
                var open = more.getAttribute('aria-expanded') !== 'true';
                more.setAttribute('aria-expanded', open ? 'true' : 'false');
                if (detail) { detail.hidden = !open; }
                more.closest('tbody').classList.toggle('is-open', open);
            }
        });
        if (search) {
            search.addEventListener('input', function () { text = search.value.trim().toLowerCase(); apply(); save(); });
            search.addEventListener('keydown', function (e) { if (e.key === 'Escape') { search.value = ''; text = ''; apply(); } });
        }
        load();
        sort();
        apply();
    }

    // ---- The redesigned pages (.ezx) ----

    function each(selector, fn, root) { Array.prototype.forEach.call((root || document).querySelectorAll(selector), fn); }

    // Messages that can be closed.
    function dismissables() {
        var close = function (alert) {
            if (alert.hidden) { return; }
            alert.classList.add('is-leaving');
            window.setTimeout(function () { alert.hidden = true; }, 350);
        };
        each('[data-ezx-dismiss]', function (alert) {
            var b = alert.querySelector('.ezx-dismiss');
            if (b) { b.addEventListener('click', function () { close(alert); }); }
            // a success message goes by itself; an error stays
            if (alert.classList.contains('ezx-alert-ok')) { window.setTimeout(function () { close(alert); }, 6000); }
        });
    }

    // A search box filtering a list: items with data-ezx-text inside the target; [data-ezx-none] shows when none match.
    function listFilters() {
        each('input[data-ezx-filter]', function (input) {
            var target = document.querySelector(input.getAttribute('data-ezx-filter'));
            if (!target) { return; }
            var none = document.querySelector('[data-ezx-none="' + input.getAttribute('data-ezx-filter') + '"]');
            var run = function () {
                var q = input.value.trim().toLowerCase(), shown = 0;
                each('[data-ezx-text]', function (item) {
                    var on = !q || item.getAttribute('data-ezx-text').indexOf(q) !== -1;
                    item.hidden = !on;
                    if (on) { shown++; }
                }, target);
                if (none) { none.hidden = shown !== 0; }
            };
            input.addEventListener('input', run);
            input.addEventListener('keydown', function (e) { if (e.key === 'Escape') { input.value = ''; run(); } });
        });
    }

    function copyText(text, button) {
        var done = function () {
            var label = button.textContent;
            button.textContent = button.getAttribute('data-done') || '✓';
            button.classList.add('is-done');
            window.setTimeout(function () { button.textContent = label; button.classList.remove('is-done'); }, 1400);
        };
        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(done, function () {});
            return;
        }
        var area = document.createElement('textarea');
        area.value = text; area.setAttribute('readonly', ''); area.style.position = 'fixed'; area.style.opacity = '0';
        document.body.appendChild(area); area.select();
        try { document.execCommand('copy'); done(); } catch (e) {}
        document.body.removeChild(area);
    }

    // Copy buttons: after code marked data-ezx-copy, and buttons naming an element to copy (the terminal).
    function copyButtons() {
        each('[data-ezx-copy]', function (code) {
            var b = document.createElement('button');
            b.type = 'button'; b.className = 'ezx-copy'; b.textContent = 'Copy'; b.setAttribute('aria-label', 'Copy ' + code.textContent);
            b.addEventListener('click', function () { copyText(code.textContent, b); });
            code.insertAdjacentElement('afterend', b);
        });
        each('[data-ezx-copy-target]', function (b) {
            b.addEventListener('click', function () {
                var el = document.getElementById(b.getAttribute('data-ezx-copy-target'));
                if (el) { copyText(el.textContent, b); }
            });
        });
    }

    // 1234567 -> "1.2M" (the full number in the title).
    function compactNumbers() {
        if (!window.Intl || !Intl.NumberFormat) { return; }
        var f;
        try { f = new Intl.NumberFormat(document.documentElement.lang || undefined, { notation: 'compact', maximumFractionDigits: 1 }); } catch (e) { return; }
        each('[data-ezx-num]', function (el) {
            var n = +el.getAttribute('data-ezx-num');
            if (isNaN(n)) { return; }
            el.title = n.toLocaleString();
            el.textContent = f.format(n);
        });
    }

    // A time as "3 days ago", the date it was in the title.
    function relativeTimes() {
        if (!window.Intl || !Intl.RelativeTimeFormat) { return; }
        var rtf = new Intl.RelativeTimeFormat(document.documentElement.lang || undefined, { numeric: 'auto' });
        var units = [['year', 31536000], ['month', 2592000], ['week', 604800], ['day', 86400], ['hour', 3600], ['minute', 60], ['second', 1]];
        each('[data-ezx-ago]', function (el) {
            var t = +el.getAttribute('data-ezx-ago');
            if (!t) { return; }
            var diff = t - Date.now() / 1000, abs = Math.abs(diff);
            for (var i = 0; i < units.length; i++) {
                if (abs >= units[i][1] || units[i][0] === 'second') {
                    el.title = el.textContent.trim();
                    el.textContent = rtf.format(Math.round(diff / units[i][1]), units[i][0]);
                    break;
                }
            }
        });
    }

    // How long a run took, counting while it runs.
    function elapsedTime() {
        var el = document.querySelector('[data-ezx-elapsed]');
        if (!el) { return; }
        var show = function () {
            var start = +el.getAttribute('data-started'), end = +el.getAttribute('data-finished') || Date.now() / 1000;
            if (!start) { return; }
            var s = Math.max(0, Math.round(end - start)), m = Math.floor(s / 60);
            el.textContent = m ? m + 'm ' + (s % 60) + 's' : s + 's';
            if (!el.getAttribute('data-finished')) { window.setTimeout(show, 1000); }
        };
        show();
    }

    // The terminal's switches.
    function terminals() {
        each('[data-ezx-term]', function (term) {
            var wrap = term.querySelector('[data-ezx-wrap]');
            if (wrap) { wrap.addEventListener('change', function () { term.classList.toggle('is-nowrap', !wrap.checked); }); }
        });
    }

    // "Releases only" in a package's versions.
    function stableOnly() {
        each('[data-ezx-stable-only]', function (box) {
            var panel = box.closest('[data-ezx-versions]');
            box.addEventListener('change', function () { each('tr[data-ezx-dev]', function (tr) { tr.hidden = box.checked; }, panel); });
        });
    }

    // Slow submits say so (the button keeps its name, so the action still arrives).
    function busyButtons() {
        each('[data-ezx-busy]', function (button) {
            if (!button.form) { return; }
            button.form.addEventListener('submit', function (e) {
                if (e.submitter && e.submitter !== button) { return; }
                window.setTimeout(function () { button.value = button.getAttribute('data-ezx-busy'); button.setAttribute('aria-busy', 'true'); button.style.opacity = '.7'; }, 0);
            });
        });
    }

    // "/" jumps to the page's search box.
    function slashToSearch() {
        document.addEventListener('keydown', function (e) {
            if (e.key !== '/' || e.ctrlKey || e.metaKey || e.altKey) { return; }
            var t = e.target;
            if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) { return; }
            var box = document.querySelector('.ezx [data-ezx-search], .ezx [data-search]');
            if (box) { e.preventDefault(); box.focus(); box.select && box.select(); }
        });
    }

    ready(function () {
        dismissables();
        listFilters();
        copyButtons();
        compactNumbers();
        relativeTimes();
        elapsedTime();
        terminals();
        stableOnly();
        busyButtons();
        slashToSearch();
        confirmBoxes();
        confirmForms();
        jobOutput();
        installedPackages();
    });
})();
