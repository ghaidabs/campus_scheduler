/* =============================================================
   INSAT Campus Scheduler — Frontend Logic
   ============================================================= */

// ---- Constants -----------------------------------------------

const DAYS = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
const DAY_LABELS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
const PERIODS = [1, 2, 3, 5, 6, 7];
const PERIOD_LABELS = {
    1: { num: '1', time: '08:00 – 09:30' },
    2: { num: '2', time: '09:30 – 11:00' },
    3: { num: '3', time: '11:00 – 12:30' },
    5: { num: '4', time: '14:00 – 15:30' },
    6: { num: '5', time: '15:30 – 17:00' },
    7: { num: '6', time: '17:00 – 18:30' },
};

const ROOM_LABELS = {
    'amphi_a1': 'Amphi A1',  'amphi_a2': 'Amphi A2',
    'td_a1': 'TD A1',        'td_a2': 'TD A2',        'td_a3': 'TD A3',
    'it_b1': 'Info B1',      'it_b2': 'Info B2',      'it_b3': 'Info B3',  'it_b4': 'Info B4',
    'chem_c1': 'Chimie C1',  'chem_c2': 'Chimie C2',
    'bio_c1': 'Bio C1',
    'td_c1': 'TD C1',        'td_c2': 'TD C2',
};


// ---- State ---------------------------------------------------

let scheduleData = null;   // { mpi: [...], cba: [...], metrics: {...}, elapsed: n }
let activeTrack  = 'mpi';
let activeFilter = 'all';


// ---- DOM refs ------------------------------------------------

const $btnQuick    = document.getElementById('btn-quick');
const $btnOptimal  = document.getElementById('btn-optimal');
const $loading     = document.getElementById('loading');
const $error       = document.getElementById('error');
const $errorMsg    = document.getElementById('error-msg');
const $main        = document.getElementById('main-content');
const $timetable   = document.getElementById('timetable');
const $toast       = document.getElementById('toast');

const $mEnergy     = document.getElementById('m-energy');
const $mImbalance  = document.getElementById('m-imbalance');
const $mVariance   = document.getElementById('m-variance');
const $mScore      = document.getElementById('m-score');


// ---- Fetch schedule ------------------------------------------

async function fetchSchedule(endpoint) {
    // UI states
    $loading.classList.remove('hidden');
    $error.classList.add('hidden');
    $main.classList.add('hidden');
    $btnQuick.disabled = true;
    $btnOptimal.disabled = true;

    try {
        const res = await fetch(endpoint);
        const data = await res.json();

        if (!res.ok || data.error) {
            throw new Error(data.error || 'Server error');
        }

        scheduleData = data;
        renderAll();
        $main.classList.remove('hidden');
        showToast(`Schedule generated in ${data.elapsed}s ✓`);

    } catch (err) {
        $errorMsg.textContent = err.message;
        $error.classList.remove('hidden');
    } finally {
        $loading.classList.add('hidden');
        $btnQuick.disabled = false;
        $btnOptimal.disabled = false;
    }
}


// ---- Toast ---------------------------------------------------

function showToast(msg) {
    $toast.textContent = msg;
    $toast.classList.remove('hidden');
    // Force reflow before adding .show
    void $toast.offsetWidth;
    $toast.classList.add('show');
    setTimeout(() => {
        $toast.classList.remove('show');
        setTimeout(() => $toast.classList.add('hidden'), 350);
    }, 3500);
}


// ---- Render orchestrator -------------------------------------

function renderAll() {
    renderTimetable();
    renderMetrics();
}


// ---- Filter entries ------------------------------------------

function filterEntries(entries) {
    if (activeFilter === 'all') return entries;
    if (activeFilter === 'cm')  return entries.filter(e => e.session_type === 'CM');
    if (activeFilter === 'a')   return entries.filter(e => e.session_type === 'CM' || e.subgroup === 'A');
    if (activeFilter === 'b')   return entries.filter(e => e.session_type === 'CM' || e.subgroup === 'B');
    return entries;
}


// ---- Build timetable grid ------------------------------------

