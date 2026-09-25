import {
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  sendPasswordResetEmail,
  signInWithEmailAndPassword,
  signInWithPopup,
  updateProfile,
} from 'firebase/auth';
import { FormEvent, useState } from 'react';
import { Field } from '../components/ui';
import { auth } from '../lib/firebase';

export function Login() {
  const [mode, setMode] = useState<'in' | 'up'>('in');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState('');
  const [info, setInfo] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setErr('');
    setBusy(true);
    try {
      if (mode === 'in') {
        await signInWithEmailAndPassword(auth, email, password);
      } else {
        const cred = await createUserWithEmailAndPassword(auth, email, password);
        if (name) await updateProfile(cred.user, { displayName: name });
      }
    } catch (e) {
      setErr((e as Error).message.replace('Firebase: ', ''));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="auth-wrap">
      <div className="auth-card an">
        <div className="bd" style={{ fontSize: 22, marginBottom: 18 }}>
          CLASSES<em>.OS</em>
        </div>
        <div className="k" style={{ padding: 24 }}>
          <h2 className="h1" style={{ fontSize: 26 }}>{mode === 'in' ? 'Welcome back' : 'Create account'}</h2>
          <p className="sub">
            {mode === 'in' ? 'Sign in to your institute.' : 'Start by creating your owner account.'}
          </p>
          <form onSubmit={submit}>
            {mode === 'up' && (
              <Field label="Full name">
                <input className="ip" value={name} onChange={(e) => setName(e.target.value)} />
              </Field>
            )}
            <Field label="Email">
              <input className="ip" type="email" required value={email} onChange={(e) => setEmail(e.target.value)} />
            </Field>
            <Field label="Password">
              <input
                className="ip"
                type="password"
                required
                minLength={6}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </Field>
            <button className="b p lg blk" disabled={busy}>
              {busy ? 'Please wait…' : mode === 'in' ? 'Sign in' : 'Create account'}
            </button>
          </form>
          <button
            className="b lg blk"
            style={{ marginTop: 10 }}
            onClick={() => signInWithPopup(auth, new GoogleAuthProvider()).catch((e) => setErr(e.message))}
          >
            Continue with Google
          </button>
          {err && <div className="err">{err}</div>}
          {info && <div className="muted" style={{ marginTop: 8 }}>{info}</div>}
          <div className="row" style={{ marginTop: 16, justifyContent: 'space-between' }}>
            <button className="b gh s" onClick={() => setMode(mode === 'in' ? 'up' : 'in')}>
              {mode === 'in' ? 'New here? Create an account' : 'Have an account? Sign in'}
            </button>
            {mode === 'in' && (
              <button
                className="b gh s"
                onClick={() =>
                  email
                    ? sendPasswordResetEmail(auth, email).then(() => setInfo('Reset email sent.'))
                    : setErr('Enter your email first')
                }
              >
                Forgot password?
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
