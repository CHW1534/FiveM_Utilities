// ══════════════════════════════════════════════════════════════════
//  respawn_menu / html / script.js
//  Handles: NUI message routing, map rendering, interactions,
//           countdown, validation, NUICallback triggers
// ══════════════════════════════════════════════════════════════════

'use strict';

const RESOURCE_NAME = 'respawn_menu';

// ── STATE ──────────────────────────────────────────────────────────
const state = {
    deathX:       0,
    deathY:       0,
    deathZ:       0,
    hasPerm:      false,
    minDist:      150,
    autoTime:     30,
    points:       [],
    locales:      {},
    mapBounds:    { minX: -4096, maxX: 4096, minY: -4096, maxY: 4096 },
    selectedId:   null,
    countdownVal: 0,
    countdownInt: null,
    errorTimeout: null,
};

// ── DOM REFERENCES ─────────────────────────────────────────────────
const els = {
    container:     () => document.getElementById('respawn-container'),
    title:         () => document.getElementById('title-text'),
    subtitle:      () => document.getElementById('subtitle-text'),
    countdownRow:  () => document.getElementById('countdown-row'),
    countdownVal:  () => document.getElementById('countdown-value'),
    mapWrapper:    () => document.getElementById('map-wrapper'),
    exclusionZone: () => document.getElementById('exclusion-zone'),
    deathMarker:   () => document.getElementById('death-marker'),
    mapMarkers:    () => document.getElementById('map-markers'),
    btnHere:       () => document.getElementById('btn-respawn-here'),
    vipIcon:       () => document.getElementById('vip-icon'),
    vipNotice:     () => document.getElementById('vip-notice'),
    zoneList:      () => document.getElementById('zone-list'),
    btnDeploy:     () => document.getElementById('btn-deploy'),
    btnDeployText: () => document.getElementById('btn-deploy-text'),
    errorToast:    () => document.getElementById('error-toast'),
    errorMsg:      () => document.getElementById('error-message'),
    vipTooltip:    () => document.getElementById('vip-tooltip'),
    btnNearby:     () => document.getElementById('btn-respawn-nearby'),
    minDistLabel:  () => document.getElementById('min-dist-label'),
    minDistText:   () => document.getElementById('min-dist-text'),
};

// ── GTA V WORLD → SCREEN CONVERSION ───────────────────────────────
// GTA V map runs roughly X: -4096→4096, Y: -4096→4096
// Y axis is inverted in screen space (north = top = lower Y world)
function worldToScreen(wx, wy) {
    const { minX, maxX, minY, maxY } = state.mapBounds;
    const pctX = (wx - minX) / (maxX - minX);
    const pctY = 1.0 - (wy - minY) / (maxY - minY); // flip Y
    return { pctX, pctY };
}

function pctToPixels(pctX, pctY) {
    const wrapper = els.mapWrapper();
    const rect = wrapper.getBoundingClientRect();
    return {
        px: pctX * rect.width,
        py: pctY * rect.height,
    };
}

// ── GET COORDS HELPER (handles object, array, or FiveM vector) ────
function getCoords(point) {
    if (!point || !point.coords) return { x: 0, y: 0, z: 0 };
    const c = point.coords;
    if (typeof c.x === 'number' && typeof c.y === 'number') {
        return { x: c.x, y: c.y, z: c.z || 0 };
    }
    if (Array.isArray(c) && c.length >= 2) {
        return { x: Number(c[0]) || 0, y: Number(c[1]) || 0, z: Number(c[2]) || 0 };
    }
    if (typeof c[1] === 'number' && typeof c[2] === 'number') {
        return { x: Number(c[1]) || 0, y: Number(c[2]) || 0, z: Number(c[3]) || 0 };
    }
    return { x: 0, y: 0, z: 0 };
}

