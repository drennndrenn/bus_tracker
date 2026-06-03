import type { ReactNode } from 'react';
import { Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { LoginPage } from './pages/LoginPage';
import { SubAdminDashboard } from './pages/SubAdminDashboard';
import { SuperAdminDashboard } from './pages/SuperAdminDashboard';

function ProtectedRoute({ role, children }: { role: 'super_admin' | 'sub_admin'; children: ReactNode }) {
  const { profile, loading } = useAuth();

  if (loading) {
    return <div className="login-page">Loading…</div>;
  }

  if (!profile) {
    return <Navigate to="/login" replace />;
  }

  if (profile.role !== role) {
    return <Navigate to={profile.role === 'super_admin' ? '/super' : '/sub'} replace />;
  }

  return <>{children}</>;
}

function AppRoutes() {
  const { profile, loading } = useAuth();

  if (loading) {
    return <div className="login-page">Loading…</div>;
  }

  return (
    <Routes>
      <Route
        path="/login"
        element={
          profile ? (
            <Navigate to={profile.role === 'super_admin' ? '/super' : '/sub'} replace />
          ) : (
            <LoginPage />
          )
        }
      />
      <Route
        path="/super"
        element={
          <ProtectedRoute role="super_admin">
            <SuperAdminDashboard />
          </ProtectedRoute>
        }
      />
      <Route
        path="/sub"
        element={
          <ProtectedRoute role="sub_admin">
            <SubAdminDashboard />
          </ProtectedRoute>
        }
      />
      <Route
        path="*"
        element={
          <Navigate
            to={profile ? (profile.role === 'super_admin' ? '/super' : '/sub') : '/login'}
            replace
          />
        }
      />
    </Routes>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <AppRoutes />
    </AuthProvider>
  );
}
