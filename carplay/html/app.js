const app = document.getElementById('app');
const hudWidget = document.getElementById('hud-widget');
const hudCover = document.getElementById('hudCover');
const hudTitle = document.getElementById('hudTitle');
const hudArtist = document.getElementById('hudArtist');
const hudProgressFill = document.getElementById('hudProgressFill');
const hudEq = document.getElementById('hudEq');

const coverEl = document.getElementById('cover');
const ambientBg = document.getElementById('ambientBg');
const titleEl = document.getElementById('title');
const urlText = document.getElementById('urlText');
const queueList = document.getElementById('queueList');
const urlInput = document.getElementById('urlInput');
const message = document.getElementById('message');
const playBtn = document.getElementById('playBtn');
const playIcon = document.getElementById('playIcon');
const progress = document.getElementById('progress');
const volume = document.getElementById('volume');
const currentEl = document.getElementById('current');
const durationEl = document.getElementById('duration');
const dockClock = document.getElementById('dockClock');
const vehiclePlate = document.getElementById('vehiclePlate');

const viewMusic = document.getElementById('viewMusic');
const viewRadio = document.getElementById('viewRadio');
const viewPhone = document.getElementById('viewPhone');
const radioGrid = document.getElementById('radioGrid');

const tabMusicBtn = document.getElementById('tabMusicBtn');
const tabRadioBtn = document.getElementById('tabRadioBtn');
const tabPhoneBtn = document.getElementById('tabPhoneBtn');
const dockHomeBtn = document.getElementById('dockHomeBtn');

const shuffleBtn = document.getElementById('shuffleBtn');
const repeatBtn = document.getElementById('repeatBtn');
const muteBtn = document.getElementById('muteBtn');

let queue = [];
let currentIndex = -1;
let player = null;
let playerReady = false;
let progressTimer = null;
let eqInterval = null;
let isInVehicleState = false;
let isGameRadioActive = false;
let isDriverState = true;

let currentSyncedId = null;
let currentSyncedNetId = null;

function setDriverMode(isDriver) {
    isDriverState = isDriver;

    const interactiveBtns = [
        document.getElementById('addBtn'),
        document.getElementById('playBtn'),
        document.getElementById('nextBtn'),
        document.getElementById('prevBtn'),
        document.getElementById('shuffleBtn'),
        document.getElementById('repeatBtn'),
        document.getElementById('clearBtn'),
        progress
    ];

    if (!isDriver) {
        urlInput.disabled = true;
        urlInput.placeholder = '🔒 Controlado por el Conductor';
        interactiveBtns.forEach(btn => {
            if (btn) {
                btn.style.pointerEvents = 'none';
                btn.style.opacity = '0.4';
            }
        });
        if (message) {
            message.style.color = '#ff9f0a';
            message.textContent = '🔒 Modo Pasajero: Solo el conductor puede cambiar la música.';
        }
    } else {
        urlInput.disabled = false;
        urlInput.placeholder = 'Pegue enlace de Canción o Playlist (list=...)...';
        interactiveBtns.forEach(btn => {
            if (btn) {
                btn.style.pointerEvents = 'auto';
                btn.style.opacity = '1';
            }
        });
        if (message) {
            message.textContent = '';
        }
    }
}

let isMuted = false;
let lastVolume = 70;
let isShuffle = false;
let repeatMode = 0; // 0: Off, 1: Repeat All, 2: Repeat One

const h5Audio = document.getElementById('h5Player');
let lastStreamVideoId = null;

async function fetchAudioStream(videoId) {
    const endpoints = [
        `https://pipedapi.kavin.rocks/streams/${videoId}`,
        `https://inv.tux.pizza/api/v1/videos/${videoId}`,
        `https://invidious.drgns.space/api/v1/videos/${videoId}`
    ];
    for (const ep of endpoints) {
        try {
            const res = await fetch(ep);
            if (res.ok) {
                const data = await res.json();
                if (Array.isArray(data.audioStreams) && data.audioStreams.length > 0) {
                    return data.audioStreams[0].url;
                }
                if (Array.isArray(data.adaptiveFormats) && data.adaptiveFormats.length > 0) {
                    const audio = data.adaptiveFormats.find(f => f && f.type && f.type.includes('audio'));
                    if (audio && audio.url) return audio.url;
                }
            }
        } catch (_) {}
    }
    return null;
}

