import { createContext, ReactNode, useCallback, useContext, useState } from 'react';

export const Spinner = () => <div className="spin" aria-label="Loading" />;

export function Empty({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <div className="emp">
      <div className="g">{title}</div>
      {children}
    </div>
  );
}

export function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
}) {
  return (
    <>
      <div className="scr" onClick={onClose} />
      <div className="modal" role="dialog" aria-label={title}>
        <div className="k">
          <div className="kh">
            <h3 style={{ fontSize: 18 }}>{title}</h3>
            <div className="r">
              <button className="b s gh" onClick={onClose} aria-label="Close">✕</button>
            </div>
          </div>
          {children}
        </div>
      </div>
    </>
  );
}

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="fl" style={{ display: 'block' }}>
      <span className="lbl">{label}</span>
      {children}
    </label>
  );
}

const ToastCtx = createContext<(msg: string) => void>(() => {});
export const useToast = () => useContext(ToastCtx);

export function ToastProvider({ children }: { children: ReactNode }) {
  const [msg, setMsg] = useState<string | null>(null);
  const show = useCallback((m: string) => {
    setMsg(m);
    window.setTimeout(() => setMsg((cur) => (cur === m ? null : cur)), 2600);
  }, []);
  return (
    <ToastCtx.Provider value={show}>
      {children}
      {msg && (
        <div className="tst" role="status">
          <i />
          {msg}
        </div>
      )}
    </ToastCtx.Provider>
  );
}