// ── DISTANCE CALC (GTA units, 2D XY plane) ─────────────────────────
function distanceTo(ax, ay, bx, by) {
    const dx = Number(ax || 0) - Number(bx || 0);
    const dy = Number(ay || 0) - Number(by || 0);
    return Math.sqrt(dx * dx + dy * dy);
}

// ── OPEN MENU ──────────────────────────────────────────────────────
function openMenu(data) {
    // Stop any leftover countdown from a previous session
    stopCountdown();

    Object.assign(state, {
        deathX:    data.deathX,
        deathY:    data.deathY,
        deathZ:    data.deathZ,
        hasPerm:   data.hasPerm,
        minDist:   data.minDist   ?? 150,
        autoTime:  data.autoTime  ?? 30,
        points:    data.points    ?? [],
        locales:   data.locales   ?? {},
        mapBounds: data.mapBounds ?? state.mapBounds,
        selectedId: null,
    });

    // Update min distance labels
    if (els.minDistLabel()) els.minDistLabel().textContent = Math.round(state.minDist);
    if (els.minDistText())  els.minDistText().textContent  = Math.round(state.minDist);

    const container = els.container();

    // Step 1: Make the container layoutable but invisible
    container.classList.remove('hidden');
    container.classList.remove('visible');

    // Build map & list (needs layout to calculate positions)
    renderMap();
    renderZoneList();

    // VIP button state
    updateVIPButton();

    // Step 2: After the browser has painted the invisible state,
    //         add .visible to trigger the CSS opacity/scale transition.
    //         Double-rAF ensures the transition actually plays in CEF.
    requestAnimationFrame(() => {
        requestAnimationFrame(() => {
            container.classList.add('visible');
        });
    });

    // Countdown
    if (state.autoTime > 0) {
        startCountdown(state.autoTime);
    } else {
        els.countdownRow().classList.add('hidden');
    }

    // Deploy button initial state
    setDeployButton(false);
}

// ── CLOSE MENU ─────────────────────────────────────────────────────
function closeMenu() {
    const container = els.container();
    container.classList.remove('visible');
    container.classList.add('hidden');
    stopCountdown();
    state.selectedId = null;
}

// ── RENDER MAP ─────────────────────────────────────────────────────
function renderMap() {
    // Wait until the map image is laid out
    requestAnimationFrame(() => {
        positionDeathMarker();
        positionExclusionZone();
        renderMapMarkers();
    });
}

function positionDeathMarker() {
    const { pctX, pctY } = worldToScreen(state.deathX, state.deathY);
    const { px, py } = pctToPixels(pctX, pctY);
    const marker = els.deathMarker();
    marker.style.left = px + 'px';
    marker.style.top  = py + 'px';
}

function positionExclusionZone() {
    const wrapper = els.mapWrapper();
    const rect = wrapper.getBoundingClientRect();

    // Convert world radius to screen pixels
    const { minX, maxX } = state.mapBounds;
    const worldWidth = maxX - minX;
    const pixelsPerUnit = rect.width / worldWidth;
    const radiusPx = state.minDist * pixelsPerUnit;
    const diameterPx = radiusPx * 2;

    // Center on death point
    const { pctX, pctY } = worldToScreen(state.deathX, state.deathY);
    const { px, py } = pctToPixels(pctX, pctY);

    const zone = els.exclusionZone();
    zone.style.width  = diameterPx + 'px';
    zone.style.height = diameterPx + 'px';
    zone.style.left   = (px - radiusPx) + 'px';
    zone.style.top    = (py - radiusPx) + 'px';
}

