/* ═══════════════════════════════════════════════════════════════════════════════
   BodyGuard Menu — vMenu / NativeUI Style JavaScript
   Hierarchical menu navigation with keyboard support + Admin Panel
   ═══════════════════════════════════════════════════════════════════════════════ */

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────
let menuData = null;
let adminPlayers = [];
let selectedIndex = 0;
let currentView = 'main';    // 'main' | 'guards' | 'vehicles' | 'services' | 'adminMain' | 'adminPlayer'
let currentItems = [];        // Items currently displayed
let menuStack = [];           // Navigation history for back
let selectedPlayer = null;    // For admin panel

// ─────────────────────────────────────────────────────────────────────────────
// NUI Message Handler
// ─────────────────────────────────────────────────────────────────────────────
window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.action) {
        case 'openMenu':
            menuData = data;
            currentView = 'main';
            menuStack = [];
            selectedIndex = 0;
            document.getElementById('banner-title').textContent = 'BODYGUARD';
            document.querySelector('.menu-banner').style.background = 'linear-gradient(135deg, #0055a4 0%, #003d7a 40%, #002d5a 100%)';
            renderCurrentView();
            showMenu();
            break;
        case 'openAdmin':
            adminPlayers = data.players;
            currentView = 'adminMain';
            menuStack = [];
            selectedIndex = 0;
            document.getElementById('banner-title').textContent = 'ADMIN PANEL';
            document.querySelector('.menu-banner').style.background = 'linear-gradient(135deg, #a40000 0%, #7a0000 40%, #5a0000 100%)';
            renderCurrentView();
            showMenu();
            break;
        case 'closeMenu':
            hideMenu();
            break;
        case 'updateGuardCount':
            if (menuData) {
                menuData.activeGuards = data.activeGuards;
                menuData.maxGuards = data.maxGuards;
                renderCurrentView();
            }
            break;
    }
});

// ─────────────────────────────────────────────────────────────────────────────
// Show / Hide
// ─────────────────────────────────────────────────────────────────────────────
function showMenu() {
    const el = document.getElementById('menu-container');
    el.classList.remove('hidden', 'closing');
}

function hideMenu() {
    const el = document.getElementById('menu-container');
    el.classList.add('closing');
    setTimeout(() => {
        el.classList.add('hidden');
        el.classList.remove('closing');
    }, 120);
}

