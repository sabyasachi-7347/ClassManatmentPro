/**
 * Seeds the local emulators with a small, realistic institute so every role
 * in the app has something to show. Run after the emulators and API are up:
 *
 *   npm run emulators                 (repo root)
 *   npm run start:dev -w apps/api     (with the emulator env from .env.example)
 *   npm run seed -w apps/api
 *
 * WARNING: wipes all emulator data for project demo-classes-os first.
 *
 * Every account's password is `secret123`:
 *   owner@demo.test    owner — classes admin desk
 *   teacher@demo.test  teacher (Vikram Raghavan)
 *   parent@demo.test   parent of Aarav and Sara
 *   student@demo.test  student (Aarav Kulkarni)
 *
 * Today's lectures are placed around the current time so the teacher sees
 * one finished, one live and one upcoming.
 */
const P = 'demo-classes-os';
const HOST = process.env.EMULATOR_HOST ?? '127.0.0.1';
const API = process.env.API_URL ?? 'http://localhost:3000/api/v1';
const AUTH = `http://${HOST}:9099/identitytoolkit.googleapis.com/v1`;

await fetch(`http://${HOST}:8080/emulator/v1/projects/${P}/databases/(default)/documents`, { method: 'DELETE' });
await fetch(`http://${HOST}:9099/emulator/v1/projects/${P}/accounts`, { method: 'DELETE' });

async function j(url, opts = {}) {
  const r = await fetch(url, { ...opts, headers: { 'content-type': 'application/json', ...(opts.headers || {}) } });
  const b = await r.json().catch(() => null);
  if (!r.ok) throw new Error(`${opts.method ?? 'GET'} ${url} -> ${r.status} ${JSON.stringify(b)}`);
  return b;
}
const signUp = async (email, displayName) => {
  const r = await j(`${AUTH}/accounts:signUp?key=x`, { method: 'POST', body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }) });
  if (displayName) await j(`${AUTH}/accounts:update?key=x`, { method: 'POST', body: JSON.stringify({ idToken: r.idToken, displayName }) });
  return r.idToken;
};
const signIn = async (email) => (await j(`${AUTH}/accounts:signInWithPassword?key=x`, { method: 'POST', body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }) })).idToken;
const setPw = (localId) => j(`${AUTH}/projects/${P}/accounts:update`, { method: 'POST', headers: { authorization: 'Bearer owner' }, body: JSON.stringify({ localId, password: 'secret123' }) });
const call = (t, m, p, body) => j(`${API}${p}`, { method: m, headers: { authorization: `Bearer ${t}` }, body: body && JSON.stringify(body) });

const pad = (n) => String(n).padStart(2, '0');
const now = new Date();
const today = now.toLocaleDateString('en-CA');
const wd = now.getDay();
const at = (deltaMin) => {
  const m = Math.min(Math.max(now.getHours() * 60 + now.getMinutes() + deltaMin, 0), 23 * 60 + 59);
  return `${pad(Math.floor(m / 60))}:${pad(m % 60)}`;
};
const daysAgo = (n) => new Date(Date.now() - n * 86_400_000).toLocaleDateString('en-CA');

// ---- Owner + institute ----
await signUp('owner@demo.test', 'Rekha Deshmukh');
let owner = await signIn('owner@demo.test');
await call(owner, 'POST', '/institutes', { name: 'Sunrise Academy', city: 'Kalyan West' });
owner = await signIn('owner@demo.test'); // refresh claims

const physics = ['Units & Measurements', 'Kinematics', 'Laws of Motion', 'Rotational Dynamics', 'Gravitation', 'Thermodynamics'];
const syl = (done) => physics.map((title, i) => ({ title, status: i < done ? 'done' : i === done ? 'current' : 'todo' }));
const others = [1, 2, 3, 4, 5, 6].filter((d) => d !== wd).slice(0, 2);

const b1 = await call(owner, 'POST', '/batches', {
  name: 'JEE Adv 2027 — A', subject: 'Physics', room: 'Hall 2', monthlyFee: 2500, syllabus: syl(3),
  schedule: [{ day: wd, start: at(-150), end: at(-60) }, ...others.map((day) => ({ day, start: '07:00', end: '08:30' }))],
});
const b2 = await call(owner, 'POST', '/batches', {
  name: 'Std XII — Physics', subject: 'Physics', room: 'Room 4', monthlyFee: 1800, syllabus: syl(2),
  schedule: [{ day: wd, start: at(-30), end: at(60) }, { day: others[0], start: '18:00', end: '19:15' }],
});
const b3 = await call(owner, 'POST', '/batches', {
  name: 'NEET 2027 — A', subject: 'Biology', room: 'Hall 1', monthlyFee: 2200,
  syllabus: ['Cell Biology', 'Plant Physiology', 'Neural Control', 'Genetics'].map((title, i) => ({ title, status: i < 2 ? 'done' : i === 2 ? 'current' : 'todo' })),
  schedule: [{ day: wd, start: at(120), end: at(210) }],
});

