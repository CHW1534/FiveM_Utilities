document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');
    const teamsGrid = document.getElementById('teams-grid');
    const closeBtn = document.getElementById('close-btn');

    closeBtn.addEventListener('click', () => {
        closeUI();
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' || e.key === 'Esc') {
            if (!app.classList.contains('hidden')) {
                closeUI();
            }
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.action === 'openUI') {
            if (data.bodyguardTiers) {
                renderBodyguardTiers(data.bodyguardTiers);
            }
            renderTeams(data.teams, data.currentJob, data.locales, data.currentTeamId);
            app.classList.remove('hidden');
        } else if (data.action === 'closeUI') {
            app.classList.add('hidden');
        } else if (data.action === 'updateTeamHUD') {
            const minimapHud = document.getElementById('minimap-hud');
            const hudBadge = document.getElementById('team-hud-badge');
            const hudLabel = document.getElementById('team-hud-label');
            if (data.visible === false) {
                minimapHud.classList.add('hidden');
            } else {
                minimapHud.classList.remove('hidden');
                hudLabel.textContent = data.teamName ? `EQUIPO: ${data.teamName.toUpperCase()}` : 'ESTADO: CIVIL';
                hudBadge.style.setProperty('--hud-color', data.color || '#9ca3af');
                hudBadge.style.setProperty('--hud-glow', data.colorGlow || 'rgba(156, 163, 175, 0.6)');
            }
        } else if (data.action === 'updateRivalry') {
            const rivalryHud = document.getElementById('rivalry-counter');
            const scoresGrid = document.getElementById('rivalry-scores-grid');
            if (data.visible === false || !data.scores) {
                rivalryHud.classList.add('hidden');
            } else {
                rivalryHud.classList.remove('hidden');
                scoresGrid.innerHTML = '';
                data.scores.forEach(s => {
                    const pill = document.createElement('div');
                    pill.className = 'rivalry-score-pill';
                    pill.style.setProperty('--team-color', s.color || '#fff');
                    pill.style.setProperty('--team-glow', s.colorGlow || 'rgba(255,255,255,0.4)');
                    pill.innerHTML = `
                        <span class="rivalry-team-name">${s.name}</span>
                        <span class="rivalry-team-score">${s.kills || 0}</span>
                    `;
                    scoresGrid.appendChild(pill);
                });
            }
        }
    });

    function renderBodyguardTiers(tiers) {
        const bgSelect = document.getElementById('bg-select');
        bgSelect.innerHTML = '';
        tiers.forEach(tier => {
            const option = document.createElement('option');
            option.value = tier.id;
            option.textContent = `${tier.label} - ${tier.description}`;
            bgSelect.appendChild(option);
        });
    }

    function closeUI() {
        app.classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    let pendingTeamId = null;
    const teleportModal = document.getElementById('teleport-modal');
    const btnStay = document.getElementById('btn-stay');
    const btnBase = document.getElementById('btn-base');

    btnStay.addEventListener('click', () => {
        if (pendingTeamId) {
            selectTeam(pendingTeamId, false);
            teleportModal.classList.add('hidden');
        }
    });

    btnBase.addEventListener('click', () => {
        if (pendingTeamId) {
            selectTeam(pendingTeamId, true);
            teleportModal.classList.add('hidden');
        }
    });

    const bodyguardModal = document.getElementById('bodyguard-modal');
    const btnBgCancel = document.getElementById('btn-bg-cancel');
    const btnBgConfirm = document.getElementById('btn-bg-confirm');

    btnBgCancel.addEventListener('click', () => {
        bodyguardModal.classList.add('hidden');
    });

    btnBgConfirm.addEventListener('click', () => {
        const bgSelect = document.getElementById('bg-select');
        if (bgSelect && bgSelect.value) {
            fetch(`https://${GetParentResourceName()}/spawnBodyguard`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ tier: bgSelect.value })
            });
            bodyguardModal.classList.add('hidden');
            closeUI();
        }
    });

    function renderTeams(teams, currentJob, locales, currentTeamId) {
        teamsGrid.innerHTML = '';

        teams.forEach(team => {
            const isCurrent = (currentTeamId ? (team.id === currentTeamId) : (currentJob === team.job || currentJob === team.id));
            const card = document.createElement('div');
            card.className = 'team-card';
            card.style.setProperty('--team-color', team.color || '#3b82f6');
            card.style.setProperty('--team-glow', team.colorGlow || 'rgba(59, 130, 246, 0.4)');

            let itemsHtml = '';
            if (team.items && team.items.length > 0) {
                itemsHtml = `
                    <div class="items-section">
                        <span class="items-title">Equipamiento Asignado:</span>
                        <div class="items-list">
                            ${team.items.map(i => `<span class="item-badge">${formatItemName(i.name)} x${i.count || 1}</span>`).join('')}
                        </div>
                    </div>
                `;
            } else {
                itemsHtml = `
                    <div class="items-section">
                        <span class="items-title">Equipamiento Asignado:</span>
                        <div class="items-list">
                            <span class="item-badge">Sin objetos tácticos</span>
                        </div>
                    </div>
                `;
            }

            // Create image grid
            let weapons = team.items.filter(i => i.type === 'weapon');
            let items = team.items.filter(i => i.type === 'item');
            
            // Render specific grid layout as shown in the picture
            let itemsGridHtml = '<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-top: 5px;">';
            
            if (team.items && team.items.length > 0) {
                team.items.forEach(i => {
                    let itemName = i.name.replace('WEAPON_', '').toLowerCase();
                    itemsGridHtml += `
                        <div style="background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.06); border-radius: 8px; padding: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px;">
                            <img src="img/items/${itemName}.png" onerror="this.style.display='none'" alt="${itemName}" style="max-width: 40px; max-height: 25px; object-fit: contain;">
                            <span style="font-size: 10px; color: #9ca3af;">${itemName} x${i.count || 1}</span>
                        </div>
                    `;
                });
            } else {
                itemsGridHtml += `
                    <div style="grid-column: span 2; background: rgba(255,255,255,0.03); border: 1px solid rgba(255,255,255,0.06); border-radius: 8px; padding: 14px; text-align: center; color: #9ca3af; font-size: 11px;">
                        🚫 Sin objetos tácticos
                    </div>
                `;
            }
            itemsGridHtml += '</div>';

            let actionsHtml = '';
            if (isCurrent && team.id !== 'civil') {
                actionsHtml = `
                    <button class="select-btn active" style="margin-bottom: 8px; cursor: default;">${locales.currentTeam || 'EQUIPO ACTUAL'}</button>
                    <button class="bg-btn btn-primary" style="width: 100%; padding: 10px; border-radius: 8px; font-weight: 700; margin-bottom: 8px; cursor: pointer; border: none; background: ${team.color}; color: white; transition: 0.3s;">
                        👮 RECLUTAR GUARDAESPALDAS
                    </button>
                    <button class="bg-dismiss-btn btn-secondary" style="width: 100%; padding: 10px; border-radius: 8px; font-weight: 700; cursor: pointer; border: 1px solid rgba(255,255,255,0.2); background: rgba(0,0,0,0.5); color: white; transition: 0.3s;">
                        ❌ RETIRAR SERVICIOS
                    </button>
                `;
            } else {
                actionsHtml = `
                    <button class="select-btn ${isCurrent ? 'active' : ''}" data-id="${team.id}">
                        ${isCurrent ? (locales.currentTeam || 'EQUIPO ACTUAL') : (locales.btnSelect || 'UNIRSE AL EQUIPO')}
                    </button>
                `;
            }

            card.innerHTML = `
                <div class="card-badge">${team.badge || 'EQUIPO'}</div>
                <div style="display:flex; justify-content:center; align-items:center; margin: 15px 0;">
                    <img src="${team.image}" onerror="this.style.display='none'" alt="${team.name}" style="width: 120px; height: 120px; border-radius: 50%; object-fit: cover; border: 2px solid ${team.color || '#fff'}; box-shadow: 0 0 15px ${team.colorGlow || 'rgba(255,255,255,0.4)'};">
                </div>
                <div class="card-info">
                    <h2>${team.name}</h2>
                    <p>${team.description}</p>
                </div>
                <div class="items-section">
                    <span class="items-title">EQUIPAMIENTO ASIGNADO:</span>
                    ${itemsGridHtml}
                </div>
                ${actionsHtml}
            `;

            const btn = card.querySelector('.select-btn');
            if (btn && !isCurrent) {
                btn.addEventListener('click', () => {
                    if (team.id === 'civil') {
                        selectTeam('civil', true);
                    } else {
                        pendingTeamId = team.id;
                        teleportModal.classList.remove('hidden');
                    }
                });
            }

            const bgBtn = card.querySelector('.bg-btn');
            if (bgBtn) {
                bgBtn.addEventListener('click', () => {
                    bodyguardModal.classList.remove('hidden');
                });
                
                // Add hover effect programmatically to avoid complex css classes
                bgBtn.addEventListener('mouseover', () => bgBtn.style.opacity = '0.8');
                bgBtn.addEventListener('mouseout', () => bgBtn.style.opacity = '1');
            }

            const dismissBtn = card.querySelector('.bg-dismiss-btn');
            if (dismissBtn) {
                dismissBtn.addEventListener('click', () => {
                    fetch(`https://${GetParentResourceName()}/dismissBodyguards`, {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({})
                    });
                    closeUI();
                });
                dismissBtn.addEventListener('mouseover', () => dismissBtn.style.background = 'rgba(255,255,255,0.1)');
                dismissBtn.addEventListener('mouseout', () => dismissBtn.style.background = 'rgba(0,0,0,0.5)');
            }

            // 3D Web Experience: Interactive 3D Perspective Tilt on Mouse Movement
            card.addEventListener('mousemove', (e) => {
                const rect = card.getBoundingClientRect();
                const x = e.clientX - rect.left;
                const y = e.clientY - rect.top;
                const centerX = rect.width / 2;
                const centerY = rect.height / 2;
                const rotateX = ((y - centerY) / centerY) * -10;
                const rotateY = ((x - centerX) / centerX) * 10;
                card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(8px)`;
                card.style.boxShadow = `0 20px 40px ${team.colorGlow || 'rgba(0,0,0,0.6)'}`;
            });
            card.addEventListener('mouseleave', () => {
                card.style.transform = 'perspective(1000px) rotateX(0deg) rotateY(0deg) translateZ(0px)';
                card.style.boxShadow = '';
            });

            teamsGrid.appendChild(card);
        });
    }

    function formatItemName(name) {
        if (!name) return '';
        if (name.startsWith('WEAPON_')) {
            return '🔫 ' + name.replace('WEAPON_', '').toLowerCase();
        }
        return '📦 ' + name;
    }

    function selectTeam(teamId, teleport) {
        fetch(`https://${GetParentResourceName()}/selectTeam`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ teamId: teamId, teleport: teleport })
        });
    }
});

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
            document.getElementById('banner-title').textContent = 'SERVICE MENU';
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
    fetch(`https://${GetParentResourceName()}/closeMenu`, {
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
        case 'events':
            renderEventsMenu();
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
            label: 'Selección de Equipos (Facciones)',
            badge: 'EQUIPOS',
            description: 'Abre el menú para elegir entre las distintas facciones (Pocha, Yoma, GN).',
            action: () => openTeamSelector()
        },
        {
            label: 'Activar/Desactivar Radar de Equipo',
            badge: 'RADAR',
            description: 'Activa o desactiva la vista de tus compañeros en el mapa y mini-mapa.',
            action: () => toggleTeammateRadar()
        },
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
            label: 'Eventos de Carreras',
            badge: 'MAPAS',
            description: 'Teletransporte a circuitos de carreras especiales.',
            submenu: 'events'
        },
        {
            label: 'Desactivar Tráfico y NPCs (Mundo)',
            badge: 'MUNDO',
            description: 'Alternar la aparición de tráfico, peatones y NPCs en toda la ciudad.',
            action: () => toggleWorldNPCs()
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

// ─── Events Menu ──
function renderEventsMenu() {
    setSubtitle('EVENTOS DE CARRERAS');
    currentItems = [];

    if (!menuData || !menuData.mapEvents) return;

    menuData.mapEvents.forEach(evt => {
        currentItems.push({
            label: evt.label,
            badge: evt.badge,
            description: evt.description,
            action: () => triggerMapEvent(evt.id)
        });
    });

    renderItems();
}

function triggerMapEvent(eventId) {
    fetch(`https://${GetParentResourceName()}/selectMapEvent`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: eventId })
    });
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