async function playDualAudio(videoId, startPos = 0, vol = 70) {
    const numVol = isMuted ? 0 : Number(vol);
    const normalizedVol = Math.max(0, Math.min(1, numVol / 100));

    if (playerReady && player && typeof player.loadVideoById === 'function') {
        try {
            player.loadVideoById(videoId, startPos);
            player.setVolume(numVol);
            player.playVideo();
        } catch (_) {}
    }

    if (h5Audio && lastStreamVideoId !== videoId) {
        lastStreamVideoId = videoId;
        const streamUrl = await fetchAudioStream(videoId);
        if (streamUrl) {
            h5Audio.src = streamUrl;
            h5Audio.currentTime = startPos;
            h5Audio.volume = normalizedVol;
            h5Audio.play().catch(() => {});
        }
    } else if (h5Audio && h5Audio.src) {
        h5Audio.currentTime = startPos;
        h5Audio.volume = normalizedVol;
        h5Audio.play().catch(() => {});
    }
}

function updateDualVolume(vol) {
    const numVol = isMuted ? 0 : Number(vol);
    const normalizedVol = Math.max(0, Math.min(1, numVol / 100));

    if (playerReady && player && typeof player.setVolume === 'function') {
        try { player.setVolume(numVol); } catch (_) {}
    }
    if (h5Audio) {
        h5Audio.volume = normalizedVol;
    }
}

function syncDualTime(targetPos) {
    if (playerReady && player && typeof player.getCurrentTime === 'function') {
        try {
            const cur = player.getCurrentTime();
            if (Math.abs(cur - targetPos) > 3.5) player.seekTo(targetPos, true);
        } catch (_) {}
    }
    if (h5Audio && !h5Audio.paused && h5Audio.duration > 0) {
        if (Math.abs(h5Audio.currentTime - targetPos) > 3.5) {
            h5Audio.currentTime = targetPos;
        }
    }
}

function stopDualAudio() {
    lastStreamVideoId = null;
    if (playerReady && player && typeof player.pauseVideo === 'function') {
        try { player.pauseVideo(); } catch (_) {}
    }
    if (h5Audio) {
        h5Audio.pause();
        h5Audio.src = '';
    }
}

const gtaRadioStations = [
    { raw: "RADIO_12_REGGAE", name: "Blue Ark" },
    { raw: "RADIO_01_CLASS_ROCK", name: "Los Santos Rock Radio" },
    { raw: "RADIO_02_POP", name: "Non-Stop-Pop FM" },
    { raw: "RADIO_03_HIPHOP", name: "Radio Los Santos" },
    { raw: "RADIO_09_HIPHOP_OLD", name: "West Coast Classics" },
    { raw: "RADIO_16_SILVERLAKE", name: "Radio Mirror Park" },
    { raw: "RADIO_14_DANCE_02", name: "FlyLo FM" },
    { raw: "RADIO_21_SLC", name: "Blonded Los Santos 97.8 FM" },
    { raw: "RADIO_36_MOTOMAMI", name: "MOTOMAMI Los Santos" },
    { raw: "RADIO_04_PUNK", name: "Channel X" },
    { raw: "RADIO_06_COUNTRY", name: "Rebel Radio" },
    { raw: "RADIO_07_DANCE_01", name: "Soulwax FM" },
    { raw: "RADIO_08_MEXICAN", name: "East Los FM" },
    { raw: "RADIO_13_JAZZ", name: "Worldwide FM" },
    { raw: "RADIO_15_MOTOWN", name: "The Lowdown 91.1" },
    { raw: "RADIO_17_FUNK", name: "Space 103.2" },
    { raw: "RADIO_18_90S_ROCK", name: "Vinewood Boulevard Radio" },
    { raw: "RADIO_20_THELAB", name: "The Lab" }
];

function nui(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function updateClock() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    if (dockClock) dockClock.textContent = `${hours}:${minutes}`;
}
setInterval(updateClock, 1000);
updateClock();

function switchTab(activeBtn, activeView) {
    [tabMusicBtn, tabRadioBtn, tabPhoneBtn].forEach(btn => btn.classList.remove('active'));
    [viewMusic, viewRadio, viewPhone].forEach(v => v.classList.add('hidden'));

    if (activeBtn) activeBtn.classList.add('active');
    if (activeView) activeView.classList.remove('hidden');
}