function renderMapMarkers() {
    const container = els.mapMarkers();
    container.innerHTML = '';

    state.points.forEach(point => {
        const c = getCoords(point);
        const dist = distanceTo(state.deathX, state.deathY, c.x, c.y);
        const tooClose = dist < state.minDist;

        const { pctX, pctY } = worldToScreen(c.x, c.y);
        const { px, py } = pctToPixels(pctX, pctY);

        const el = document.createElement('div');
        el.className = 'map-marker' + (tooClose ? ' too-close' : '');
        el.dataset.id = point.id;
        el.style.left = px + 'px';
        el.style.top  = py + 'px';

        const distKm = (dist / 1000).toFixed(1);
        el.innerHTML = `
            <div class="marker-pin"></div>
            <div class="marker-label">
                ${escapeHtml(point.label)}
                <span>${tooClose ? '✕ Muy cerca' : distKm + ' km'}</span>
            </div>
        `;

        if (!tooClose) {
            el.addEventListener('click', () => selectPoint(point.id));
        } else {
            el.addEventListener('click', () => showError(
                state.locales.tooClose
                    ? state.locales.tooClose.replace('%d', Math.round(state.minDist))
                    : `Zona en conflicto. Selecciona a más de ${Math.round(state.minDist)}m.`
            ));
        }

        container.appendChild(el);
    });
}

// ── RENDER ZONE LIST ───────────────────────────────────────────────
function renderZoneList() {
    const list = els.zoneList();
    list.innerHTML = '';

    // Sort: valid first, too-close last
    const sorted = [...state.points].sort((a, b) => {
        const ca = getCoords(a);
        const cb = getCoords(b);
        const da = distanceTo(state.deathX, state.deathY, ca.x, ca.y);
        const db = distanceTo(state.deathX, state.deathY, cb.x, cb.y);
        const aClose = da < state.minDist;
        const bClose = db < state.minDist;
        if (aClose !== bClose) return aClose ? 1 : -1;
        return da - db;
    });

    sorted.forEach(point => {
        const c = getCoords(point);
        const dist = distanceTo(state.deathX, state.deathY, c.x, c.y);
        const tooClose = dist < state.minDist;
        const distKm = (dist / 1000).toFixed(1);

        const item = document.createElement('div');
        item.className = 'zone-item' + (tooClose ? ' too-close' : '');
        item.dataset.id = point.id;

        item.innerHTML = `
            <div class="zone-info">
                <div class="zone-name">${escapeHtml(point.label)}</div>
                <div class="zone-dist">${tooClose ? '⛔ ' : '📍 '}${distKm} km</div>
            </div>
            <button class="zone-btn ${tooClose ? 'btn-close' : 'btn-select'}" ${tooClose ? 'disabled' : ''}>
                ${tooClose ? 'DEMASIADO CERCA' : 'SELECCIONAR'}
            </button>
        `;

        if (!tooClose) {
            item.addEventListener('click', () => selectPoint(point.id));
            item.querySelector('.zone-btn').addEventListener('click', (e) => {
                e.stopPropagation();
                selectPoint(point.id);
            });
        } else {
            item.addEventListener('click', () => showError(
                state.locales.tooClose
                    ? state.locales.tooClose.replace('%d', Math.round(state.minDist))
                    : `Zona en conflicto. Selecciona a más de ${Math.round(state.minDist)}m.`
            ));
        }

        list.appendChild(item);
    });

    // Auto-select first valid point if none selected yet
    const firstValid = sorted.find(p => {
        const c = getCoords(p);
        return distanceTo(state.deathX, state.deathY, c.x, c.y) >= state.minDist;
    });
    if (firstValid && !state.selectedId) {
        selectPoint(firstValid.id);
    }
}

// ── SELECT POINT ───────────────────────────────────────────────────
function selectPoint(pointId) {
    state.selectedId = pointId;

    // Update zone list
    document.querySelectorAll('.zone-item').forEach(el => {
        el.classList.toggle('selected', el.dataset.id === pointId);
        const btn = el.querySelector('.zone-btn');
        if (btn && !el.classList.contains('too-close')) {
            btn.textContent = el.dataset.id === pointId ? '✔ ELEGIDO' : 'SELECCIONAR';
        }
    });

    // Update map markers
    document.querySelectorAll('.map-marker').forEach(el => {
        el.classList.toggle('selected', el.dataset.id === pointId);
    });

    // Activate deploy button
    setDeployButton(true);
}