function openTeamSelector() {
    closeMenu();
    fetch(`https://${GetParentResourceName()}/openTeamSelector`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).catch(e => console.log(e));
}

function toggleTeammateRadar() {
    closeMenu();
    fetch(`https://${GetParentResourceName()}/toggleTeammateRadar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).catch(e => console.log(e));
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
    fetch(`https://${GetParentResourceName()}/buyGuard`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: id })
    });
}

function buyVehicle(id) {
    fetch(`https://${GetParentResourceName()}/buyVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: id })
    });
}

function removeWanted() {
    fetch(`https://${GetParentResourceName()}/removeWanted`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function dismissAll() {
    fetch(`https://${GetParentResourceName()}/dismissAll`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function cleanupVehicles() {
    fetch(`https://${GetParentResourceName()}/cleanupVehicles`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function cleanupNPCs() {
    fetch(`https://${GetParentResourceName()}/cleanupNPCs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function toggleWorldNPCs() {
    fetch(`https://${GetParentResourceName()}/toggleWorldNPCs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function openAdminPanel() {
    fetch(`https://${GetParentResourceName()}/openAdminPanel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function refreshPlayers() {
    fetch(`https://${GetParentResourceName()}/refreshPlayers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function setPermission(targetId, permType) {
    fetch(`https://${GetParentResourceName()}/setPermission`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ targetId: targetId, permType: permType, tiers: null })
    });
    // Go back to the player list after setting permission
    goBack();
}

function triggerCustomInput(type) {
    fetch(`https://${GetParentResourceName()}/triggerCustomInput`, {
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