dockHomeBtn.onclick = () => switchTab(tabMusicBtn, viewMusic);
tabMusicBtn.onclick = () => switchTab(tabMusicBtn, viewMusic);
tabRadioBtn.onclick = () => {
    switchTab(tabRadioBtn, viewRadio);
    renderRadioGrid();
};
tabPhoneBtn.onclick = () => switchTab(tabPhoneBtn, viewPhone);

function renderRadioGrid() {
    radioGrid.innerHTML = '';
    gtaRadioStations.forEach(st => {
        const item = document.createElement('div');
        item.className = 'radio-card-item';

        const icon = document.createElement('div');
        icon.className = 'radio-icon-box';
        icon.textContent = '📻';

        const name = document.createElement('div');
        name.className = 'radio-name-text';
        name.textContent = st.name;

        item.append(icon, name);
        item.onclick = () => {
            if (!isDriverState) {
                if (message) {
                    message.style.color = '#ff9f0a';
                    message.textContent = '🔒 Solo el conductor puede cambiar de emisora.';
                }
                return;
            }
            player?.stopVideo();
            currentIndex = -1;
            renderQueue();

            nui('setRadioStation', { stationName: st.raw });
            hudTitle.textContent = st.name;
            hudArtist.textContent = 'Radio de GTA V';
            titleEl.textContent = st.name;
            urlText.textContent = 'Radio de GTA V';
            hudCover.style.backgroundImage = 'none';
            hudCover.innerHTML = '<span class="hud-note">📻</span>';
            coverEl.style.backgroundImage = 'none';
            coverEl.innerHTML = '<span class="cover-fallback">📻</span>';
            updateEqAnimation(true);
            switchTab(tabMusicBtn, viewMusic);
        };
        radioGrid.appendChild(item);
    });
}

function extractYouTubeId(url) {
    try {
        const u = new URL(url);
        if (u.hostname.includes('youtu.be')) {
            return u.pathname.replace('/', '').split('?')[0];
        }
        if (u.hostname.includes('youtube.com')) {
            if (u.pathname === '/watch') return u.searchParams.get('v');
            if (u.pathname.startsWith('/shorts/')) return u.pathname.split('/')[2];
            if (u.pathname.startsWith('/embed/')) return u.pathname.split('/')[2];
        }
    } catch (_) {}
    return null;
}

function extractYouTubePlaylistId(url) {
    try {
        const u = new URL(url);
        if (u.hostname.includes('youtube.com') || u.hostname.includes('youtu.be')) {
            const listParam = u.searchParams.get('list');
            if (listParam) return listParam;
        }
    } catch (_) {}
    return null;
}

function getThumbnailUrl(id) {
    return id ? `https://img.youtube.com/vi/${id}/mqdefault.jpg` : '';
}

async function fetchMetadata(url, videoId) {
    try {
        const response = await fetch(`https://noembed.com/embed?url=https://www.youtube.com/watch?v=${videoId}`);
        if (response.ok) {
            const data = await response.json();
            if (data && data.title) {
                return {
                    title: data.title,
                    author: data.author_name || 'YouTube'
                };
            }
        }
    } catch (_) {}

    return {
        title: 'Audio de YouTube',
        author: 'Reproduciendo desde YouTube'
    };
}

async function fetchPlaylistItems(playlistId) {
    const maxTracks = 10;
    const endpoints = [
        `https://inv.tux.pizza/api/v1/playlists/${playlistId}`,
        `https://invidious.drgns.space/api/v1/playlists/${playlistId}`,
        `https://pipedapi.kavin.rocks/playlists/${playlistId}`
    ];

    for (const ep of endpoints) {
        try {
            const res = await fetch(ep);
            if (res.ok) {
                const data = await res.json();
                
                // Invidious format (FIFO: first 10 items in order)
                if (data && Array.isArray(data.videos) && data.videos.length > 0) {
                    return data.videos.slice(0, maxTracks).map(v => ({
                        id: v.videoId,
                        url: `https://www.youtube.com/watch?v=${v.videoId}`,
                        title: v.title || 'Canción de Playlist',
                        author: v.author || 'YouTube'
                    }));
                }

                // Piped format (FIFO: first 10 items in order)
                if (data && Array.isArray(data.relatedStreams) && data.relatedStreams.length > 0) {
                    return data.relatedStreams
                        .slice(0, maxTracks)
                        .map(v => {
                            const vid = extractYouTubeId(`https://www.youtube.com${v.url}`);
                            return {
                                id: vid,
                                url: `https://www.youtube.com/watch?v=${vid}`,
                                title: v.title || 'Canción de Playlist',
                                author: v.uploaderName || 'YouTube'
                            };
                        })
                        .filter(item => item.id);
                }
            }
        } catch (_) {}
    }

    // Fallback: Use YouTube iframe API if player is ready (Strict FIFO indexing)
    if (playerReady && player && typeof player.loadPlaylist === 'function') {
        try {
            player.loadPlaylist({ list: playlistId, listType: 'playlist' });
            await new Promise(r => setTimeout(r, 800));
            const list = player.getPlaylist();
            if (Array.isArray(list) && list.length > 0) {
                const targetList = list.slice(0, maxTracks);
                const items = await Promise.all(targetList.map(async (vid) => {
                    const meta = await fetchMetadata('', vid);
                    return {
                        id: vid,
                        url: `https://www.youtube.com/watch?v=${vid}`,
                        title: meta.title,
                        author: meta.author
                    };
                }));
                return items.filter(item => item.id);
            }
        } catch (_) {}
    }

    return [];
}

