import { createContext, ReactNode, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark';
const Ctx = createContext<{ theme: Theme; toggle: () => void }>({ theme: 'light', toggle: () => {} });
export const useTheme = () => useContext(Ctx);

function initial(): Theme {
  try {
    const saved = localStorage.getItem('os-theme');
    if (saved === 'light' || saved === 'dark') return saved;
  } catch {
    /* storage unavailable */
  }
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

/** Root `.os` wrapper; carries data-t="dark" exactly like the prototype. */
export function ThemeRoot({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(initial);
  useEffect(() => {
    try {
      localStorage.setItem('os-theme', theme);
    } catch {
      /* ignore */
    }
    document.body.style.background = theme === 'dark' ? '#0A0C14' : '#F1F3F7';
  }, [theme]);
  return (
    <Ctx.Provider value={{ theme, toggle: () => setTheme((t) => (t === 'dark' ? 'light' : 'dark')) }}>
      <div className="os" data-t={theme}>
        {children}
      </div>
    </Ctx.Provider>
  );
}