function closeMenu() {
    fetch('https://BodyGuard/closeMenu', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard Navigation (vMenu style)
// ─────────────────────────────────────────────────────────────────────────────
document.addEventListener('keydown', function (e) {
    const container = document.getElementById('menu-container');
    if (container.classList.contains('hidden')) return;

    switch (e.key) {
        case 'ArrowUp':
            e.preventDefault();
            navigateUp();
            break;
        case 'ArrowDown':
            e.preventDefault();
            navigateDown();
            break;
        case 'Enter':
            e.preventDefault();
            selectItem();
            break;
        case 'Backspace':
            e.preventDefault();
            goBack();
            break;
        case 'Escape':
            e.preventDefault();
            if (menuStack.length > 0) {
                goBack();
            } else {
                closeMenu();
            }
            break;
    }
});

function navigateUp() {
    if (currentItems.length === 0) return;
    selectedIndex = (selectedIndex - 1 + currentItems.length) % currentItems.length;
    updateSelection();
}

function navigateDown() {
    if (currentItems.length === 0) return;
    selectedIndex = (selectedIndex + 1) % currentItems.length;
    updateSelection();
}

function selectItem() {
    if (currentItems.length === 0) return;
    const item = currentItems[selectedIndex];
    if (!item) return;

    if (item.submenu) {
        // Navigate into submenu
        menuStack.push({ view: currentView, index: selectedIndex });
        currentView = item.submenu;
        selectedIndex = 0;
        if (item.playerData) {
            selectedPlayer = item.playerData;
        }
        renderCurrentView();
    } else if (item.action) {
        item.action();
    }
}

function goBack() {
    if (menuStack.length > 0) {
        const prev = menuStack.pop();
        currentView = prev.view;
        selectedIndex = prev.index;
        if (currentView === 'adminMain') {
            selectedPlayer = null;
        }
        renderCurrentView();
    } else {
        closeMenu();
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Render Views
// ─────────────────────────────────────────────────────────────────────────────
function renderCurrentView() {
    switch (currentView) {
        case 'main':
            renderMainMenu();
            break;
        case 'guards':
            renderGuardsMenu();
            break;
        case 'vehicles':
            renderVehiclesMenu();
            break;
        case 'services':
            renderServicesMenu();
            break;
        case 'adminMain':
            renderAdminMain();
            break;
        case 'adminPlayer':
            renderAdminPlayer();
            break;
    }
}

// ─── Main Menu ──
function renderMainMenu() {
    const active = menuData ? menuData.activeGuards : 0;
    const max = menuData ? menuData.maxGuards : 7;
    const isAdmin = menuData ? menuData.isAdmin : false;

    setSubtitle('MENÚ PRINCIPAL');
    currentItems = [
        {
            label: 'Guardaespaldas',
            right: active + '/' + max,
            description: 'Contrata guardaespaldas que te seguirán y protegerán en combate.',
            submenu: 'guards'
        },
        {
            label: 'Vehículos de Escolta',
            description: 'Despliega vehículos blindados con chofer armado que te escoltará.',
            submenu: 'vehicles'
        },
        {
            label: 'Servicios',
            description: 'Acciones especiales: limpiar nivel de búsqueda, despedir tropas, etc.',
            submenu: 'services'
        }
    ];

    if (isAdmin) {
        currentItems.push({
            label: 'Panel de Administración',
            badge: 'ADMIN',
            description: 'Gestiona permisos de jugadores online.',
            action: () => openAdminPanel()
        });
    }

    renderItems();
}

// ─── Guards Menu ──
function renderGuardsMenu() {
    setSubtitle('GUARDAESPALDAS');
    currentItems = [];

    if (!menuData) return;

    const tiers = menuData.guards.filter(g => g.category === 'tier');
    if (tiers.length > 0) {
        tiers.forEach(g => {
            currentItems.push({
                label: g.label,
                badge: tierBadge(g),
                description: g.description,
                stats: { hp: g.health, armor: g.armor, acc: g.accuracy + '%' },
                action: () => buyGuard(g.id)
            });
        });
    }

    const customs = menuData.guards.filter(g => g.category === 'custom');
    if (customs.length > 0) {
        customs.forEach(g => {
            currentItems.push({
                label: g.label,
                badge: 'CUSTOM',
                description: g.description,
                stats: { hp: g.health, armor: g.armor, acc: g.accuracy + '%' },
                action: () => buyGuard(g.id)
            });
        });
    }

    currentItems.push({
        label: 'Spawn Modelo por Nombre',
        badge: 'MANUAL',
        description: 'Escribe el nombre del modelo del ped (ej: ig_bankman).',
        action: () => triggerCustomInput('guard')
    });

    renderItems();
}

function tierBadge(guard) {
    const tierMap = { tier1: 'I', tier2: 'II', tier3: 'III', tier4: 'IV' };
    return 'TIER ' + (tierMap[guard.id] || '?');
}

// ─── Vehicles Menu ──
function renderVehiclesMenu() {
    setSubtitle('VEHÍCULOS DE ESCOLTA');
    currentItems = [];

    if (!menuData) return;

    menuData.vehicles.forEach(v => {
        currentItems.push({
            label: v.label,
            badge: v.category === 'custom' ? 'CUSTOM' : null,
            description: v.description,
            action: () => buyVehicle(v.id)
        });
    });

    currentItems.push({
        label: 'Spawn Modelo por Nombre',
        badge: 'MANUAL',
        description: 'Escribe el nombre del modelo del vehículo (ej: kuruma).',
        action: () => triggerCustomInput('vehicle')
    });

    renderItems();
}

// ─── Services Menu ──
function renderServicesMenu() {
    setSubtitle('SERVICIOS');
    const active = menuData ? menuData.activeGuards : 0;

    currentItems = [
        {
            label: 'Eliminar Nivel de Búsqueda',
            description: 'Limpia completamente tu nivel de búsqueda policial.',
            action: () => removeWanted()
        },
        {
            label: 'Limpiar Vehículos Fuera de Uso',
            badge: 'AUTOS',
            description: 'Elimina de inmediato todos los vehículos de escolta y convoy abandonados.',
            action: () => cleanupVehicles()
        },
        {
            label: 'Limpiar NPCs Fuera de Uso',
            badge: 'NPCS',
            description: 'Elimina de inmediato escoltas rezagados, muertos o abandonados a distancia.',
            action: () => cleanupNPCs()
        },
        {
            label: 'Despedir a Todos',
            right: active + ' activos',
            description: 'Despide a todos tus guardaespaldas y elimina los vehículos de escolta.',
            action: () => dismissAll()
        }
    ];

    renderItems();
}

// ─── Admin Main Menu ──
function renderAdminMain() {
    setSubtitle('JUGADORES ONLINE');
    currentItems = [];

    currentItems.push({
        label: 'Refrescar Lista',
        description: 'Actualiza la lista de jugadores conectados.',
        action: () => refreshPlayers()
    });

    if (adminPlayers && adminPlayers.length > 0) {
        adminPlayers.forEach(p => {
            let badgeText = p.isAdmin ? 'ADMIN' : p.permType.toUpperCase();
            currentItems.push({
                label: `[${p.id}] ${p.name}`,
                badge: badgeText,
                description: `Gestionar permisos para ${p.name} (${p.license})`,
                submenu: 'adminPlayer',
                playerData: p
            });
        });
    } else {
        currentItems.push({
            label: 'No hay jugadores online.',
            description: ''
        });
    }

    renderItems();
}

// ─── Admin Player Menu ──
function renderAdminPlayer() {
    if (!selectedPlayer) return goBack();
    setSubtitle(`GESTIONAR: ${selectedPlayer.name}`);

    let currentPermDesc = `Permiso actual: ${selectedPlayer.permType.toUpperCase()}`;
    if (selectedPlayer.isAdmin) currentPermDesc += ' (Es Admin - Tiene acceso total)';

    currentItems = [
        {
            label: 'Permiso: DEFAULT',
            description: `Usa la configuración general del servidor (Config.DefaultAccess). ${currentPermDesc}`,
            action: () => setPermission(selectedPlayer.id, 'default')
        },
        {
            label: 'Permiso: PERMANENTE',
            description: `Da acceso total siempre. Guardado en base de datos. ${currentPermDesc}`,
            action: () => setPermission(selectedPlayer.id, 'permanent')
        },
        {
            label: 'Permiso: TEMPORAL (Sesión)',
            description: `Da acceso total pero solo hasta que el jugador se desconecte. ${currentPermDesc}`,
            action: () => setPermission(selectedPlayer.id, 'session')
        },
        {
            label: 'REVOCAR Permiso',
            description: `Bloquea explícitamente el uso de guardaespaldas para este jugador. ${currentPermDesc}`,
            action: () => setPermission(selectedPlayer.id, 'revoked')
        }
    ];

    renderItems();
}


// ─────────────────────────────────────────────────────────────────────────────
// Render Helpers
// ─────────────────────────────────────────────────────────────────────────────
function setSubtitle(text) {
    document.getElementById('menu-subtitle').textContent = text;
}

function renderItems() {
    const container = document.getElementById('menu-items');
    container.innerHTML = '';

    currentItems.forEach((item, index) => {
        const div = document.createElement('div');
        div.className = 'menu-item' + (index === selectedIndex ? ' selected' : '');
        div.setAttribute('data-index', index);

        let rightHtml = '';
        if (item.badge) {
            rightHtml += '<span class="item-badge">' + escapeHtml(item.badge) + '</span>';
        }
        if (item.right) {
            rightHtml += '<span>' + escapeHtml(item.right) + '</span>';
        }
        if (item.submenu) {
            rightHtml += '<span class="arrow">›</span>';
        }

        div.innerHTML =
            '<span class="item-label">' + escapeHtml(item.label) + '</span>' +
            '<span class="item-right">' + rightHtml + '</span>';

        div.addEventListener('mouseenter', () => {
            selectedIndex = index;
            updateSelection();
        });

        div.addEventListener('click', () => {
            selectedIndex = index;
            selectItem();
        });

        container.appendChild(div);
    });

    updateCounter();
    updateDescription();
}

function updateSelection() {
    const items = document.querySelectorAll('.menu-item');
    items.forEach((el, i) => {
        el.classList.toggle('selected', i === selectedIndex);
    });

    const selected = document.querySelector('.menu-item.selected');
    if (selected) {
        selected.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
    }

    updateCounter();
    updateDescription();
}

function updateCounter() {
    const el = document.getElementById('item-counter');
    if (currentItems.length > 0) {
        el.textContent = (selectedIndex + 1) + ' / ' + currentItems.length;
    } else {
        el.textContent = '0 / 0';
    }
}

function updateDescription() {
    const descBox = document.getElementById('menu-description');
    const item = currentItems[selectedIndex];

    if (item && item.description) {
        let html = '<p>' + escapeHtml(item.description) + '</p>';

        if (item.stats) {
            html += '<div class="desc-stats">';
            if (item.stats.hp) html += '<span class="desc-stat">HP: <span>' + item.stats.hp + '</span></span>';
            if (item.stats.armor) html += '<span class="desc-stat">Armadura: <span>' + item.stats.armor + '</span></span>';
            if (item.stats.acc) html += '<span class="desc-stat">Precisión: <span>' + item.stats.acc + '</span></span>';
            html += '</div>';
        }

        descBox.innerHTML = html;
        descBox.classList.add('visible');
    } else {
        descBox.classList.remove('visible');
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Actions → NUI Callbacks
// ─────────────────────────────────────────────────────────────────────────────
function buyGuard(id) {
    fetch('https://BodyGuard/buyGuard', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: id })
    });
}

function buyVehicle(id) {
    fetch('https://BodyGuard/buyVehicle', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: id })
    });
}

function removeWanted() {
    fetch('https://BodyGuard/removeWanted', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function dismissAll() {
    fetch('https://BodyGuard/dismissAll', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function cleanupVehicles() {
    fetch('https://BodyGuard/cleanupVehicles', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function cleanupNPCs() {
    fetch('https://BodyGuard/cleanupNPCs', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function openAdminPanel() {
    fetch('https://BodyGuard/openAdminPanel', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function refreshPlayers() {
    fetch('https://BodyGuard/refreshPlayers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function setPermission(targetId, permType) {
    fetch('https://BodyGuard/setPermission', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: targetId, permType: permType, tiers: null })
    });
    // Go back to the player list after setting permission
    goBack();
}

function triggerCustomInput(type) {
    fetch('https://BodyGuard/triggerCustomInput', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: type })
    });
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