function formatTime(seconds) {
    if (!Number.isFinite(seconds)) return '0:00';
    seconds = Math.max(0, Math.floor(seconds));
    return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, '0')}`;
}

function updateEqAnimation(isPlaying) {
    const spans = hudEq.querySelectorAll('span');
    if (isPlaying) {
        hudEq.classList.remove('paused');
        if (!eqInterval) {
            eqInterval = setInterval(() => {
                spans.forEach(span => {
                    span.style.height = `${Math.floor(Math.random() * 9) + 3}px`;
                });
            }, 180);
        }
    } else {
        hudEq.classList.add('paused');
        if (eqInterval) {
            clearInterval(eqInterval);
            eqInterval = null;
        }
        spans.forEach(span => {
            span.style.height = '3px';
        });
    }
}

function broadcastSync(overrideIsPlaying = null) {
    if (currentIndex < 0 || !queue[currentIndex]) {
        nui('syncTrackState', { isPlaying: false });
        return;
    }

    const item = queue[currentIndex];
    const isPlaying = (overrideIsPlaying !== null) 
        ? overrideIsPlaying 
        : (playerReady && player ? player.getPlayerState() === YT.PlayerState.PLAYING : false);

    const currentTime = (playerReady && player && typeof player.getCurrentTime === 'function') ? player.getCurrentTime() : (h5Audio ? h5Audio.currentTime : 0);
    const duration = (playerReady && player && typeof player.getDuration === 'function') ? player.getDuration() : (h5Audio ? h5Audio.duration : 0);

    nui('syncTrackState', {
        id: item.id,
        title: item.title,
        author: item.author,
        url: item.url,
        isPlaying: isPlaying,
        baseVolume: Number(volume.value),
        position: currentTime,
        duration: duration
    });
}

function renderQueue() {
    queueList.innerHTML = '';

    if (!queue.length) {
        queueList.innerHTML = '<div style="opacity:.5;padding:12px 0;font-size:11px;text-align:center;">La cola está vacía.</div>';
        return;
    }

    queue.forEach((item, index) => {
        const row = document.createElement('div');
        row.className = `queue-item ${index === currentIndex ? 'active' : ''}`;

        const indexEl = document.createElement('div');
        indexEl.className = 'queue-index';
        indexEl.textContent = index + 1;

        const thumb = document.createElement('div');
        thumb.className = 'queue-thumb';
        if (item.id) {
            thumb.style.backgroundImage = `url('${getThumbnailUrl(item.id)}')`;
            thumb.textContent = '';
        } else {
            thumb.textContent = '♪';
        }

        const info = document.createElement('div');
        info.className = 'queue-info';

        const tTitle = document.createElement('div');
        tTitle.className = 'queue-title-text';
        tTitle.textContent = item.title || 'Audio de YouTube';

        const tSub = document.createElement('div');
        tSub.className = 'queue-sub-text';
        tSub.textContent = item.author || 'Reproduciendo desde YouTube';

        info.append(tTitle, tSub);

        const removeBtn = document.createElement('button');
        removeBtn.className = 'remove-btn';
        removeBtn.textContent = '×';
        removeBtn.onclick = (e) => {
            e.stopPropagation();
            removeFromQueue(index);
        };

        row.append(indexEl, thumb, info, removeBtn);
        row.onclick = () => playIndex(index);

        queueList.appendChild(row);
    });
}

async function addUrl() {
    if (!isDriverState) {
        message.style.color = '#ff9f0a';
        message.textContent = '🔒 Solo el conductor puede añadir canciones.';
        return;
    }

    const url = urlInput.value.trim();
    if (!url) return;

    const playlistId = extractYouTubePlaylistId(url);
    const videoId = extractYouTubeId(url);

    if (playlistId) {
        message.style.color = 'rgba(255,255,255,0.7)';
        message.textContent = 'Cargando las primeras 10 canciones de la Playlist (FIFO)...';

        let playlistItems = await fetchPlaylistItems(playlistId);

        if (playlistItems && playlistItems.length > 0) {
            playlistItems = playlistItems.slice(0, 10);
            const isInitialEmpty = (queue.length === 0);
            const startIndex = queue.length;

            playlistItems.forEach(item => queue.push(item));
            urlInput.value = '';
            message.style.color = '#30d158';
            message.textContent = `Se añadieron ${playlistItems.length} canciones (Cola FIFO).`;
            renderQueue();

            if (isInitialEmpty || currentIndex === -1) {
                playIndex(startIndex);
            }
            return;
        } else if (!videoId) {
            message.style.color = '#ff453a';
            message.textContent = 'No se pudieron cargar las canciones de la Playlist.';
            return;
        }
    }

    if (!videoId) {
        message.style.color = '#ff453a';
        message.textContent = 'Enlace de YouTube no válido.';
        return;
    }

    message.style.color = 'rgba(255,255,255,0.7)';
    message.textContent = 'Obteniendo canción...';

    const meta = await fetchMetadata(url, videoId);

    const newItem = {
        id: videoId,
        url: url,
        title: meta.title,
        author: meta.author
    };

    queue.push(newItem);
    urlInput.value = '';
    message.style.color = '#30d158';
    message.textContent = 'Añadido a la cola de CarPlay.';
    renderQueue();

    if (currentIndex === -1) {
        playIndex(0);
    }
}

function removeFromQueue(index) {
    if (index === currentIndex) {
        player?.stopVideo();
        currentIndex = -1;
        resetTrackUI();
        broadcastSync(false);
    } else if (index < currentIndex) {
        currentIndex--;
    }

    queue.splice(index, 1);
    renderQueue();
}

function resetTrackUI() {
    isGameRadioActive = false;
    currentSyncedId = null;
    currentSyncedNetId = null;
    titleEl.textContent = 'Sin reproducción';
    urlText.textContent = 'Reproduciendo en iFruit';
    hudTitle.textContent = 'Sin reproducción';
    hudArtist.textContent = 'Reproduciendo en iFruit';

    coverEl.style.backgroundImage = 'none';
    coverEl.innerHTML = '<span class="cover-fallback">♪</span>';
    hudCover.style.backgroundImage = 'none';
    hudCover.innerHTML = '<span class="hud-note">♪</span>';
    ambientBg.style.backgroundImage = 'none';

    progress.value = 0;
    hudProgressFill.style.width = '0%';
    currentEl.textContent = '0:00';
    durationEl.textContent = '0:00';

    playIcon.textContent = '▶';
    updateEqAnimation(false);
}

function triggerTrackChangeAnimation() {
    const animEls = [titleEl, urlText, coverEl, hudTitle, hudArtist, hudCover];
    animEls.forEach(el => el && el.classList.add('track-changing'));

    if (hudWidget) {
        hudWidget.classList.remove('hud-pulse');
        void hudWidget.offsetWidth;
        hudWidget.classList.add('hud-pulse');
    }

    setTimeout(() => {
        animEls.forEach(el => el && el.classList.remove('track-changing'));
        if (coverEl) {
            coverEl.classList.add('track-bump');
            setTimeout(() => coverEl.classList.remove('track-bump'), 400);
        }
        if (hudCover) {
            hudCover.classList.add('track-bump');
            setTimeout(() => hudCover.classList.remove('track-bump'), 400);
        }
    }, 160);
}

function playIndex(index) {
    if (!queue[index]) return;

    isGameRadioActive = false;
    currentIndex = index;
    const item = queue[index];
    const thumbUrl = getThumbnailUrl(item.id);

    triggerTrackChangeAnimation();

    titleEl.textContent = item.title;
    urlText.textContent = item.author || 'Reproduciendo en iFruit';
    hudTitle.textContent = item.title;
    hudArtist.textContent = item.author || 'Reproduciendo en iFruit';

    if (thumbUrl) {
        coverEl.style.backgroundImage = `url('${thumbUrl}')`;
        coverEl.innerHTML = '';
        hudCover.style.backgroundImage = `url('${thumbUrl}')`;
        hudCover.innerHTML = '';
        ambientBg.style.backgroundImage = `url('${thumbUrl}')`;
    }

    renderQueue();
    playDualAudio(item.id, 0, volume.value);
    broadcastSync(true);
}

function onTrackEnded() {
    if (!queue.length || currentIndex < 0) return;

    // Repeat One (repeatMode === 2): repeat current track
    if (repeatMode === 2) {
        playIndex(currentIndex);
        return;
    }

    // Shuffle: pick a random other track
    if (isShuffle && queue.length > 1) {
        let rand = Math.floor(Math.random() * queue.length);
        if (rand === currentIndex) rand = (rand + 1) % queue.length;
        playIndex(rand);
        return;
    }

    // Next track exists in queue
    if (currentIndex < queue.length - 1) {
        playIndex(currentIndex + 1);
        return;
    }

    // End of queue reached:
    if (repeatMode === 1) {
        // Repeat All: loop back to first track
        playIndex(0);
    } else {
        // Repeat OFF (default 0): STOP PLAYBACK AND DO NOT LOOP!
        stopDualAudio();
        currentIndex = -1;
        resetTrackUI();
        renderQueue();
        broadcastSync(false);
    }
}

function playNext() {
    if (!queue.length) return;

    if (repeatMode === 2 && currentIndex >= 0) {
        playIndex(currentIndex);
        return;
    }

    if (isShuffle && queue.length > 1) {
        let rand = Math.floor(Math.random() * queue.length);
        if (rand === currentIndex) rand = (rand + 1) % queue.length;
        playIndex(rand);
        return;
    }

    playIndex((currentIndex + 1) % queue.length);
}

function playPrevious() {
    if (!queue.length) return;
    playIndex((currentIndex - 1 + queue.length) % queue.length);
}

function togglePlay() {
    if (currentIndex < 0) return;

    const isPlaying = (playerReady && player) ? player.getPlayerState() === YT.PlayerState.PLAYING : (h5Audio && !h5Audio.paused);
    if (isPlaying) {
        stopDualAudio();
        broadcastSync(false);
    } else {
        if (queue[currentIndex]) {
            const currentPos = (playerReady && player) ? player.getCurrentTime() : (h5Audio ? h5Audio.currentTime : 0);
            playDualAudio(queue[currentIndex].id, currentPos, volume.value);
            broadcastSync(true);
        }
    }
}

shuffleBtn.onclick = () => {
    isShuffle = !isShuffle;
    shuffleBtn.classList.toggle('active', isShuffle);
};

repeatBtn.onclick = () => {
    repeatMode = (repeatMode + 1) % 3; // 0: Off, 1: Repeat All, 2: Repeat One
    repeatBtn.classList.toggle('active', repeatMode > 0);
    repeatBtn.title = repeatMode === 2 ? 'Repetir Una' : (repeatMode === 1 ? 'Repetir Todo' : 'Modo Repetir');
};

muteBtn.onclick = () => {
    isMuted = !isMuted;
    if (isMuted) {
        lastVolume = Number(volume.value);
        volume.value = 0;
        if (playerReady && player) player.setVolume(0);
    } else {
        volume.value = lastVolume || 70;
        if (playerReady && player) player.setVolume(Number(volume.value));
    }
    broadcastSync();
};

function updatePlayerUI() {
    if (!playerReady) return;

    const state = player.getPlayerState();
    const isPlaying = (state === YT.PlayerState.PLAYING);

    if (isPlaying) {
        playIcon.textContent = '❚❚';
    } else {
        playIcon.textContent = '▶';
    }
    updateEqAnimation(isPlaying);

    try {
        const vData = player.getVideoData();
        if (vData && vData.title && queue[currentIndex]) {
            if (queue[currentIndex].title !== vData.title) {
                queue[currentIndex].title = vData.title;
                if (vData.author) queue[currentIndex].author = vData.author;
                titleEl.textContent = vData.title;
                hudTitle.textContent = vData.title;
                urlText.textContent = vData.author || 'Reproduciendo desde YouTube';
                renderQueue();
                broadcastSync();
            }
        }
    } catch (_) {}

    const total = player.getDuration();
    const now = player.getCurrentTime();

    if (total > 0) {
        const pct = (now / total) * 100;
        progress.value = pct;
        hudProgressFill.style.width = `${pct}%`;
        currentEl.textContent = formatTime(now);
        durationEl.textContent = formatTime(total);
    }
}

function loadYouTubeAPI() {
    if (document.getElementById('youtube-api')) return;

    const script = document.createElement('script');
    script.id = 'youtube-api';
    script.src = 'https://www.youtube.com/iframe_api';
    document.head.appendChild(script);
}

window.onYouTubeIframeAPIReady = function () {
    player = new YT.Player('youtubePlayer', {
        height: '1',
        width: '1',
        videoId: (window.pendingVideo && window.pendingVideo.id) ? window.pendingVideo.id : (typeof window.pendingVideo === 'string' ? window.pendingVideo : ''),
        playerVars: {
            autoplay: 1,
            controls: 0,
            playsinline: 1,
            rel: 0,
            enablejsapi: 1
        },
        events: {
            onReady: () => {
                playerReady = true;
                if (window.pendingVideo) {
                    const videoObj = (typeof window.pendingVideo === 'object') ? window.pendingVideo : { id: window.pendingVideo, startPos: 0, volume: 70 };
                    player.loadVideoById(videoObj.id, videoObj.startPos || 0);
                    player.setVolume(isMuted ? 0 : (videoObj.volume || Number(volume.value)));
                    window.pendingVideo = null;
                } else {
                    player.setVolume(isMuted ? 0 : Number(volume.value));
                }

                if (progressTimer) clearInterval(progressTimer);
                progressTimer = setInterval(updatePlayerUI, 500);
            },
            onStateChange: (event) => {
                // CRITICAL FIX: Only the driver with active queue handles track transitions and sync!
                if (currentIndex >= 0 && isDriverState) {
                    if (event.data === YT.PlayerState.ENDED) {
                        onTrackEnded();
                    } else if (event.data === YT.PlayerState.PLAYING) {
                        broadcastSync(true);
                    } else if (event.data === YT.PlayerState.PAUSED) {
                        broadcastSync(false);
                    }
                }
                updatePlayerUI();
            }
        }
    });
};

document.getElementById('addBtn').onclick = addUrl;
document.getElementById('playBtn').onclick = togglePlay;
document.getElementById('nextBtn').onclick = playNext;
document.getElementById('prevBtn').onclick = playPrevious;
document.getElementById('closeBtn').onclick = () => nui('close');
document.getElementById('hudOpenBtn').onclick = () => {
    nui('getVehicle');
    app.classList.remove('hidden');
    hudWidget.classList.add('hidden');
};

document.getElementById('clearBtn').onclick = () => {
    queue = [];
    currentIndex = -1;
    stopDualAudio();
    resetTrackUI();
    renderQueue();
    broadcastSync(false);
};

volume.oninput = () => {
    isMuted = false;
    updateDualVolume(Number(volume.value));
    broadcastSync();
};

progress.oninput = () => {
    const targetPos = (Number(progress.value) / 100) * (playerReady && player ? player.getDuration() : (h5Audio ? h5Audio.duration : 0));
    syncDualTime(targetPos);
};

urlInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') addUrl();
});

if (h5Audio) {
    h5Audio.addEventListener('ended', () => {
        if (currentIndex >= 0 && isDriverState) {
            onTrackEnded();
        }
    });
}

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === 'open') {
        app.classList.remove('hidden');
        hudWidget.classList.add('hidden');
        nui('getVehicle').then(res => res?.json?.()).then(vData => {
            if (vData) {
                const tag = vData.isDriver ? '' : ' (Pasajero)';
                if (vData.vehicle) {
                    vehiclePlate.textContent = `${vData.modelName || 'Vehículo'} [${vData.vehicle}]${tag}`;
                }
                setDriverMode(vData.isDriver);
            }
        });
    }

    if (data.action === 'close') {
        app.classList.add('hidden');
        if (isInVehicleState) {
            hudWidget.classList.remove('hidden');
        }
    }

    if (data.action === 'setVehicleState') {
        isInVehicleState = data.inVehicle;
        if (isInVehicleState) {
            if (app.classList.contains('hidden')) {
                hudWidget.classList.remove('hidden');
            }
        } else {
            hudWidget.classList.add('hidden');
            app.classList.add('hidden');
        }
    }

    if (data.action === 'updateGameRadio') {
        const isYouTubePlaying = (playerReady && player && player.getPlayerState() === YT.PlayerState.PLAYING) || (h5Audio && !h5Audio.paused);
        if (data.isRadioOn && !isYouTubePlaying) {
            if (hudTitle.textContent !== data.stationName) {
                triggerTrackChangeAnimation();
            }
            isGameRadioActive = true;
            hudTitle.textContent = data.stationName;
            hudArtist.textContent = 'Radio de GTA V';
            titleEl.textContent = data.stationName;
            urlText.textContent = 'Radio de GTA V';
            hudCover.style.backgroundImage = 'none';
            hudCover.innerHTML = '<span class="hud-note">📻</span>';
            coverEl.style.backgroundImage = 'none';
            coverEl.innerHTML = '<span class="cover-fallback">📻</span>';
            updateEqAnimation(true);
        } else if (!data.isRadioOn && isGameRadioActive) {
            isGameRadioActive = false;
            if (!isYouTubePlaying && currentIndex < 0) {
                resetTrackUI();
            }
        }
    }

    if (data.action === 'setSpatialAttenuation') {
        const track = data.trackData;
        const vol = isMuted ? 0 : (data.volume || 0);
        const isDriver = data.isDriver;
        const isPassenger = data.isPassenger;

        // DRIVER with their own queue active: do NOT override their volume or playback
        // The driver controls their own audio entirely via the CarPlay UI
        if (isDriver && currentIndex >= 0) {
            return;
        }

        // PASSENGER or NEARBY PLAYER: handle synced audio from the vehicle
        if (track && track.id && track.isPlaying && vol > 0) {
            // Calculate what second of the song should be playing right now
            // serverTime = os.time() when the track started on the server
            // startPosition = the position in seconds when the track started
            // estimatedServerTime = client's estimate of current server time
            const elapsed = (data.estimatedServerTime && track.serverTime)
                ? Math.max(0, data.estimatedServerTime - track.serverTime)
                : 0;
            const targetPos = (track.startPosition || 0) + elapsed;

            // Stop playback if track duration has already passed
            if (track.duration && track.duration > 0 && targetPos >= track.duration + 1.5) {
                if (currentSyncedId !== null) {
                    currentSyncedId = null;
                    currentSyncedNetId = null;
                    stopDualAudio();
                    resetTrackUI();
                }
                return;
            }

            if (currentSyncedId !== track.id) {
                // New track - load it
                currentSyncedId = track.id;
                currentSyncedNetId = data.netId;

                triggerTrackChangeAnimation();
                titleEl.textContent = track.title || 'Audio de YouTube';
                urlText.textContent = track.author || 'Reproduciendo en iFruit';
                hudTitle.textContent = track.title || 'Audio de YouTube';
                hudArtist.textContent = track.author || 'Reproduciendo en iFruit';

                const thumbUrl = getThumbnailUrl(track.id);
                if (thumbUrl) {
                    coverEl.style.backgroundImage = `url('${thumbUrl}')`;
                    coverEl.innerHTML = '';
                    hudCover.style.backgroundImage = `url('${thumbUrl}')`;
                    hudCover.innerHTML = '';
                    ambientBg.style.backgroundImage = `url('${thumbUrl}')`;
                }

                updateEqAnimation(true);
                playDualAudio(track.id, targetPos, vol);
            } else {
                // Same track - update volume and sync time
                updateDualVolume(vol);
                syncDualTime(targetPos);

                if (h5Audio && h5Audio.paused && !h5Audio.ended && vol > 0 && h5Audio.src) {
                    h5Audio.play().catch(() => {});
                }

                hudTitle.textContent = track.title || 'Audio de YouTube';
                hudArtist.textContent = track.author || 'Reproduciendo en iFruit';
                updateEqAnimation(true);
            }

            // If passenger in vehicle, ensure HUD widget is visible
            if ((isPassenger || data.isInVehicle) && app.classList.contains('hidden')) {
                hudWidget.classList.remove('hidden');
            }

            // If passenger, lock controls so they can't change the music
            if (isPassenger) {
                setDriverMode(false);
            }
        } else {
            // No vehicle nearby is playing audio or out of range
            if (currentSyncedId !== null) {
                currentSyncedId = null;
                currentSyncedNetId = null;
                stopDualAudio();
                resetTrackUI();
            }
        }
    }
});

renderQueue();
loadYouTubeAPI();