// ---- Students ----
const names = [
  ['Aarav Kulkarni', 'XII', 'Sanjay Kulkarni'], ['Sara Kulkarni', 'X', 'Sanjay Kulkarni'],
  ['Diya Shetty', 'XII', 'Meena Shetty'], ['Rehan Kadri', 'XII', 'S. Kadri'], ['Ishita Rane', 'XI', 'A. Rane'],
  ['Om Bhagat', 'X', 'K. Bhagat'], ['Yash Pawar', 'XI', 'M. Pawar'], ['Tanvi Bhosale', 'XII', 'R. Bhosale'],
];
const st = [];
for (const [name, grade, guardianName] of names) {
  st.push(await call(owner, 'POST', '/students', { name, grade, guardianName, guardianPhone: '+91 98000 00000' }));
}
const [aarav, sara, diya, rehan, ishita, om, yash, tanvi] = st;
const enrol = (b, list) => list.map((s) => ({ studentId: s.id, batchId: b.id, enrolled: true }));
await call(owner, 'PUT', '/enrollments', { changes: [
  ...enrol(b1, [aarav, diya, rehan, ishita, tanvi]),
  ...enrol(b2, [aarav, rehan, tanvi, om]),
  ...enrol(b3, [sara, ishita, yash, om]),
] });

// ---- People ----
const t = await call(owner, 'POST', '/members', { email: 'teacher@demo.test', name: 'Vikram Raghavan', role: 'teacher' });
await setPw(t.uid);
const t2 = await call(owner, 'POST', '/members', { email: 'pillai@demo.test', name: 'Sunita Pillai', role: 'teacher' });
await setPw(t2.uid);
await call(owner, 'PATCH', `/batches/${b1.id}`, { teacherIds: [t.uid] });
await call(owner, 'PATCH', `/batches/${b2.id}`, { teacherIds: [t.uid] });
await call(owner, 'PATCH', `/batches/${b3.id}`, { teacherIds: [t2.uid] });
const p = await call(owner, 'POST', '/members', { email: 'parent@demo.test', name: 'Sanjay Kulkarni', role: 'parent', studentIds: [aarav.id, sara.id] });
await setPw(p.uid);
const s = await call(owner, 'POST', '/members', { email: 'student@demo.test', name: 'Aarav Kulkarni', role: 'student', studentIds: [aarav.id] });
await setPw(s.uid);

// ---- History: past attendance and tests ----
const teacher = await signIn('teacher@demo.test');
const pillai = await signIn('pillai@demo.test');
const roll = (b, list, absent = []) => ({ records: list.map((x) => ({ studentId: x.id, status: absent.includes(x) ? 'absent' : 'present' })) });
for (const [n, absent] of [[2, []], [5, [aarav]], [9, []], [12, [rehan]], [16, []], [19, []], [23, [diya]], [26, []]]) {
  await call(teacher, 'PUT', `/attendance/batches/${b1.id}/${daysAgo(n)}`, roll(b1, [aarav, diya, rehan, ishita, tanvi], absent));
}
for (const [n, absent] of [[3, [sara]], [10, []], [17, []], [24, [yash]]]) {
  await call(pillai, 'PUT', `/attendance/batches/${b3.id}/${daysAgo(n)}`, roll(b3, [sara, ishita, yash, om], absent));
}

const tests = [
  ['Weekly Test 11 — Physics', 80, 28, { aarav: 52, diya: 61, rehan: 44, ishita: 70, tanvi: 49 }],
  ['Weekly Test 12 — Physics', 80, 21, { aarav: 58, diya: 63, rehan: 47, ishita: 72, tanvi: 55 }],
  ['Monthly Mock 03 — PCM', 300, 14, { aarav: 214, diya: 228, rehan: 171, ishita: 251, tanvi: 199 }],
  ['Weekly Test 13 — Physics', 80, 7, { aarav: 68, diya: 66, rehan: 50, ishita: 74, tanvi: 61 }],
];
const ids = { aarav: aarav.id, diya: diya.id, rehan: rehan.id, ishita: ishita.id, tanvi: tanvi.id };
for (const [title, maxMarks, ago, marks] of tests) {
  const test = await call(teacher, 'POST', '/tests', { batchId: b1.id, title, maxMarks, date: daysAgo(ago) });
  await call(teacher, 'PUT', `/tests/${test.id}/marks`, {
    marks: Object.entries(marks).map(([k, score]) => ({ studentId: ids[k], score, note: k === 'aarav' && ago === 7 ? 'Strong on torque; revise friction.' : undefined })),
  });
}
const bio = await call(pillai, 'POST', '/tests', { batchId: b3.id, title: 'Weekly Test 9 — Biology', maxMarks: 50, date: daysAgo(6) });
await call(pillai, 'PUT', `/tests/${bio.id}/marks`, { marks: [{ studentId: sara.id, score: 41 }, { studentId: ishita.id, score: 46 }, { studentId: yash.id, score: 33 }, { studentId: om.id, score: 38 }] });

// ---- Today: the finished lecture's roll call, with Aarav absent ----
await call(teacher, 'PUT', `/attendance/batches/${b1.id}/${today}`, { ...roll(b1, [aarav, diya, rehan, ishita, tanvi], [aarav, rehan]), topic: 'Rotational Dynamics — Torque' });

console.log(`Seeded Sunrise Academy for ${today}.
  owner@demo.test / teacher@demo.test / parent@demo.test / student@demo.test   password: secret123`);
