import type { ReactNode } from 'react';
import { FlaticonIcon, type FlaticonIconName } from './FlaticonIcon';

export function BrandLogo({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const dim = size === 'lg' ? 'h-28 w-28' : size === 'sm' ? 'h-10 w-10' : 'h-16 w-16';
  return (
    <img
      src="/logo.png"
      alt="Bus Tracker PH"
      className={`${dim} object-contain drop-shadow-sm`}
      onError={(e) => {
        e.currentTarget.style.display = 'none';
      }}
    />
  );
}

export function BrandWordmark({ light = false }: { light?: boolean }) {
  if (light) {
    return (
      <h1 className="text-lg font-extrabold tracking-tight">
        <span className="text-white">Bus</span>
        <span className="text-emerald-200">Tracker</span>
        <span className="ml-1 inline-block rounded-md bg-white/20 px-1.5 py-0.5 text-xs text-white">
          PH
        </span>
      </h1>
    );
  }
  return (
    <h1 className="text-2xl font-extrabold tracking-tight">
      <span className="text-brand-blue">Bus</span>
      <span className="text-brand-green">Tracker</span>
      <span className="ml-1.5 inline-block rounded-md bg-brand-blue px-1.5 py-0.5 text-sm text-white">
        PH
      </span>
    </h1>
  );
}

export function StatCard({
  label,
  value,
  accent = 'blue',
  icon,
}: {
  label: string;
  value: string | number;
  accent?: 'blue' | 'green' | 'amber' | 'violet';
  icon?: FlaticonIconName;
}) {
  const ring =
    accent === 'green'
      ? 'from-brand-green/15 to-emerald-50 border-emerald-100'
      : accent === 'amber'
        ? 'from-amber-50 to-orange-50 border-amber-100'
        : accent === 'violet'
          ? 'from-violet-50 to-indigo-50 border-violet-100'
          : 'from-blue-50 to-sky-50 border-blue-100';

  const iconColor =
    accent === 'green'
      ? 'text-brand-green/40'
      : accent === 'amber'
        ? 'text-amber-500/40'
        : accent === 'violet'
          ? 'text-violet-500/40'
          : 'text-brand-blue/40';

  return (
    <div className={`relative overflow-hidden rounded-2xl border bg-gradient-to-br p-5 shadow-sm ${ring}`}>
      {icon && <FlaticonIcon name={icon} className={`absolute right-4 top-4 text-3xl ${iconColor}`} />}
      <p className="text-sm font-medium text-slate-500">{label}</p>
      <p className="mt-2 text-3xl font-extrabold text-brand-navy">{value}</p>
    </div>
  );
}

export function Panel({ title, children, action }: { title: string; children: ReactNode; action?: ReactNode }) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
      <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
        <h3 className="text-lg font-bold text-brand-navy">{title}</h3>
        {action}
      </div>
      {children}
    </section>
  );
}

export function AlertBanner({ children, tone = 'info' }: { children: ReactNode; tone?: 'info' | 'error' }) {
  return (
    <div
      className={`mb-5 rounded-xl border px-4 py-3 text-sm ${
        tone === 'error'
          ? 'border-red-200 bg-red-50 text-red-800'
          : 'border-blue-100 bg-blue-50 text-brand-navy'
      }`}
    >
      {children}
    </div>
  );
}

export function StatusPill({ status }: { status: string }) {
  const styles =
    status === 'approved' || status === 'active'
      ? 'bg-emerald-100 text-emerald-800'
      : status === 'rejected'
        ? 'bg-red-100 text-red-800'
        : status === 'pending'
          ? 'bg-orange-100 text-orange-800'
          : status === 'suspended' || status === 'maintenance'
            ? 'bg-amber-100 text-amber-800'
            : status === 'inactive'
              ? 'bg-slate-100 text-slate-600'
              : 'bg-slate-100 text-slate-700';

  return (
    <span className={`inline-block rounded-full px-2.5 py-1 text-xs font-bold capitalize ${styles}`}>
      {status}
    </span>
  );
}

export function Btn({
  children,
  variant = 'primary',
  className = '',
  ...props
}: React.ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: 'primary' | 'success' | 'danger' | 'ghost' | 'outline';
}) {
  const base =
    'inline-flex items-center justify-center rounded-xl px-4 py-2.5 text-sm font-bold transition disabled:cursor-not-allowed disabled:opacity-50';
  const variants = {
    primary: 'bg-gradient-to-r from-brand-blue to-primary text-white shadow-md shadow-blue-500/25 hover:brightness-105',
    success: 'bg-brand-green text-white shadow-md shadow-emerald-500/20 hover:brightness-105',
    danger: 'bg-red-500 text-white hover:bg-red-600',
    ghost: 'border border-slate-200 bg-white text-slate-700 hover:bg-slate-50',
    outline: 'border-2 border-brand-blue text-brand-blue hover:bg-blue-50',
  };
  return (
    <button type="button" className={`${base} ${variants[variant]} ${className}`} {...props}>
      {children}
    </button>
  );
}

export function Input(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return (
    <input
      {...props}
      className={`w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm outline-none transition focus:border-brand-blue focus:bg-white focus:ring-2 focus:ring-blue-100 ${props.className ?? ''}`}
    />
  );
}

export function Select(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return (
    <select
      {...props}
      className={`w-full rounded-xl border border-slate-200 bg-slate-50 px-4 py-2.5 text-sm outline-none focus:border-brand-blue focus:ring-2 focus:ring-blue-100 ${props.className ?? ''}`}
    />
  );
}

export function DataTable({ children }: { children: ReactNode }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-100">
      <table className="w-full min-w-[640px] text-left text-sm">{children}</table>
    </div>
  );
}

export function Th({ children }: { children?: ReactNode }) {
  return <th className="bg-slate-50 px-4 py-3 text-xs font-bold uppercase tracking-wide text-slate-500">{children ?? ''}</th>;
}

export function Td({ children, className = '' }: { children: ReactNode; className?: string }) {
  return <td className={`border-t border-slate-100 px-4 py-3 text-slate-700 ${className}`}>{children}</td>;
}

export function PageHeader({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <header className="mb-8">
      <h2 className="text-3xl font-extrabold tracking-tight text-brand-navy">{title}</h2>
      {subtitle && <p className="mt-1 text-slate-500">{subtitle}</p>}
    </header>
  );
}
