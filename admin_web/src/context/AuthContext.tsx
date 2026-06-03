import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react';
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  type User,
} from 'firebase/auth';
import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import {
  BACHELOR_EXPRESS_COMPANY_ID,
  seedBachelorExpressIfEmpty,
} from '../lib/bachelorExpressSeed';
import { auth, db } from '../lib/firebase';
import type { AdminProfile, AdminRole } from '../lib/types';

interface AuthContextValue {
  user: User | null;
  profile: AdminProfile | null;
  loading: boolean;
  error: string;
  signIn: (email: string, password: string) => Promise<AdminProfile>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const DEMO_ADMINS: Record<
  string,
  { role: AdminRole; displayName: string; companyId: string | null }
> = {
  'superadmin@bustracker.demo': {
    role: 'super_admin',
    displayName: 'Super Admin',
    companyId: null,
  },
  'subadmin@bustracker.demo': {
    role: 'sub_admin',
    displayName: 'Bachelor Express Sub Admin',
    companyId: 'dnsc-express',
  },
};

async function ensureDemoCompany() {
  await setDoc(
    doc(db, 'companies', BACHELOR_EXPRESS_COMPANY_ID),
    {
      name: 'Bachelor Express',
      region: 'Davao del Norte',
      status: 'active',
      createdAt: serverTimestamp(),
    },
    { merge: true },
  );
  await seedBachelorExpressIfEmpty(BACHELOR_EXPRESS_COMPANY_ID);
}

async function loadOrCreateAdminProfile(user: User): Promise<AdminProfile> {
  const adminRef = doc(db, 'admins', user.uid);
  const snap = await getDoc(adminRef);

  if (snap.exists()) {
    const data = snap.data();
    if (data.role !== 'super_admin' && data.role !== 'sub_admin') {
      throw new Error('Invalid admin role.');
    }
    return {
      uid: user.uid,
      email: data.email ?? user.email ?? '',
      displayName: data.displayName ?? 'Admin',
      role: data.role,
      companyId: data.companyId ?? null,
    };
  }

  const email = (user.email ?? '').toLowerCase();
  const demo = DEMO_ADMINS[email];
  if (!demo) {
    throw new Error('This account is not registered as an admin.');
  }

  await setDoc(adminRef, {
    email: user.email ?? email,
    displayName: demo.displayName,
    role: demo.role,
    companyId: demo.companyId,
    createdAt: serverTimestamp(),
  });

  await ensureDemoCompany();

  return {
    uid: user.uid,
    email: user.email ?? email,
    displayName: demo.displayName,
    role: demo.role,
    companyId: demo.companyId,
  };
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<AdminProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (nextUser) => {
      setLoading(true);
      setError('');
      try {
        if (!nextUser) {
          setUser(null);
          setProfile(null);
          return;
        }
        const adminProfile = await loadOrCreateAdminProfile(nextUser);
        setUser(nextUser);
        setProfile(adminProfile);
      } catch (err) {
        await signOut(auth);
        setUser(null);
        setProfile(null);
        setError(err instanceof Error ? err.message : 'Failed to load admin profile.');
      } finally {
        setLoading(false);
      }
    });
    return unsub;
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    setError('');
    const credential = await signInWithEmailAndPassword(auth, email.trim(), password);
    const adminProfile = await loadOrCreateAdminProfile(credential.user);
    setUser(credential.user);
    setProfile(adminProfile);
    return adminProfile;
  }, []);

  const logout = useCallback(async () => {
    await signOut(auth);
    setUser(null);
    setProfile(null);
  }, []);

  const value = useMemo(
    () => ({ user, profile, loading, error, signIn, logout }),
    [user, profile, loading, error, signIn, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
