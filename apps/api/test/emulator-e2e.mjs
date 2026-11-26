/**
 * End-to-end API test against the Firebase emulators.
 *   1. npm run emulators          (repo root)
 *   2. npm run start:dev -w apps/api  (with the emulator env vars from .env.example)
 *   3. npm run test:e2e -w apps/api
 * WARNING: wipes all emulator data for project demo-classes-os before running.
 */
const P = 'demo-classes-os';
await fetch(`http://127.0.0.1:8080/emulator/v1/projects/${P}/databases/(default)/documents`, { method: 'DELETE' });
await fetch(`http://127.0.0.1:9099/emulator/v1/projects/${P}/accounts`, { method: 'DELETE' });
const AUTH = 'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1';
const API = process.env.API_URL ?? 'http://localhost:3000/api/v1';
let fails = 0;
const ok = (c, m) => { console.log(`${c ? 'PASS' : 'FAIL'}  ${m}`); if (!c) fails++; };
async function j(url, opts = {}) { const r = await fetch(url, { ...opts, headers: { 'content-type': 'application/json', ...(opts.headers || {}) } }); return { s: r.status, b: await r.json().catch(() => null) }; }
const signUp = async (email) => (await j(`${AUTH}/accounts:signUp?key=x`, { method: 'POST', body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }) })).b.idToken;
const signIn = async (email) => (await j(`${AUTH}/accounts:signInWithPassword?key=x`, { method: 'POST', body: JSON.stringify({ email, password: 'secret123', returnSecureToken: true }) })).b.idToken;
const setPw = (localId) => j(`${AUTH}/projects/${P}/accounts:update`, { method: 'POST', headers: { authorization: 'Bearer owner' }, body: JSON.stringify({ localId, password: 'secret123' }) });
const call = (t, m, p, body) => j(`${API}${p}`, { method: m, headers: { authorization: `Bearer ${t}` }, body: body && JSON.stringify(body) });

const today = new Date().toLocaleDateString('en-CA');
const wd = new Date(`${today}T00:00:00Z`).getUTCDay();

let owner = await signUp('owner@x.com');
ok((await call(owner, 'GET', '/batches')).s === 403, 'member routes blocked before onboarding');
ok((await call(owner, 'GET', '/me')).b.institute === null, '/me works without institute');
const inst = await call(owner, 'POST', '/institutes', { name: 'Apex Classes', city: 'Pune' });
ok(inst.s === 201, 'create institute');
ok((await call(owner, 'POST', '/institutes', { name: 'Second' })).s === 409, 'stale token cannot create a second institute');
owner = await signIn('owner@x.com');
ok((await call(owner, 'POST', '/institutes', { name: 'Third' })).s === 409, 'cannot create second institute after refresh');
const me = await call(owner, 'GET', '/me');
ok(me.b.role === 'owner' && me.b.institute, 'owner claims present');

const b1 = (await call(owner, 'POST', '/batches', { name: 'JEE Physics A', subject: 'Physics', monthlyFee: 1500, schedule: [{ day: wd, start: '17:00', end: '18:30' }] })).b;
const b2 = (await call(owner, 'POST', '/batches', { name: 'NEET Bio', subject: 'Biology', monthlyFee: 1000 })).b;
ok(b1.id && b2.id, 'create batches');
ok((await call(owner, 'POST', '/batches', { name: 'bad', subject: 's', schedule: [{ day: 9, start: '25:00', end: 'x' }] })).s === 400, 'validation rejects bad schedule');

const s1 = (await call(owner, 'POST', '/students', { name: 'Aarav Shah', phone: '9999' })).b;
const s2 = (await call(owner, 'POST', '/students', { name: 'Diya Rao' })).b;
const en = await call(owner, 'PUT', '/enrollments', { changes: [
  { studentId: s1.id, batchId: b1.id, enrolled: true }, { studentId: s2.id, batchId: b1.id, enrolled: true },
  { studentId: s2.id, batchId: b2.id, enrolled: true } ] });
ok(en.b.applied === 3, 'bulk enrollment');

const inv = await call(owner, 'POST', '/members', { email: 'teach@x.com', name: 'Ms. Iyer', role: 'teacher' });
ok(inv.s === 201 && inv.b.setPasswordLink, 'invite teacher returns set-password link');
await setPw(inv.b.uid);
await call(owner, 'PATCH', `/batches/${b1.id}`, { teacherIds: [inv.b.uid] });
const teacher = await signIn('teach@x.com');
const tb = await call(teacher, 'GET', '/batches');
ok(tb.b.length === 1 && tb.b[0].id === b1.id, 'teacher sees only own batch');
ok((await call(teacher, 'GET', `/batches/${b2.id}`)).s === 403, 'teacher blocked from other batch');
ok((await call(teacher, 'POST', '/batches', { name: 'x', subject: 'y' })).s === 403, 'teacher cannot create batch');
ok((await call(teacher, 'GET', '/fees')).s === 403, 'teacher cannot view fees');
const ts = await call(teacher, 'GET', '/students');
ok(ts.b.length === 2, 'teacher sees students of own batch');
const td = await call(teacher, 'GET', `/dashboard?date=${today}`);
ok(td.b.todaysClasses.length === 1 && td.b.pendingAttendance === 1, 'teacher dashboard shows pending class');
const mk = await call(teacher, 'PUT', `/attendance/batches/${b1.id}/${today}`, { records: [{ studentId: s1.id, status: 'present' }, { studentId: s2.id, status: 'absent' }] });
ok(mk.s === 200 && mk.b.summary.present === 1, 'teacher marks attendance');
ok((await call(teacher, 'PUT', `/attendance/batches/${b2.id}/${today}`, { records: [] })).s === 403, 'teacher cannot mark other batch');
ok((await call(teacher, 'GET', `/dashboard?date=${today}`)).b.pendingAttendance === 0, 'pending cleared');