// ── BUTTON STATES & ACTIONS ─────────────────────────────────────────
function updateVIPButton() {
    const btn = els.btnHere();
    if (!btn) return;

    if (state.hasPerm) {
        btn.classList.remove('locked');
        btn.classList.add('active');
        btn.disabled = false;
        els.vipIcon().textContent = '⚡';
        els.vipNotice().classList.add('hidden');
    } else {
        btn.classList.add('locked');
        btn.classList.remove('active');
        btn.disabled = true;
        els.vipIcon().textContent = '🔒';
        els.vipNotice().classList.remove('hidden');
    }
}

function initActionButtons() {
    const btnHere = els.btnHere();
    if (btnHere) {
        // Tooltip for locked
        btnHere.addEventListener('mouseenter', (e) => {
            if (!state.hasPerm) {
                const tt = els.vipTooltip();
                if (tt) {
                    tt.classList.remove('hidden');
                    tt.style.left = (e.clientX + 12) + 'px';
                    tt.style.top  = (e.clientY - 30) + 'px';
                }
            }
        });
        btnHere.addEventListener('mousemove', (e) => {
            const tt = els.vipTooltip();
            if (tt) {
                tt.style.left = (e.clientX + 12) + 'px';
                tt.style.top  = (e.clientY - 30) + 'px';
            }
        });
        btnHere.addEventListener('mouseleave', () => {
            els.vipTooltip()?.classList.add('hidden');
        });

        btnHere.addEventListener('click', () => {
            if (!state.hasPerm) {
                showError(state.locales.lockedTooltip || 'Requiere rango táctico avanzado.');
                return;
            }
            const payload = {
                deathX: state.deathX,
                deathY: state.deathY,
                deathZ: state.deathZ
            };
            stopCountdown();
            closeMenu();
            fetch(`https://${RESOURCE_NAME}/respawnHere`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
        });
    }

    const btnNearby = els.btnNearby();
    if (btnNearby) {
        btnNearby.addEventListener('click', () => {
            const payload = {
                deathX: state.deathX,
                deathY: state.deathY,
                deathZ: state.deathZ
            };
            stopCountdown();
            closeMenu();
            fetch(`https://${RESOURCE_NAME}/respawnNearby`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
        });
    }

    els.btnDeploy()?.addEventListener('click', confirmDeploy);
}

// ── DEPLOY BUTTON ──────────────────────────────────────────────────
function setDeployButton(active) {
    const btn = els.btnDeploy();
    const txt = els.btnDeployText();
    if (!btn || !txt) return;

    if (active) {
        btn.classList.remove('disabled');
        btn.classList.add('active');
        btn.disabled = false;
        txt.textContent = state.locales.btnDeploy || 'DESPLEGAR EN ZONA';
    } else {
        btn.classList.add('disabled');
        btn.classList.remove('active');
        btn.disabled = true;
        txt.textContent = state.locales.btnDeployWait || 'SELECCIONA UN PUNTO';
    }
}

function confirmDeploy() {
    const targetPointId = state.selectedId;
    if (!targetPointId) {
        showError(state.locales.noPointSelected || 'Selecciona un punto de despliegue en el mapa.');
        return;
    }
    const payload = {
        pointId: targetPointId,
        deathX: state.deathX,
        deathY: state.deathY,
        deathZ: state.deathZ
    };
    stopCountdown();
    closeMenu();
    fetch(`https://${RESOURCE_NAME}/respawnZone`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    });
}

// ── COUNTDOWN ──────────────────────────────────────────────────────
function startCountdown(seconds) {
    state.countdownVal = seconds;
    updateCountdownDisplay(seconds);
    els.countdownRow().classList.remove('hidden');

    if (state.countdownInt) clearInterval(state.countdownInt);
    state.countdownInt = setInterval(() => {
        state.countdownVal--;
        updateCountdownDisplay(state.countdownVal);
        if (state.countdownVal <= 0) {
            stopCountdown();
            // Auto-respawn via Lua countdown thread
        }
    }, 1000);
}

function updateCountdownDisplay(secs) {
    const el = els.countdownVal();
    if (el) el.textContent = Math.max(0, secs) + 's';
}

function stopCountdown() {
    if (state.countdownInt) {
        clearInterval(state.countdownInt);
        state.countdownInt = null;
    }
}

// ── ERROR TOAST ────────────────────────────────────────────────────
function showError(msg) {
    const toast = els.errorToast();
    const msgEl = els.errorMsg();
    if (!toast || !msgEl) return;

    msgEl.textContent = msg;
    toast.classList.remove('hidden');

    // Shake the zone list
    const zoneSection = document.getElementById('zone-section');
    if (zoneSection) {
        zoneSection.classList.remove('shake');
        void zoneSection.offsetWidth; // reflow
        zoneSection.classList.add('shake');
    }

    if (state.errorTimeout) clearTimeout(state.errorTimeout);
    state.errorTimeout = setTimeout(() => {
        toast.classList.add('hidden');
    }, 3000);
}

// ── SERVER ERROR EVENT ─────────────────────────────────────────────
// Called from Lua: SendNUIMessage({ action = 'showError', message = '...' })
function handleServerError(message) {
    showError(message);
}

// ── KEYBOARD SHORTCUTS ─────────────────────────────────────────────
document.addEventListener('keydown', (e) => {
    if (els.container().classList.contains('hidden')) return;

    if (e.key === 'Enter') {
        e.preventDefault();
        confirmDeploy();
    }
    if (e.key === 'e' || e.key === 'E') {
        e.preventDefault();
        if (state.hasPerm) {
            els.btnHere()?.click();
        }
    }
    if (e.key === 'ArrowDown') {
        e.preventDefault();
        navigateList(1);
    }
    if (e.key === 'ArrowUp') {
        e.preventDefault();
        navigateList(-1);
    }
    if (e.key === 'Escape') {
        // Don't allow closing during death — handled by Lua auto-respawn
    }
});

function navigateList(dir) {
    const items = [...document.querySelectorAll('.zone-item:not(.too-close)')];
    if (!items.length) return;
    const currentIdx = items.findIndex(el => el.dataset.id === state.selectedId);
    let nextIdx = currentIdx + dir;
    if (nextIdx < 0) nextIdx = items.length - 1;
    if (nextIdx >= items.length) nextIdx = 0;
    const next = items[nextIdx];
    if (next) selectPoint(next.dataset.id);
    next?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

// ── HELPER: Escape HTML ────────────────────────────────────────────
function escapeHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}

// ── NUI MESSAGE LISTENER ───────────────────────────────────────────
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'openMenu':
            openMenu(data);
            break;

        case 'closeMenu':
            closeMenu();
            break;

        case 'updateCountdown':
            updateCountdownDisplay(data.seconds);
            break;

        case 'showError':
            handleServerError(data.message || '');
            break;
    }
});

// ── RESIZE HANDLER (re-position map elements on resize) ───────────
window.addEventListener('resize', () => {
    if (!els.container().classList.contains('hidden')) {
        renderMap();
    }
});

// ── HANDLE WINDOW LOAD (re-render after fonts/img load) ────────────
window.addEventListener('load', () => {
    const mapImg = document.getElementById('map-img');
    if (mapImg) {
        mapImg.addEventListener('load', () => {
            if (!els.container().classList.contains('hidden')) {
                renderMap();
            }
        });
    }
});

// ── INITIALIZE BUTTONS ─────────────────────────────────────────────
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initActionButtons);
} else {
    initActionButtons();
}
