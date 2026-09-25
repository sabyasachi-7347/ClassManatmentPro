import { FormEvent, useState } from 'react';
import { Field } from '../components/ui';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth';

/** Shown to signed-in users who don't belong to an institute yet. */
export function Onboarding() {
  const { user, refresh, logout } = useAuth();
  const [name, setName] = useState('');
  const [city, setCity] = useState('');
  const [err, setErr] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setErr('');
    try {
      await api.post('/institutes', { name, city: city || undefined });
      await refresh(); // pick up the new owner claims
    } catch (e) {
      setErr((e as Error).message);
      setBusy(false);
    }
  }

  return (
    <div className="auth-wrap">
      <div className="auth-card an">
        <div className="feat" style={{ marginBottom: 12 }}>
          <div className="r">
            <div className="lab">Step 1 of 1</div>
            <h2 style={{ fontSize: 24, marginTop: 8 }}>Set up your institute</h2>
            <p style={{ fontSize: 13, marginTop: 6, opacity: 0.85 }}>
              Signed in as {user?.email}. If you were invited by an institute, ask the admin to add you —
              then sign out and back in.
            </p>
          </div>
        </div>
        <form className="k" style={{ padding: 22 }} onSubmit={submit}>
          <Field label="Institute name">
            <input className="ip" required value={name} onChange={(e) => setName(e.target.value)} />
          </Field>
          <Field label="City">
            <input className="ip" value={city} onChange={(e) => setCity(e.target.value)} />
          </Field>
          <button className="b p lg blk" disabled={busy}>
            {busy ? 'Creating…' : 'Create institute'}
          </button>
          {err && <div className="err">{err}</div>}
          <button type="button" className="b gh s" style={{ marginTop: 12 }} onClick={logout}>
            Sign out
          </button>
        </form>
      </div>
    </div>
  );
}