const gen = await call(owner, 'POST', '/fees/generate', { period: '2026-09', dueDate: '2026-09-05' });
ok(gen.b.created === 2, `generate fees (${JSON.stringify(gen.b)})`);
const gen2 = await call(owner, 'POST', '/fees/generate', { period: '2026-09', dueDate: '2026-09-05' });
ok(gen2.b.created === 0, 'generate is idempotent');
const fees = await call(owner, 'GET', '/fees?status=due');
ok(fees.s === 200 && fees.b.length === 2 && fees.b.every((f) => f.overdue), `list due fees overdue (${fees.s} ${JSON.stringify(fees.b).slice(0,200)})`);
const f2 = fees.b.find((f) => f.studentId === s2.id);
ok(f2?.amount === 2500, 'fee sums batches');
ok((await call(owner, 'POST', `/fees/${f2.id}/pay`, { method: 'upi', reference: 'R1' })).b.status === 'paid', 'record payment');
ok((await call(owner, 'POST', `/fees/${f2.id}/pay`, { method: 'upi' })).s === 409, 'double payment rejected');
const od = await call(owner, 'GET', `/dashboard?date=${today}`);
ok(od.b.activeStudents === 2 && od.b.attendanceToday.rate === 50 && od.b.fees.dueCount === 1, `owner dashboard ${JSON.stringify(od.b.fees)} ${od.s}`);

const pinv = await call(owner, 'POST', '/members', { email: 'parent@x.com', name: 'Mr. Shah', role: 'parent', studentIds: [s1.id] });
await setPw(pinv.b.uid);
const parent = await signIn('parent@x.com');
ok((await call(parent, 'GET', '/students')).b.length === 1, 'parent sees only own child');
ok((await call(parent, 'GET', `/students/${s2.id}`)).s === 403, 'parent blocked from other student');
ok((await call(parent, 'GET', '/fees')).b.length === 1, 'parent sees own fees');
ok((await call(parent, 'GET', `/fees?studentId=${s2.id}`)).s === 403, 'parent cannot query other fees');
const pa = await call(parent, 'GET', `/attendance/students/${s1.id}`);
ok(pa.s === 200 && pa.b.rate === 100, `parent attendance ${pa.s} ${JSON.stringify(pa.b).slice(0,200)}`);
const pd = await call(parent, 'GET', `/dashboard?date=${today}`);
ok(pd.s === 200 && pd.b.students[0].attendanceRate30d === 100, `parent dashboard ${pd.s} ${JSON.stringify(pd.b).slice(0,200)}`);
ok((await call(parent, 'POST', '/announcements', { title: 'x', body: 'y' })).s === 403, 'parent cannot post');

await call(owner, 'POST', '/announcements', { title: 'Holiday', body: 'Closed Monday' });
await call(teacher, 'POST', '/announcements', { title: 'Physics test', body: 'Friday' });
await call(owner, 'POST', '/announcements', { title: 'Bio only', body: '...', batchIds: [b2.id] });
const pan = await call(parent, 'GET', '/announcements');
ok(pan.b.length === 2 && !pan.b.some((a) => a.title === 'Bio only'), 'parent sees institute + own batch announcements');
// ---- Absence alerts: mark absent -> parent acknowledges -> staff see it ----
const ab = await call(teacher, 'GET', `/absences?date=${today}`);
ok(ab.s === 200 && ab.b.length === 1 && ab.b[0].studentId === s2.id && ab.b[0].state === 'waiting', `absence opened for absent student (${ab.s} ${JSON.stringify(ab.b).slice(0,160)})`);
ok(mk.b.alerts?.opened === 1, 'mark reports opened alerts');
const remark = await call(teacher, 'PUT', `/attendance/batches/${b1.id}/${today}`, { records: [{ studentId: s1.id, status: 'absent' }, { studentId: s2.id, status: 'absent' }], topic: 'Torque' });
ok(remark.b.alerts.opened === 1, 're-marking only opens new alerts');
ok((await call(owner, 'GET', `/absences?date=${today}`)).b.length === 2, 'owner sees all alerts for the day');
ok((await call(parent, 'POST', '/me/devices', { token: 'test-device-token' })).s === 201, 'parent registers device');
const pab = await call(parent, 'GET', '/absences');
ok(pab.s === 200 && pab.b.length === 1 && pab.b[0].studentId === s1.id, `parent sees only own child's absence (${pab.s} ${JSON.stringify(pab.b).slice(0,120)})`);
ok((await call(teacher, 'POST', `/absences/${pab.b[0].id}/ack`)).s === 403, 'teacher cannot acknowledge');
const others = (await call(owner, 'GET', `/absences?date=${today}`)).b.find((a) => a.studentId === s2.id);
ok((await call(parent, 'POST', `/absences/${others.id}/ack`)).s === 403, "parent cannot acknowledge another child's absence");
const ack = await call(parent, 'POST', `/absences/${pab.b[0].id}/ack`);
ok(ack.s === 201 && ack.b.state === 'acknowledged' && ack.b.ackAt, 'parent acknowledges');
const nud = await call(teacher, 'POST', '/absences/nudge', { date: today });
ok(nud.s === 201 && nud.b.nudged === 1, `nudge targets only unacknowledged (${JSON.stringify(nud.b)})`);
const fixed = await call(teacher, 'PUT', `/attendance/batches/${b1.id}/${today}`, { records: [{ studentId: s1.id, status: 'absent' }, { studentId: s2.id, status: 'present' }] });
ok(fixed.b.alerts.closed === 1, 'marking present closes the alert');
const after = (await call(owner, 'GET', `/absences?date=${today}`)).b;
ok(after.length === 1 && after[0].state === 'acknowledged', 'acknowledgement survives a re-mark');
ok((await call(owner, 'GET', `/absences?state=waiting&date=${today}`)).b.length === 0, 'filter by state');

