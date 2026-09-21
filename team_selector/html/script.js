document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');
    const teamsGrid = document.getElementById('teams-grid');
    const closeBtn = document.getElementById('close-btn');

    closeBtn.addEventListener('click', () => {
        closeUI();
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' || e.key === 'Esc') {
            closeUI();
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.action === 'openUI') {
            renderTeams(data.teams, data.currentJob, data.locales);
            app.classList.remove('hidden');
        } else if (data.action === 'closeUI') {
            app.classList.add('hidden');
        }
    });

    function closeUI() {
        app.classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }

    function renderTeams(teams, currentJob, locales) {
        teamsGrid.innerHTML = '';

        teams.forEach(team => {
            const isCurrent = (currentJob === team.job);
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

            card.innerHTML = `
                <div class="card-badge">${team.badge || 'EQUIPO'}</div>
                <div class="card-info">
                    <h2>${team.name}</h2>
                    <p>${team.description}</p>
                </div>
                ${itemsHtml}
                <button class="select-btn ${isCurrent ? 'active' : ''}" data-id="${team.id}">
                    ${isCurrent ? (locales.currentTeam || 'EQUIPO ACTUAL') : (locales.btnSelect || 'UNIRSE AL EQUIPO')}
                </button>
            `;

            const btn = card.querySelector('.select-btn');
            if (!isCurrent) {
                btn.addEventListener('click', () => {
                    selectTeam(team.id);
                });
            }

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

    function selectTeam(teamId) {
        fetch(`https://${GetParentResourceName()}/selectTeam`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ teamId: teamId })
        });
    }
});
