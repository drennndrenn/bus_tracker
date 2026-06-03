import { FormEvent, useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { FlaticonIcon } from '../components/FlaticonIcon';
import { firebaseReady } from '../lib/firebase';
import { useAuth } from '../context/AuthContext';
import { AlertBanner } from '../components/ui';

const REMEMBER_KEY = 'bustracker_admin_email';

function IconField({
  icon,
  type = 'text',
  value,
  onChange,
  placeholder,
  autoComplete,
  required,
  trailing,
}: {
  icon: 'user' | 'lock';
  type?: string;
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
  autoComplete?: string;
  required?: boolean;
  trailing?: React.ReactNode;
}) {
  return (
    <div className="relative">
      <FlaticonIcon
        name={icon}
        className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-base text-slate-400"
      />
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        autoComplete={autoComplete}
        required={required}
        className="w-full rounded-lg border border-slate-200 bg-white py-3 pl-11 pr-11 text-sm text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-primary focus:ring-2 focus:ring-blue-100"
      />
      {trailing && <div className="absolute right-2 top-1/2 -translate-y-1/2">{trailing}</div>}
    </div>
  );
}

function BrandPanel() {
  return (
    <div className="relative hidden min-h-[520px] overflow-hidden lg:block lg:w-1/2">
      <img src="/bus.png" alt="" className="absolute inset-0 h-full w-full object-cover" />
      <div className="absolute inset-0 bg-gradient-to-br from-brand-navy/85 via-brand-blue/75 to-brand-blue-dark/90" />

      <svg
        className="pointer-events-none absolute inset-0 h-full w-full text-white/35"
        viewBox="0 0 400 600"
        preserveAspectRatio="none"
        aria-hidden
      >
        <path
          d="M 30 380 Q 120 280 200 340 T 370 220"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeDasharray="10 8"
        />
        <circle cx="30" cy="380" r="6" fill="currentColor" />
        <circle cx="200" cy="340" r="5" fill="currentColor" />
        <circle cx="370" cy="220" r="6" fill="currentColor" />
      </svg>

      <div className="relative z-10 flex h-full flex-col items-center justify-center px-10 text-center text-white">
        <img
          src="/logo.png"
          alt="Bus Tracker PH"
          className="h-24 w-24 object-contain drop-shadow-lg"
        />
        <h1 className="mt-8 text-3xl font-bold tracking-[0.25em] xl:text-4xl">BUS TRACKING</h1>
        <p className="mt-3 text-lg font-light tracking-wide text-blue-100">Track. Monitor. Manage.</p>
      </div>
    </div>
  );
}

export function LoginPage() {
  const { signIn, error } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [remember, setRemember] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState('');

  useEffect(() => {
    const saved = localStorage.getItem(REMEMBER_KEY);
    if (saved) {
      setEmail(saved);
      setRemember(true);
    }
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    setLocalError('');
    setSubmitting(true);
    try {
      const profile = await signIn(email, password);
      if (remember) {
        localStorage.setItem(REMEMBER_KEY, email);
      } else {
        localStorage.removeItem(REMEMBER_KEY);
      }
      navigate(profile.role === 'super_admin' ? '/super' : '/sub', { replace: true });
    } catch (err) {
      const code =
        err && typeof err === 'object' && 'code' in err
          ? String((err as { code: string }).code)
          : '';
      const message = err instanceof Error ? err.message : 'Login failed.';
      if (code === 'auth/invalid-credential' || code === 'auth/wrong-password') {
        setLocalError('Wrong email or password.');
      } else {
        setLocalError(message);
      }
    } finally {
      setSubmitting(false);
    }
  }

  if (!firebaseReady) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-slate-100 p-6">
        <div className="max-w-md rounded-2xl border border-slate-200 bg-white p-8 shadow-xl">
          <h1 className="text-xl font-bold text-brand-navy">Firebase not configured</h1>
          <p className="mt-2 text-sm text-slate-600">
            Copy <code className="rounded bg-slate-100 px-1">admin_web/.env</code> from the example file
            and restart the dev server.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-100 p-4 sm:p-6">
      <div className="flex w-full max-w-5xl overflow-hidden rounded-2xl bg-white shadow-2xl">
        <BrandPanel />

        <div className="flex w-full flex-col justify-center px-8 py-10 sm:px-12 lg:w-1/2 lg:px-14 lg:py-12">
          <div className="mb-8 flex flex-col items-center text-center lg:hidden">
            <img src="/logo.png" alt="Bus Tracker PH" className="h-16 w-16 object-contain" />
            <p className="mt-3 text-sm font-semibold tracking-widest text-brand-navy">BUS TRACKING</p>
          </div>

          <div className="mb-6 flex justify-center">
            <span className="flex h-14 w-14 items-center justify-center rounded-full bg-blue-50">
              <FlaticonIcon name="user-shield" className="text-3xl text-primary" />
            </span>
          </div>

          <h2 className="text-center text-2xl font-bold text-slate-900">Admin Login</h2>
          <p className="mt-1 text-center text-sm text-slate-500">Welcome back! Please login to continue.</p>

          {(localError || error) && (
            <div className="mt-5">
              <AlertBanner tone="error">{localError || error}</AlertBanner>
            </div>
          )}

          <form className="mt-8 space-y-5" onSubmit={handleSubmit}>
            <div>
              <label htmlFor="email" className="mb-1.5 block text-sm font-semibold text-slate-700">
                Email
              </label>
              <IconField
                icon="user"
                type="email"
                value={email}
                onChange={setEmail}
                placeholder="Enter your email"
                autoComplete="email"
                required
              />
            </div>

            <div>
              <label htmlFor="password" className="mb-1.5 block text-sm font-semibold text-slate-700">
                Password
              </label>
              <IconField
                icon="lock"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={setPassword}
                placeholder="Enter password"
                autoComplete="current-password"
                required
                trailing={
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-600"
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                  >
                    <FlaticonIcon name={showPassword ? 'eye-crossed' : 'eye'} className="text-base" />
                  </button>
                }
              />
            </div>

            <div className="flex items-center justify-between text-sm">
              <label className="flex cursor-pointer items-center gap-2 text-slate-600">
                <input
                  type="checkbox"
                  checked={remember}
                  onChange={(e) => setRemember(e.target.checked)}
                  className="h-4 w-4 rounded border-slate-300 text-primary focus:ring-primary"
                />
                Remember me
              </label>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-primary py-3 text-sm font-bold text-white shadow-md shadow-blue-500/30 transition hover:bg-brand-blue disabled:cursor-not-allowed disabled:opacity-60"
            >
              <FlaticonIcon name="lock" className="text-base text-white" />
              {submitting ? 'Signing in…' : 'Login'}
            </button>
          </form>

          <div className="mt-8 border-t border-slate-100 pt-6">
            <p className="flex items-center justify-center gap-2 text-center text-xs text-slate-400">
              <FlaticonIcon name="shield-check" className="text-sm text-slate-400" />
              Secure Admin Access
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