function renderTimetable() {
    if (!scheduleData) return;

    const entries = filterEntries(scheduleData[activeTrack] || []);
    $timetable.innerHTML = '';

    // Build lookup: key "day-period" → [entries]
    const lookup = {};
    for (const e of entries) {
        const key = `${e.day}-${e.period}`;
        (lookup[key] = lookup[key] || []).push(e);
    }

    // ---- Header row ----
    const corner = el('div', 'grid-header corner', '');
    $timetable.appendChild(corner);
    for (const label of DAY_LABELS) {
        $timetable.appendChild(el('div', 'grid-header', label));
    }

    // ---- Period rows ----
    let cardIndex = 0;
    for (let i = 0; i < PERIODS.length; i++) {
        const p = PERIODS[i];

        // Insert lunch break divider after period 3
        if (i === 3) {
            const lunch = el('div', 'grid-lunch', '☕  Lunch Break  ·  12:30 – 14:00');
            $timetable.appendChild(lunch);
        }

        // Time label
        const timeCell = document.createElement('div');
        timeCell.className = 'grid-time';
        timeCell.innerHTML = `
            <span>P${PERIOD_LABELS[p].num}</span>
            <span class="time-range">${PERIOD_LABELS[p].time}</span>
        `;
        $timetable.appendChild(timeCell);

        // Day cells
        for (const day of DAYS) {
            const cell = document.createElement('div');
            cell.className = 'grid-cell';

            const cellEntries = lookup[`${day}-${p}`] || [];
            for (const entry of cellEntries) {
                const card = buildCard(entry, cardIndex++);
                cell.appendChild(card);
            }
            $timetable.appendChild(cell);
        }
    }
}


// ---- Build a course card element -----------------------------

function buildCard(entry, index) {
    const typeClass = `type-${entry.session_type.toLowerCase()}`;
    const badgeClass = entry.session_type.toLowerCase();

    const card = document.createElement('div');
    card.className = `course-card ${typeClass}`;
    card.style.animationDelay = `${index * 0.03}s`;

    const badgeText = entry.subgroup
        ? `${entry.session_type}·${entry.subgroup}`
        : entry.session_type;

    const roomLabel = ROOM_LABELS[entry.room] || entry.room;

    card.innerHTML = `
        <div class="card-top">
            <span class="card-badge ${badgeClass}">${badgeText}</span>
            <span class="card-name" title="${entry.course_name}">${entry.course_name}</span>
        </div>
        <div class="card-details">
            <span class="card-room">📍 ${roomLabel}</span>
            <span class="card-session">s${entry.session}</span>
        </div>
    `;

    card.title = `${entry.course_name}\n${entry.session_type}${entry.subgroup ? ' – Group ' + entry.subgroup : ''}\nRoom: ${roomLabel}\nSession ${entry.session}`;

    return card;
}


// ---- Render metrics with count-up ----------------------------

function renderMetrics() {
    if (!scheduleData || !scheduleData.metrics) return;

    const m = scheduleData.metrics;
    animateValue($mEnergy,    0, m.energy,    800, 0);
    animateValue($mImbalance, 0, m.imbalance, 800, 0);
    animateValue($mVariance,  0, m.variance,  900, 4);
    animateValue($mScore,     0, m.score,     1000, 2);
}

function animateValue(element, start, end, duration, decimals) {
    const startTime = performance.now();
    function step(now) {
        const elapsed = now - startTime;
        const progress = Math.min(elapsed / duration, 1);
        // Ease-out cubic
        const eased = 1 - Math.pow(1 - progress, 3);
        const value = start + (end - start) * eased;
        element.textContent = decimals > 0 ? value.toFixed(decimals) : Math.round(value);
        if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
}


// ---- Helper: create element ----------------------------------

function el(tag, className, text) {
    const node = document.createElement(tag);
    if (className) node.className = className;
    if (text) node.textContent = text;
    return node;
}


// ---- Event listeners -----------------------------------------

$btnQuick.addEventListener('click', () => fetchSchedule('/api/schedule'));
$btnOptimal.addEventListener('click', () => fetchSchedule('/api/schedule/optimal'));

// Track tabs
document.querySelectorAll('#track-tabs .tab').forEach(tab => {
    tab.addEventListener('click', () => {
        document.querySelector('#track-tabs .tab.active')?.classList.remove('active');
        tab.classList.add('active');
        activeTrack = tab.dataset.track;
        renderTimetable();
    });
});

// Subgroup filters
document.querySelectorAll('#filters .filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelector('#filters .filter-btn.active')?.classList.remove('active');
        btn.classList.add('active');
        activeFilter = btn.dataset.filter;
        renderTimetable();
    });
});

// Footer year
document.getElementById('footer-year').textContent = new Date().getFullYear();
