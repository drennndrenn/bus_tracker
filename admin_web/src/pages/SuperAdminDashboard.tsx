import { useEffect, useState } from 'react';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  serverTimestamp,
  updateDoc,
} from 'firebase/firestore';
import { AdminLayout } from '../components/AdminLayout';
import { AdminDataTable } from '../components/AdminDataTable';
import { EditModal, ModalField, ModalInput, ModalSelect, ModalTextarea } from '../components/EditModal';
import { AlertBanner, Btn, Input, PageHeader, StatCard, StatusPill } from '../components/ui';
import {
  BACHELOR_EXPRESS_COMPANY_ID,
  seedBachelorExpressIfEmpty,
} from '../lib/bachelorExpressSeed';
import { db } from '../lib/firebase';
import type { Company, PaymentRequest } from '../lib/types';

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'companies', label: 'Companies' },
  { id: 'payments', label: 'Payments' },
  { id: 'admins', label: 'Sub-admins' },
];

function shortId(prefix: string, id: string) {
  return `${prefix}-${id.slice(0, 6).toUpperCase()}`;
}

export function SuperAdminDashboard() {
  const [tab, setTab] = useState('overview');
  const [companies, setCompanies] = useState<Company[]>([]);
  const [payments, setPayments] = useState<PaymentRequest[]>([]);
  const [subAdmins, setSubAdmins] = useState<{ id: string; email: string; companyId: string }[]>([]);
  const [stats, setStats] = useState({ companies: 0, pending: 0, routes: 0, buses: 0 });
  const [companyName, setCompanyName] = useState('');
  const [companyRegion, setCompanyRegion] = useState('');
  const [message, setMessage] = useState('');
  const [editCompany, setEditCompany] = useState<Company | null>(null);
  const [viewPayment, setViewPayment] = useState<PaymentRequest | null>(null);
  const [editAdmin, setEditAdmin] = useState<{ id: string; email: string; companyId: string } | null>(
    null,
  );
  const [saving, setSaving] = useState(false);

  async function loadData() {
    const companySnap = await getDocs(collection(db, 'companies'));
    const companyList: Company[] = companySnap.docs.map((d) => ({
      id: d.id,
      name: d.data().name,
      region: d.data().region,
      status: d.data().status,
    }));
    setCompanies(companyList);

    if (companyList.some((c) => c.id === BACHELOR_EXPRESS_COMPANY_ID)) {
      await seedBachelorExpressIfEmpty(BACHELOR_EXPRESS_COMPANY_ID);
    }

    let routeCount = 0;
    let busCount = 0;
    for (const company of companyList) {
      const routes = await getDocs(collection(db, 'companies', company.id, 'routes'));
      const buses = await getDocs(collection(db, 'companies', company.id, 'buses'));
      routeCount += routes.size;
      busCount += buses.size;
    }

    const paymentSnap = await getDocs(collection(db, 'payment_requests'));
    const paymentList: PaymentRequest[] = paymentSnap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        userId: data.userId,
        userEmail: data.userEmail,
        senderName: data.senderName,
        amount: data.amount,
        plan: data.plan,
        status: data.status,
        proofNote: data.proofNote,
        rejectReason: data.rejectReason,
      };
    });
    setPayments(paymentList);

    const adminSnap = await getDocs(collection(db, 'admins'));
    setSubAdmins(
      adminSnap.docs
        .filter((d) => d.data().role === 'sub_admin')
        .map((d) => ({
          id: d.id,
          email: d.data().email,
          companyId: d.data().companyId,
        })),
    );

    setStats({
      companies: companyList.length,
      pending: paymentList.filter((p) => p.status === 'pending').length,
      routes: routeCount,
      buses: busCount,
    });
  }

  useEffect(() => {
    loadData().catch((err) => setMessage(err instanceof Error ? err.message : 'Load failed'));
  }, []);

  async function addCompany() {
    if (!companyName.trim()) return;
    await addDoc(collection(db, 'companies'), {
      name: companyName.trim(),
      region: companyRegion.trim(),
      status: 'active',
      createdAt: serverTimestamp(),
    });
    setCompanyName('');
    setMessage('Company added.');
    await loadData();
  }

  async function removeCompany(id: string) {
    if (!confirm('Delete this bus company?')) return;
    await deleteDoc(doc(db, 'companies', id));
    setMessage('Company removed.');
    await loadData();
  }

  async function saveCompanyEdit() {
    if (!editCompany) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'companies', editCompany.id), {
        name: editCompany.name.trim(),
        region: editCompany.region?.trim() ?? '',
        status: editCompany.status ?? 'active',
      });
      setEditCompany(null);
      setMessage('Company updated.');
      await loadData();
    } finally {
      setSaving(false);
    }
  }

  async function deletePayment(payment: PaymentRequest) {
    if (!confirm('Delete this payment request?')) return;
    await deleteDoc(doc(db, 'payment_requests', payment.id));
    setViewPayment(null);
    setMessage('Payment request deleted.');
    await loadData();
  }

  async function openPaymentView(payment: PaymentRequest) {
    const snap = await getDoc(doc(db, 'payment_requests', payment.id));
    if (!snap.exists()) {
      setMessage('Payment request not found.');
      return;
    }
    const data = snap.data();
    setViewPayment({
      id: snap.id,
      userId: data.userId,
      userEmail: data.userEmail,
      senderName: data.senderName,
      amount: data.amount,
      plan: data.plan,
      status: data.status,
      proofNote: data.proofNote,
      proofImageBase64: data.proofImageBase64,
      rejectReason: data.rejectReason,
    });
  }

  async function reviewPayment(
    payment: PaymentRequest,
    decision: 'approved' | 'rejected',
    rejectReason?: string,
  ) {
    if (!payment.userId) {
      setMessage('Payment has no linked commuter account.');
      return;
    }
    if (payment.status !== 'pending') {
      setMessage('This payment was already reviewed.');
      return;
    }

    setSaving(true);
    try {
      const paymentRef = doc(db, 'payment_requests', payment.id);
      const commuterRef = doc(db, 'commuters', payment.userId);

      await updateDoc(paymentRef, {
        status: decision,
        rejectReason: decision === 'rejected' ? rejectReason || 'Payment could not be verified' : null,
        reviewedAt: serverTimestamp(),
      });

      if (decision === 'approved') {
        await updateDoc(commuterRef, {
          subscriptionStatus: 'pro',
          activePlan: payment.plan || 'pro_monthly',
          proActivatedAt: serverTimestamp(),
          pendingPaymentId: null,
          rejectReason: null,
          updatedAt: serverTimestamp(),
        });
      } else {
        await updateDoc(commuterRef, {
          subscriptionStatus: 'free',
          activePlan: null,
          pendingPaymentId: null,
          rejectReason: rejectReason || 'Payment could not be verified',
          updatedAt: serverTimestamp(),
        });
      }

      const alertBody =
        decision === 'approved'
          ? 'Your Pro payment was approved. Pro features are now active in the commuter app.'
          : rejectReason || 'Payment could not be verified';

      await addDoc(collection(db, 'commuter_alerts'), {
        userId: payment.userId,
        type: decision === 'approved' ? 'payment_approved' : 'payment_rejected',
        title: decision === 'approved' ? 'Pro plan activated' : 'Payment rejected',
        body: alertBody,
        read: false,
        createdAt: serverTimestamp(),
      });

      setViewPayment(null);
      setMessage(
        decision === 'approved'
          ? 'Payment approved. Commuter Pro subscription activated.'
          : 'Payment rejected.',
      );
      await loadData();
    } catch (err) {
      setMessage(err instanceof Error ? err.message : 'Review failed');
    } finally {
      setSaving(false);
    }
  }

  async function saveAdminEdit() {
    if (!editAdmin) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'admins', editAdmin.id), {
        companyId: editAdmin.companyId,
      });
      setEditAdmin(null);
      setMessage('Sub-admin updated.');
      await loadData();
    } finally {
      setSaving(false);
    }
  }

  return (
    <AdminLayout
      title="Platform control"
      role="super_admin"
      tabs={TABS}
      activeTab={tab}
      onTabChange={setTab}
    >
      <PageHeader
        title="Super Admin Dashboard"
        subtitle="Manage companies, Pro subscriptions, and sub-admin accounts."
      />

      {message && <AlertBanner>{message}</AlertBanner>}

      {tab === 'overview' && (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <StatCard label="Bus companies" value={stats.companies} accent="blue" icon="companies" />
          <StatCard label="Pending Pro payments" value={stats.pending} accent="amber" icon="payments" />
          <StatCard label="Total routes" value={stats.routes} accent="green" icon="routes" />
          <StatCard label="Total buses" value={stats.buses} accent="violet" icon="buses" />
        </div>
      )}

      {tab === 'companies' && (
        <AdminDataTable
          title="Bus companies"
          rows={companies}
          rowKey={(c) => c.id}
          searchPlaceholder="Search company…"
          searchFn={(c, q) =>
            [c.name, c.region, c.id].some((v) => String(v ?? '').toLowerCase().includes(q))
          }
          categoryLabel="All Regions"
          categoryFn={(c) => c.region ?? 'Unknown'}
          statusFn={(c) => c.status ?? 'active'}
          initialSortKey="name"
          sortFns={{
            id: (c) => c.id,
            name: (c) => c.name,
            region: (c) => c.region ?? '',
            status: (c) => c.status ?? '',
          }}
          toolbar={
            <div className="flex flex-wrap gap-3">
              <Input
                className="min-w-[180px] flex-1"
                placeholder="Company name"
                value={companyName}
                onChange={(e) => setCompanyName(e.target.value)}
              />
              <Input
                className="min-w-[160px] flex-1"
                placeholder="Region"
                value={companyRegion}
                onChange={(e) => setCompanyRegion(e.target.value)}
              />
              <Btn variant="primary" onClick={addCompany}>
                Add company
              </Btn>
            </div>
          }
          onEdit={setEditCompany}
          onDelete={(c) => removeCompany(c.id)}
          columns={[
            {
              key: 'id',
              label: 'Company ID',
              sortable: true,
              render: (c) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('CMP', c.id)}
                </span>
              ),
            },
            {
              key: 'name',
              label: 'Company name',
              sortable: true,
              render: (c) => <span className="font-semibold text-brand-navy">{c.name}</span>,
            },
            {
              key: 'region',
              label: 'Region',
              sortable: true,
              render: (c) => c.region,
            },
            {
              key: 'status',
              label: 'Status',
              sortable: true,
              render: (c) => <StatusPill status={c.status ?? 'active'} />,
            },
          ]}
        />
      )}

      {tab === 'payments' && (
        <AdminDataTable
          title="Subscription payment review"
          rows={payments}
          rowKey={(p) => p.id}
          searchPlaceholder="Search payment…"
          searchFn={(p, q) =>
            [p.userEmail, p.senderName, p.proofNote, p.plan].some((v) =>
              String(v ?? '').toLowerCase().includes(q),
            )
          }
          categoryLabel="All Plans"
          categoryFn={(p) => p.plan ?? 'unknown'}
          statusFn={(p) => p.status}
          initialSortKey="amount"
          sortFns={{
            id: (p) => p.id,
            userEmail: (p) => p.userEmail,
            amount: (p) => p.amount,
            status: (p) => p.status,
          }}
          onView={openPaymentView}
          onDelete={deletePayment}
          columns={[
            {
              key: 'id',
              label: 'Request ID',
              sortable: true,
              render: (p) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('PAY', p.id)}
                </span>
              ),
            },
            {
              key: 'userEmail',
              label: 'User',
              sortable: true,
              render: (p) => p.userEmail,
            },
            {
              key: 'sender',
              label: 'Sender',
              render: (p) => p.senderName,
            },
            {
              key: 'amount',
              label: 'Amount',
              sortable: true,
              render: (p) => <span className="font-bold">₱{p.amount}</span>,
            },
            {
              key: 'proof',
              label: 'Proof',
              render: (p) => p.proofNote || '—',
            },
            {
              key: 'status',
              label: 'Status',
              sortable: true,
              render: (p) => <StatusPill status={p.status} />,
            },
          ]}
        />
      )}

      {tab === 'admins' && (
        <AdminDataTable
          title="Sub-admin accounts"
          rows={subAdmins}
          rowKey={(a) => a.id}
          searchPlaceholder="Search admin…"
          searchFn={(a, q) =>
            [a.email, a.companyId, a.id].some((v) => String(v ?? '').toLowerCase().includes(q))
          }
          categoryLabel="All Companies"
          categoryFn={(a) => a.companyId ?? 'unassigned'}
          initialSortKey="email"
          sortFns={{
            id: (a) => a.id,
            email: (a) => a.email,
            companyId: (a) => a.companyId ?? '',
          }}
          onEdit={setEditAdmin}
          columns={[
            {
              key: 'id',
              label: 'Admin ID',
              sortable: true,
              render: (a) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('ADM', a.id)}
                </span>
              ),
            },
            {
              key: 'email',
              label: 'Email',
              sortable: true,
              render: (a) => <span className="font-medium">{a.email}</span>,
            },
            {
              key: 'companyId',
              label: 'Company',
              sortable: true,
              render: (a) => (
                <span className="rounded-lg bg-blue-50 px-2 py-1 font-mono text-xs text-brand-blue">
                  {a.companyId}
                </span>
              ),
            },
            {
              key: 'status',
              label: 'Status',
              render: () => <StatusPill status="active" />,
            },
          ]}
        />
      )}

      <EditModal
        open={editCompany !== null}
        title="Edit Company"
        onClose={() => setEditCompany(null)}
        onSave={saveCompanyEdit}
        saving={saving}
      >
        <ModalField label="Company ID">
          <ModalInput
            value={editCompany ? shortId('CMP', editCompany.id) : ''}
            readOnly
            disabled
          />
        </ModalField>
        <ModalField label="Company name">
          <ModalInput
            value={editCompany?.name ?? ''}
            onChange={(e) =>
              editCompany && setEditCompany({ ...editCompany, name: e.target.value })
            }
            required
          />
        </ModalField>
        <ModalField label="Region">
          <ModalInput
            value={editCompany?.region ?? ''}
            onChange={(e) =>
              editCompany && setEditCompany({ ...editCompany, region: e.target.value })
            }
          />
        </ModalField>
        <ModalField label="Status">
          <ModalSelect
            value={editCompany?.status ?? 'active'}
            onChange={(e) =>
              editCompany && setEditCompany({ ...editCompany, status: e.target.value })
            }
          >
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="suspended">Suspended</option>
          </ModalSelect>
        </ModalField>
      </EditModal>

      <EditModal
        open={viewPayment !== null}
        title="View Payment"
        onClose={() => setViewPayment(null)}
        readOnly
        hideFooterClose
        footerExtra={
          viewPayment?.status === 'pending' ? (
            <>
              <Btn
                type="button"
                variant="success"
                disabled={saving}
                onClick={() => reviewPayment(viewPayment, 'approved')}
              >
                Approve payment
              </Btn>
              <Btn
                type="button"
                variant="danger"
                disabled={saving}
                onClick={async () => {
                  const reason = window.prompt('Rejection reason (optional):') ?? undefined;
                  await reviewPayment(viewPayment, 'rejected', reason);
                }}
              >
                Reject
              </Btn>
            </>
          ) : undefined
        }
      >
        <ModalField label="Request ID">
          <ModalInput
            value={viewPayment ? shortId('PAY', viewPayment.id) : ''}
            readOnly
            disabled
          />
        </ModalField>
        <ModalField label="User email">
          <ModalInput type="email" value={viewPayment?.userEmail ?? ''} readOnly disabled />
        </ModalField>
        <ModalField label="Sender name">
          <ModalInput value={viewPayment?.senderName ?? ''} readOnly disabled />
        </ModalField>
        <ModalField label="Amount (PHP)">
          <ModalInput value={viewPayment ? `₱${viewPayment.amount}` : ''} readOnly disabled />
        </ModalField>
        <ModalField label="Plan">
          <ModalInput value={viewPayment?.plan ?? ''} readOnly disabled />
        </ModalField>
        <ModalField label="Status">
          <ModalInput
            value={
              viewPayment?.status
                ? viewPayment.status.charAt(0).toUpperCase() + viewPayment.status.slice(1)
                : ''
            }
            readOnly
            disabled
          />
        </ModalField>
        <ModalField label="Proof note" span={2} optional>
          <ModalTextarea value={viewPayment?.proofNote ?? '—'} readOnly disabled />
        </ModalField>
        {viewPayment?.proofImageBase64 && (
          <ModalField label="Proof screenshot" span={2}>
            <div className="overflow-hidden rounded-lg border border-slate-200 bg-slate-50 p-2">
              <img
                src={`data:image/jpeg;base64,${viewPayment.proofImageBase64}`}
                alt="Payment proof"
                className="mx-auto max-h-80 w-full object-contain"
              />
            </div>
          </ModalField>
        )}
        {viewPayment?.status === 'rejected' && (
          <ModalField label="Reject reason" span={2} optional>
            <ModalTextarea value={viewPayment.rejectReason ?? '—'} readOnly disabled />
          </ModalField>
        )}
      </EditModal>

      <EditModal
        open={editAdmin !== null}
        title="Edit Sub-admin"
        onClose={() => setEditAdmin(null)}
        onSave={saveAdminEdit}
        saving={saving}
      >
        <ModalField label="Admin ID">
          <ModalInput value={editAdmin ? shortId('ADM', editAdmin.id) : ''} readOnly disabled />
        </ModalField>
        <ModalField label="Email">
          <ModalInput value={editAdmin?.email ?? ''} readOnly disabled />
        </ModalField>
        <ModalField label="Company ID" span={2}>
          <ModalSelect
            value={editAdmin?.companyId ?? ''}
            onChange={(e) => editAdmin && setEditAdmin({ ...editAdmin, companyId: e.target.value })}
          >
            <option value="">— Select company —</option>
            {companies.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} ({c.id})
              </option>
            ))}
          </ModalSelect>
        </ModalField>
      </EditModal>
    </AdminLayout>
  );
}

