export type AdminRole = 'super_admin' | 'sub_admin';

export interface AdminProfile {
  uid: string;
  email: string;
  displayName: string;
  role: AdminRole;
  companyId: string | null;
}

export interface Company {
  id: string;
  name: string;
  region?: string;
  status?: string;
}

export interface RouteDoc {
  id: string;
  name: string;
  origin: string;
  destination: string;
  status: string;
}

export interface BusDoc {
  id: string;
  plateNumber: string;
  routeLabel: string;
  status: string;
}

export interface FareDoc {
  id: string;
  origin: string;
  destination: string;
  amount: number;
  currency?: string;
}

export interface PaymentRequest {
  id: string;
  userId?: string;
  userEmail: string;
  senderName: string;
  amount: number;
  plan: string;
  status: 'pending' | 'approved' | 'rejected';
  proofNote?: string;
  proofImageBase64?: string;
  rejectReason?: string;
  createdAt?: Date;
}