// ---- Tests & marks ----
const t1 = await call(teacher, 'POST', '/tests', { batchId: b1.id, title: 'Weekly Test 1', maxMarks: 80, date: today });
ok(t1.s === 201 && t1.b.id, 'teacher creates test for own batch');
ok((await call(teacher, 'POST', '/tests', { batchId: b2.id, title: 'x', maxMarks: 10, date: today })).s === 403, 'teacher cannot create test for other batch');
ok((await call(teacher, 'PUT', `/tests/${t1.b.id}/marks`, { marks: [{ studentId: s1.id, score: 90 }] })).s === 400, 'score above max rejected');
const em = await call(teacher, 'PUT', `/tests/${t1.b.id}/marks`, { marks: [{ studentId: s1.id, score: 68, note: 'Good' }, { studentId: s2.id, score: 74 }] });
ok(em.s === 200 && em.b.rows[0].studentId === s2.id && em.b.rows[0].rank === 1 && em.b.average === 71, `marks entered and ranked (${JSON.stringify(em.b).slice(0,200)})`);
const plb = await call(parent, 'GET', `/tests/${t1.b.id}`);
const other = plb.b.rows.find((r) => !r.isMine);
ok(plb.s === 200 && other.name === 'Diya R.' && other.studentId === undefined && other.note === undefined, 'parent leaderboard hides other students');
const pres = await call(parent, 'GET', `/students/${s1.id}/results`);
ok(pres.s === 200 && pres.b[0].score === 68 && pres.b[0].rank === 2 && pres.b[0].outOf === 2 && pres.b[0].note === 'Good', `parent sees child results (${JSON.stringify(pres.b).slice(0,160)})`);
ok((await call(parent, 'GET', `/students/${s2.id}/results`)).s === 403, "parent blocked from other student's results");
ok((await call(parent, 'GET', '/tests')).b.length === 1, 'parent lists tests of child batches');
ok((await call(parent, 'POST', '/tests', { batchId: b1.id, title: 'x', maxMarks: 10, date: today })).s === 403, 'parent cannot create tests');

// ---- Syllabus ----
const syl = await call(owner, 'PATCH', `/batches/${b1.id}`, { syllabus: [{ title: 'Kinematics', status: 'done' }, { title: 'Rotation', status: 'current' }, { title: 'Gravitation', status: 'todo' }] });
ok(syl.s === 200 && syl.b.syllabus.length === 3, 'owner sets syllabus');
const ts1 = await call(teacher, 'PUT', `/batches/${b1.id}/syllabus`, { chapters: [{ title: 'Kinematics', status: 'done' }, { title: 'Rotation', status: 'done' }, { title: 'Gravitation', status: 'current' }] });
ok(ts1.s === 200 && ts1.b.syllabus[1].status === 'done', 'teacher logs coverage');
ok((await call(teacher, 'PUT', `/batches/${b1.id}/syllabus`, { chapters: [{ title: 'Renamed', status: 'done' }] })).s === 403, 'teacher cannot restructure syllabus');

const mem = await call(owner, 'GET', '/members');
ok(mem.b.length === 3, `members list (${mem.s} ${JSON.stringify(mem.b).slice(0,150)})`);
ok((await call(owner, 'GET', '/members?role=teacher')).b.length === 1, 'members filter by role');
ok((await call(owner, 'DELETE', `/members/${pinv.b.uid}`)).s === 200, 'remove member');

console.log(fails ? `\n${fails} FAILED` : '\nALL PASSED');
process.exit(fails ? 1 : 0);
