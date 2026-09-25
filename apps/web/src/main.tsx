import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { App } from './App';
import { ThemeRoot } from './components/theme';
import { ToastProvider } from './components/ui';
import { AuthProvider } from './lib/auth';
import './styles/os.css';
import './styles/app.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <ThemeRoot>
        <ToastProvider>
          <AuthProvider>
            <App />
          </AuthProvider>
        </ToastProvider>
      </ThemeRoot>
    </BrowserRouter>
  </StrictMode>,
);
