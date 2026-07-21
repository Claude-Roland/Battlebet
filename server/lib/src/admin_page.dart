// Schlanke Personal-Oberflaeche (Admin) — als HTML-Konstante in den Server
// kompiliert (das Backend-Image ist FROM scratch, also kein Datei-Ausliefern).
// Wird von routes/admin/index.dart (GET /admin) und, in Produktion, von
// routes/index.dart bei Host admin.battlebet.app am Root ausgeliefert.
//
// Die Seite spricht das GLEICHE Backend ueber RELATIVE Pfade an (kein CORS):
// POST /auth/login  (Personal-Login, prueft isStaff) und POST /admin/bets
// (kuratierte Wette mit freiem Namen). v1: nur Anlegen + Benennen.

const String adminHtml = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>BattleBet · Staff Console</title>
<style>
  :root { --bg:#12161c; --card:#1b212b; --line:#2b333f; --muted:#8b97a7;
          --text:#e7ecf3; --orange:#e8622a; --price:#4ba3ff; --gain:#43c59e; }
  * { box-sizing: border-box; }
  body { margin:0; background:var(--bg); color:var(--text);
         font:15px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif; }
  header { background:var(--orange); color:#fff; padding:14px 20px; font-weight:700;
           display:flex; align-items:center; justify-content:space-between; }
  header small { font-weight:400; opacity:.9; }
  main { max-width:560px; margin:24px auto; padding:0 16px; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:12px;
          padding:20px; margin-bottom:18px; }
  h2 { margin:0 0 14px; font-size:16px; }
  label { display:block; font-size:12px; color:var(--muted); margin:12px 0 4px; }
  input, select { width:100%; padding:10px 12px; background:#0e1218; color:var(--text);
          border:1px solid var(--line); border-radius:8px; font-size:15px; }
  .row { display:flex; gap:12px; } .row > div { flex:1; }
  button { margin-top:16px; width:100%; padding:12px; border:0; border-radius:9px;
           background:var(--orange); color:#fff; font-size:15px; font-weight:700; cursor:pointer; }
  button.secondary { background:transparent; border:1px solid var(--line); color:var(--muted);
           margin-top:0; width:auto; padding:6px 12px; font-size:13px; }
  .msg { margin-top:14px; padding:10px 12px; border-radius:8px; font-size:14px; display:none; }
  .msg.err { background:#3a1e1e; color:#ff9a9a; display:block; }
  .msg.ok  { background:#173129; color:var(--gain); display:block; }
  .who { display:flex; align-items:center; justify-content:space-between; gap:12px; }
  .hidden { display:none; }
  .hint { color:var(--muted); font-size:12px; margin-top:4px; }
</style>
</head>
<body>
<header>
  <span>BattleBet · Staff Console</span>
  <small>test phase · test credits</small>
</header>
<main>

  <div class="card" id="loginCard">
    <h2>Staff login</h2>
    <label>Username</label>
    <input id="lgUser" autocomplete="username">
    <label>Password</label>
    <input id="lgPass" type="password" autocomplete="current-password">
    <button id="lgBtn">Log in</button>
    <div class="msg" id="lgMsg"></div>
  </div>

  <div class="card hidden" id="workCard">
    <div class="who">
      <div>Signed in as <b id="whoName">—</b> <span style="color:var(--gain)">· staff</span></div>
      <button class="secondary" id="logoutBtn">Log out</button>
    </div>
  </div>

  <div class="card hidden" id="createCard">
    <h2>Create curated bet</h2>
    <label>Name (shown verbatim — this is the whole point of a curated bet)</label>
    <input id="cName" placeholder="e.g. Summer Streak Challenge">
    <div class="row">
      <div>
        <label>Sport</label>
        <select id="cSport">
          <option value="0">jogging</option>
          <option value="1">running</option>
          <option value="5">hiking</option>
        </select>
      </div>
      <div>
        <label>Tier</label>
        <select id="cTier">
          <option value="0">Tier 1 (up to 500)</option>
          <option value="1">Tier 2 (up to 2000)</option>
          <option value="2">Unlimited</option>
        </select>
      </div>
    </div>
    <div class="row">
      <div><label>Distance (km)</label><input id="cDist" type="number" min="0.1" step="0.1" value="5"></div>
      <div><label>Runs / week</label><input id="cIpw" type="number" min="1" max="21" step="1" value="3"></div>
    </div>
    <div class="row">
      <div><label>Duration (weeks)</label><input id="cWeeks" type="number" min="1" step="1" value="4"></div>
      <div><label>Stake (€)</label><input id="cStake" type="number" min="0.01" step="0.5" value="10"></div>
    </div>
    <div class="hint">Curated bets carry no auto-name. You (staff) do not join or stake — users join later.</div>
    <button id="createBtn">Create curated bet</button>
    <div class="msg" id="createMsg"></div>
  </div>

</main>
<script>
  let token = null;
  const $ = (id) => document.getElementById(id);
  function show(el, on){ el.classList.toggle('hidden', !on); }
  function msg(el, text, kind){ el.textContent = text; el.className = 'msg ' + kind; }

  async function api(path, body, auth){
    const headers = {'Content-Type':'application/json'};
    if (auth && token) headers['Authorization'] = 'Bearer ' + token;
    const res = await fetch(path, {method:'POST', headers, body: JSON.stringify(body)});
    let data = {};
    try { data = await res.json(); } catch(e) {}
    return { ok: res.ok, status: res.status, data };
  }

  $('lgBtn').onclick = async () => {
    const u = $('lgUser').value.trim(), p = $('lgPass').value;
    if (!u || !p) { msg($('lgMsg'),'Enter username and password.','err'); return; }
    const r = await api('/auth/login', {username:u, password:p}, false);
    if (!r.ok) { msg($('lgMsg'), r.data.error || 'Login failed.', 'err'); return; }
    if (!r.data.user || !r.data.user.isStaff) {
      msg($('lgMsg'),'This account is not staff. Ask an admin to promote it.','err'); return;
    }
    token = r.data.token;
    $('whoName').textContent = r.data.user.displayName || r.data.user.username;
    show($('loginCard'), false); show($('workCard'), true); show($('createCard'), true);
  };

  $('logoutBtn').onclick = () => {
    token = null;
    show($('workCard'), false); show($('createCard'), false); show($('loginCard'), true);
    $('lgPass').value = ''; msg($('lgMsg'),'','');
  };

  $('createBtn').onclick = async () => {
    const name = $('cName').value.trim();
    if (!name) { msg($('createMsg'),'Please enter a name.','err'); return; }
    const weeks = parseInt($('cWeeks').value, 10) || 0;
    const body = {
      name,
      sport: parseInt($('cSport').value, 10),
      tier: parseInt($('cTier').value, 10),
      distanceKm: parseFloat($('cDist').value),
      iterationsPerWeek: parseInt($('cIpw').value, 10),
      expirationDays: weeks * 7,
      stakeMinor: Math.round(parseFloat($('cStake').value) * 100),
      currency: 'EUR'
    };
    const r = await api('/admin/bets', body, true);
    if (!r.ok) { msg($('createMsg'), r.data.error || ('Failed ('+r.status+').'), 'err'); return; }
    msg($('createMsg'), 'Created curated bet: ' + (r.data.name || name), 'ok');
    $('cName').value = '';
  };
</script>
</body>
</html>''';
