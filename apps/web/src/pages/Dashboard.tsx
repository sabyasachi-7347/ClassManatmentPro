import { Link } from 'react-router-dom';
import { Empty, Spinner } from '../components/ui';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';
import { useLoad } from '../lib/hooks';
import { Dashboard as D, isStaff, money, today } from '../lib/types';

export function Dashboard() {
  const { me } = useAuth();
  const { data, loading, error } = useLoad(() => api.get<D>(`/dashboard?date=${today()}`));
  const hello = me?.member?.name?.split(' ')[0] ?? 'there';

  return (
    <>
      <div className="an">
        <h1 className="h1">Good {greeting()}, {hello}</h1>
        <p className="sub">
          {new Date().toLocaleDateString(undefined, { weekday: 'long', day: 'numeric', month: 'long' })}
        </p>
      </div>
      {loading && <Spinner />}
      {error && <div className="err">{error}</div>}
      {data && (
        <div className="bn an2">
          {isStaff(data.role) && <StaffTiles d={data} />}
          {data.role === 'teacher' && (
            <>
              <Tile label="Classes today" value={data.todaysClasses.length} />
              <Tile label="Attendance pending" value={data.pendingAttendance ?? 0} hot={!!data.pendingAttendance} />
              <Tile label="My batches" value={data.batchCount} />
            </>
          )}
          {(data.role === 'student' || data.role === 'parent') && <LearnerTiles d={data} />}

          <div className="k w4">
            <div className="kh">
              <h3>Today’s classes</h3>
              <div className="r"><span className="pl x">{data.todaysClasses.length}</span></div>
            </div>
            {!data.todaysClasses.length && <Empty title="No classes today">Enjoy the breather.</Empty>}
            {data.todaysClasses.map((c) => (
              <div className="lb" key={c.batchId + c.start}>
                <span className="rk mono">{c.start}</span>
                <span className="nm">
                  {c.name} <span className="muted">· {c.subject}{c.room ? ` · ${c.room}` : ''}</span>
                </span>
                {data.role !== 'student' && data.role !== 'parent' &&
                  (c.attendanceMarked ? (
                    <span className="pl l">Marked</span>
                  ) : (
                    <Link className="b s p" to={`/attendance?batch=${c.batchId}`}>Take attendance</Link>
                  ))}
              </div>
            ))}
          </div>
        </div>
      )}
    </>
  );
}

function StaffTiles({ d }: { d: D }) {
  const rate = d.attendanceToday?.rate;
  return (
    <>
      <div className="feat w2">
        <div className="r">
          <div className="lab">Attendance today</div>
          <div className="big n1" style={{ marginTop: 10 }}>{rate == null ? '—' : `${rate}%`}</div>
          <div style={{ fontSize: 12.5, marginTop: 8, opacity: 0.85 }}>
            {d.attendanceToday?.present ?? 0} of {d.attendanceToday?.total ?? 0} marked present
          </div>
        </div>
      </div>
      <Tile label="Active students" value={d.activeStudents ?? 0} />
      <Tile label="Batches" value={d.batchCount} />
      <Tile label="Fees due" value={money(d.fees?.dueAmount ?? 0)} sub={`${d.fees?.dueCount ?? 0} invoices`} />
      <Tile label="Overdue" value={d.fees?.overdueCount ?? 0} hot={!!d.fees?.overdueCount} />
    </>
  );
}

function LearnerTiles({ d }: { d: D }) {
  const due = (d.dues ?? []).reduce((s, f) => s + f.amount, 0);
  return (
    <>
      {(d.students ?? []).map((s) => (
        <div className="feat w2" key={s.id}>
          <div className="r">
            <div className="lab">{s.name} · attendance (30 days)</div>
            <div className="big n1" style={{ marginTop: 10 }}>
              {s.attendanceRate30d == null ? '—' : `${s.attendanceRate30d}%`}
            </div>
          </div>
        </div>
      ))}
      <Tile label="Fees due" value={money(due)} hot={due > 0} />
      <Tile label="Batches" value={d.batchCount} />
    </>
  );
}

function Tile({ label, value, sub, hot }: { label: string; value: string | number; sub?: string; hot?: boolean }) {
  return (
    <div className="k hov">
      <div className="lab">{label}</div>
      <div className="big n2" style={{ marginTop: 12, color: hot ? 'var(--hot)' : undefined }}>{value}</div>
      {sub && <div className="dlt fl">{sub}</div>}
    </div>
  );
}

function greeting() {
  const h = new Date().getHours();
  return h < 12 ? 'morning' : h < 17 ? 'afternoon' : 'evening';
}
