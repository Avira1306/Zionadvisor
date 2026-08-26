// Zion Advisor — minimal progressive enhancement
(function () {
    'use strict';

    // Mobile navigation toggle
    var toggle = document.querySelector('.nav-toggle');
    var nav = document.querySelector('nav.site-nav');
    if (toggle && nav) {
        toggle.addEventListener('click', function () {
            var open = nav.classList.toggle('open');
            toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
        });
    }

    // Current year in footer copyright
    document.querySelectorAll('.js-year').forEach(function (el) {
        el.textContent = new Date().getFullYear();
    });

    // Reading progress bar on article pages
    var progress = document.querySelector('.reading-progress');
    if (progress) {
        var update = function () {
            var doc = document.documentElement;
            var max = doc.scrollHeight - window.innerHeight;
            progress.style.width = (max > 0 ? (window.scrollY / max) * 100 : 0) + '%';
        };
        window.addEventListener('scroll', update, { passive: true });
        update();
    }

    // Contact / intake forms: client-side acknowledgement only (no backend yet)
    var forms = document.querySelectorAll('form[data-static-form]');
    forms.forEach(function (form) {
        form.addEventListener('submit', function (e) {
            e.preventDefault();
            var status = form.querySelector('.form-status');
            if (!status) return;
            status.textContent = 'Thank you — your message has been noted. We respond within 1 business day. For secure file sharing we will follow up by email.';
            status.hidden = false;
            form.reset();
        });
    });
})();
