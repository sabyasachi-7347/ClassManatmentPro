import { onIdTokenChanged, signOut, User } from 'firebase/auth';
import { createContext, ReactNode, useCallback, useContext, useEffect, useState } from 'react';
import { api } from './api';
import { auth } from './firebase';
import { Me } from './types';

interface AuthState {
  user: User | null;
  me: Me | null;
  loading: boolean;
  /** Force-refresh the ID token (to pick up new custom claims) and reload /me. */
  refresh: () => Promise<void>;
  logout: () => Promise<void>;
}

const Ctx = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [me, setMe] = useState<Me | null>(null);
  const [loading, setLoading] = useState(true);

  const loadMe = useCallback(async () => {
    try {
      setMe(await api.get<Me>('/me'));
    } catch {
      setMe(null);
    }
  }, []);

  useEffect(
    () =>
      onIdTokenChanged(auth, async (u) => {
        setUser(u);
        if (u) await loadMe();
        else setMe(null);
        setLoading(false);
      }),
    [loadMe],
  );

  const refresh = useCallback(async () => {
    await auth.currentUser?.getIdToken(true);
    await loadMe();
  }, [loadMe]);

  return (
    <Ctx.Provider value={{ user, me, loading, refresh, logout: () => signOut(auth) }}>
      {children}
    </Ctx.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('useAuth must be used inside <AuthProvider>');
  return ctx;
}
