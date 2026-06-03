import { ReactNode } from 'react';
import { useAuth } from '../context/AuthContext';
import { FlaticonIcon, type TabIconId } from './FlaticonIcon';
import { BrandLogo, BrandWordmark, Btn } from './ui';
import type { AdminRole } from '../lib/types';

interface AdminLayoutProps {
  title: string;
  role: AdminRole;
  tabs: { id: string; label: string }[];
  activeTab: string;
  onTabChange: (id: string) => void;
  children: ReactNode;
}

function isTabIconId(id: string): id is TabIconId {
  return (
    id === 'overview' ||
    id === 'companies' ||
    id === 'payments' ||
    id === 'admins' ||
    id === 'routes' ||
    id === 'buses' ||
    id === 'fares'
  );
}

export function AdminLayout({
  role,
  tabs,
  activeTab,
  onTabChange,
  children,
}: AdminLayoutProps) {
  const { logout } = useAuth();
  const isSuper = role === 'super_admin';

  return (
    <div className="flex min-h-screen bg-slate-50">
      <aside className="flex w-72 shrink-0 flex-col bg-gradient-to-b from-brand-blue to-brand-blue-dark text-white shadow-xl">
        <div className="border-b border-white/10 p-6">
          <div className="flex items-center gap-3">
            <BrandLogo size="sm" />
            <div>
              <BrandWordmark light />
              <p className="mt-1 text-xs text-blue-100">{isSuper ? 'Super Admin' : 'Sub Admin'}</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-4">
          {tabs.map((tab) => {
            const active = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                type="button"
                onClick={() => onTabChange(tab.id)}
                className={`flex w-full items-center gap-3 rounded-xl px-4 py-3 text-left text-sm font-semibold transition ${
                  active ? 'bg-white text-brand-blue shadow-md' : 'text-blue-100 hover:bg-white/10'
                }`}
              >
                {isTabIconId(tab.id) ? (
                  <FlaticonIcon
                    name={tab.id}
                    className={`text-lg ${active ? 'text-brand-blue' : 'text-blue-200'}`}
                  />
                ) : (
                  <span className="h-5 w-5 rounded-full bg-white/20" />
                )}
                {tab.label}
              </button>
            );
          })}
        </nav>

        <div className="border-t border-white/10 p-4">
          <Btn
            variant="ghost"
            className="mt-3 w-full !inline-flex !items-center !justify-center !border-white/30 !bg-white/10 !text-white hover:!bg-white/20"
            onClick={() => logout()}
          >
            <FlaticonIcon name="sign-out" className="mr-2 text-base" />
            Sign out
          </Btn>
        </div>
      </aside>

      <main className="flex-1 overflow-auto bg-gradient-to-br from-slate-50 via-white to-blue-50/40 p-6 md:p-8">
        {children}
      </main>
    </div>
  );
}
