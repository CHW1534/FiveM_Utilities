// ══════════════════════════════════════════════════════════════════
//  respawn_menu / html / admin_panel.js
//  Admin panel UI logic: tabs, player lists, grant/revoke, search
// ══════════════════════════════════════════════════════════════════

'use strict';

// ── PANEL STATE ────────────────────────────────────────────────────
const ap = {
    online:    [],
    persisted: [],
};

// ── HELPERS ────────────────────────────────────────────────────────
function apEsc(str) {
    return String(str || '')
        .replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function apInitials(name) {
    return String(name || '?').slice(0, 2).toUpperCase();
}

function apFetch(route, body) {
    fetch(`https://${RESOURCE_NAME}/${route}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {})
    });
}

// ── OPEN PANEL ─────────────────────────────────────────────────────
function openAdminPanel(data) {
    ap.online    = data.online    || [];
    ap.persisted = data.persisted || [];

    const overlay = document.getElementById('admin-panel-overlay');
    if (overlay) overlay.classList.remove('ap-hidden');

    renderOnlineList(ap.online);
    renderPersistedList(ap.persisted);
    updateBadges();

    // Focus search
    const searchInput = document.getElementById('ap-search-online');
    if (searchInput) setTimeout(() => searchInput.focus(), 50);
}

// ── CLOSE PANEL ────────────────────────────────────────────────────
function closeAdminPanel() {
    const overlay = document.getElementById('admin-panel-overlay');
    if (overlay) overlay.classList.add('ap-hidden');
    apFetch('closeAdminPanel');
}

// ── REFRESH (without re-opening) ───────────────────────────────────
function refreshAdminPanel(data) {
    ap.online    = data.online    || [];
    ap.persisted = data.persisted || [];
    renderOnlineList(ap.online);
    renderPersistedList(ap.persisted);
    updateBadges();
}

// ── BADGES ─────────────────────────────────────────────────────────
function updateBadges() {
    const bo = document.getElementById('ap-badge-online');
    const bp = document.getElementById('ap-badge-persisted');
    if (bo) bo.textContent = ap.online.length;
    if (bp) bp.textContent = ap.persisted.length;
}

// ── RENDER ONLINE LIST ─────────────────────────────────────────────
function renderOnlineList(players, filter) {
    const list = document.getElementById('ap-online-list');
    if (!list) return;
    list.innerHTML = '';

    const filtered = filter
        ? players.filter(p =>
            p.name.toLowerCase().includes(filter) ||
            String(p.serverId).includes(filter) ||
            (p.identifier || '').toLowerCase().includes(filter))
        : players;

    if (!filtered.length) {
        list.innerHTML = '<p class="ap-empty-note">Sin jugadores conectados.</p>';
        return;
    }

    filtered.forEach(player => {
        const row = document.createElement('div');
        row.className = 'ap-player-row' + (player.hasPerm ? ' has-perm' : '');
        row.innerHTML = `
            <div class="ap-player-avatar">${apEsc(apInitials(player.name))}</div>
            <div class="ap-player-info">
                <div class="ap-player-name">
                    ${apEsc(player.name)}
                    <span class="ap-server-id">#${player.serverId}</span>
                </div>
                <div class="ap-player-id">${apEsc(player.identifier || '—')}</div>
            </div>
            <span class="ap-perm-badge ${player.hasPerm ? 'granted' : 'not-granted'}">
                ${player.hasPerm ? '✔ PERMISO' : '✕ SIN PERM'}
            </span>
            ${player.hasPerm
                ? `<button class="ap-btn-revoke" data-id="${apEsc(player.identifier)}">REVOCAR</button>`
                : `<button class="ap-btn-grant"  data-sid="${player.serverId}">OTORGAR</button>`
            }
        `;

        // Grant
        const grantBtn = row.querySelector('.ap-btn-grant');
        if (grantBtn) {
            grantBtn.addEventListener('click', () => {
                apFetch('grantPerm', { serverId: player.serverId });
                grantBtn.textContent = '⏳ ...';
                grantBtn.disabled = true;
            });
        }

        // Revoke
        const revokeBtn = row.querySelector('.ap-btn-revoke');
        if (revokeBtn) {
            revokeBtn.addEventListener('click', () => {
                apFetch('revokePerm', { identifier: player.identifier });
                revokeBtn.textContent = '⏳ ...';
                revokeBtn.disabled = true;
            });
        }

        list.appendChild(row);
    });
}

// ── RENDER PERSISTED LIST ──────────────────────────────────────────
function renderPersistedList(entries, filter) {
    const list  = document.getElementById('ap-persisted-list');
    const empty = document.getElementById('ap-persisted-empty');
    if (!list) return;
    list.innerHTML = '';

    const filtered = filter
        ? entries.filter(e =>
            (e.name || '').toLowerCase().includes(filter) ||
            (e.identifier || '').toLowerCase().includes(filter) ||
            (e.addedBy || '').toLowerCase().includes(filter))
        : entries;

    if (!filtered.length) {
        if (empty) empty.classList.remove('ap-hidden');
        return;
    }
    if (empty) empty.classList.add('ap-hidden');

    filtered.forEach(entry => {
        const row = document.createElement('div');
        row.className = 'ap-persisted-row';
        row.innerHTML = `
            <div class="ap-player-avatar">${apEsc(apInitials(entry.name))}</div>
            <div class="ap-persist-info">
                <div class="ap-persist-name">${apEsc(entry.name || entry.identifier)}</div>
                <div class="ap-persist-meta">
                    <span class="meta-id">${apEsc(entry.identifier)}</span>
                    <span class="meta-by">⚙ ${apEsc(entry.addedBy || '—')}</span>
                    <span>${apEsc(entry.addedAt || '')}</span>
                </div>
            </div>
            <button class="ap-btn-revoke" data-id="${apEsc(entry.identifier)}">REVOCAR</button>
        `;

        row.querySelector('.ap-btn-revoke').addEventListener('click', () => {
            if (confirm(`¿Revocar permiso de "${entry.name || entry.identifier}"?`)) {
                apFetch('revokePerm', { identifier: entry.identifier });
            }
        });

        list.appendChild(row);
    });
}

// ── TAB SWITCHING ──────────────────────────────────────────────────
function setupTabs() {
    const tabs    = document.querySelectorAll('.ap-tab');
    const contents = document.querySelectorAll('.ap-tab-content');

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            const target = tab.dataset.tab;

            tabs.forEach(t => t.classList.remove('active'));
            contents.forEach(c => c.classList.remove('active'));

            tab.classList.add('active');
            const targetEl = document.getElementById(`ap-tab-${target}`);
            if (targetEl) targetEl.classList.add('active');
        });
    });
}

// ── SEARCH ─────────────────────────────────────────────────────────
function setupSearch() {
    const searchOnline = document.getElementById('ap-search-online');
    if (searchOnline) {
        searchOnline.addEventListener('input', () => {
            renderOnlineList(ap.online, searchOnline.value.toLowerCase().trim() || null);
        });
    }

    const searchPersisted = document.getElementById('ap-search-persisted');
    if (searchPersisted) {
        searchPersisted.addEventListener('input', () => {
            renderPersistedList(ap.persisted, searchPersisted.value.toLowerCase().trim() || null);
        });
    }
}

// ── CLOSE BUTTON & ESC ────────────────────────────────────────────
function setupCloseButton() {
    const closeBtn = document.getElementById('ap-btn-close');
    if (closeBtn) {
        closeBtn.addEventListener('click', closeAdminPanel);
    }

    document.addEventListener('keydown', (e) => {
        const overlay = document.getElementById('admin-panel-overlay');
        if (overlay && !overlay.classList.contains('ap-hidden')) {
            if (e.key === 'Escape') {
                e.preventDefault();
                closeAdminPanel();
            }
        }
    });
}

// ── MANUAL ADD FORM ───────────────────────────────────────────────
function setupManualForm() {
    const addBtn  = document.getElementById('ap-btn-manual-add');
    const idInput = document.getElementById('ap-manual-id');
    const nmInput = document.getElementById('ap-manual-name');

    if (!addBtn) return;

    addBtn.addEventListener('click', () => {
        const identifier = (idInput?.value || '').trim();
        const name       = (nmInput?.value || '').trim();

        if (!identifier) {
            idInput?.focus();
            idInput?.classList.add('shake');
            setTimeout(() => idInput?.classList.remove('shake'), 450);
            return;
        }

        apFetch('grantPermById', { identifier, name: name || identifier });
        addBtn.textContent = '⏳ Enviando...';
        addBtn.disabled = true;

        setTimeout(() => {
            addBtn.textContent = '➕ AGREGAR PERMISO';
            addBtn.disabled = false;
            if (idInput) idInput.value = '';
            if (nmInput) nmInput.value = '';
        }, 1500);
    });

    // Enter key on inputs
    [idInput, nmInput].forEach(input => {
        input?.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') addBtn.click();
        });
    });
}

// ── INIT ──────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    setupTabs();
    setupSearch();
    setupCloseButton();
    setupManualForm();
});

// ── NUI MESSAGE HANDLER (extends main script.js listener) ─────────
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data?.action) return;

    switch (data.action) {
        case 'openAdminPanel':
            openAdminPanel(data);
            break;
        case 'closeAdminPanel':
            closeAdminPanel();
            break;
        case 'refreshAdminPanel':
            refreshAdminPanel(data);
            break;
    }
});
