import { FormEvent, useEffect, useState } from 'react';
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
import { EditModal, ModalField, ModalInput, ModalSelect } from '../components/EditModal';
import { AlertBanner, Btn, Input, PageHeader, Select, StatCard, StatusPill } from '../components/ui';
import { useAuth } from '../context/AuthContext';
import { BACHELOR_EXPRESS_COMPANY_ID, seedBachelorExpressIfEmpty } from '../lib/bachelorExpressSeed';
import { db } from '../lib/firebase';
import type { BusDoc, FareDoc, RouteDoc } from '../lib/types';

const TABS = [
  { id: 'overview', label: 'Overview' },
  { id: 'routes', label: 'Routes' },
  { id: 'buses', label: 'Buses' },
  { id: 'fares', label: 'Fares' },
];

const LOCATIONS = [
  'Tagum City',
  'Panabo City',
  'Carmen',
  'Sto. Tomas',
  'Kapalong',
  'New Corella',
  'Asuncion',
];

function shortId(prefix: string, id: string) {
  return `${prefix}-${id.slice(0, 6).toUpperCase()}`;
}

export function SubAdminDashboard() {
  const { profile } = useAuth();
  const companyId = profile?.companyId ?? '';

  const [companyName, setCompanyName] = useState('');
  const [tab, setTab] = useState('overview');
  const [routes, setRoutes] = useState<RouteDoc[]>([]);
  const [buses, setBuses] = useState<BusDoc[]>([]);
  const [fares, setFares] = useState<FareDoc[]>([]);
  const [message, setMessage] = useState('');

  const [routeName, setRouteName] = useState('');
  const [routeOrigin, setRouteOrigin] = useState(LOCATIONS[0]);
  const [routeDestination, setRouteDestination] = useState(LOCATIONS[1]);

  const [busPlate, setBusPlate] = useState('');
  const [busRouteLabel, setBusRouteLabel] = useState(LOCATIONS[0]);

  const [fareOrigin, setFareOrigin] = useState(LOCATIONS[0]);
  const [fareDestination, setFareDestination] = useState(LOCATIONS[1]);
  const [fareAmount, setFareAmount] = useState('50');

  const [editRoute, setEditRoute] = useState<RouteDoc | null>(null);
  const [editBus, setEditBus] = useState<BusDoc | null>(null);
  const [editFare, setEditFare] = useState<FareDoc | null>(null);
  const [saving, setSaving] = useState(false);

  async function loadCompanyData() {
    if (!companyId) return;
    const companySnap = await getDoc(doc(db, 'companies', companyId));
    if (companySnap.exists()) {
      setCompanyName(String(companySnap.data().name ?? ''));
    }
    const routeSnap = await getDocs(collection(db, 'companies', companyId, 'routes'));
    const busSnap = await getDocs(collection(db, 'companies', companyId, 'buses'));
    const fareSnap = await getDocs(collection(db, 'companies', companyId, 'fares'));

    setRoutes(
      routeSnap.docs.map((d) => ({
        id: d.id,
        name: d.data().name,
        origin: d.data().origin,
        destination: d.data().destination,
        status: d.data().status,
      })),
    );
    setBuses(
      busSnap.docs.map((d) => ({
        id: d.id,
        plateNumber: d.data().plateNumber,
        routeLabel: d.data().routeLabel,
        status: d.data().status,
      })),
    );
    setFares(
      fareSnap.docs.map((d) => ({
        id: d.id,
        origin: d.data().origin,
        destination: d.data().destination,
        amount: d.data().amount,
        currency: d.data().currency,
      })),
    );
  }

  useEffect(() => {
    if (!companyId) {
      setMessage('No company linked to this sub-admin account.');
      return;
    }
    (async () => {
      try {
        if (companyId === BACHELOR_EXPRESS_COMPANY_ID) {
          const seeded = await seedBachelorExpressIfEmpty(companyId);
          if (seeded) {
            setMessage('Loaded default routes, buses, and fares for Bachelor Express.');
          }
        }
        await loadCompanyData();
      } catch (err) {
        setMessage(err instanceof Error ? err.message : 'Failed to load company data');
      }
    })();
  }, [companyId]);

  async function addRoute(event: FormEvent) {
    event.preventDefault();
    if (!companyId) return;
    await addDoc(collection(db, 'companies', companyId, 'routes'), {
      name: routeName || `${routeOrigin} line`,
      origin: routeOrigin,
      destination: routeDestination,
      status: 'active',
      updatedAt: serverTimestamp(),
    });
    setRouteName('');
    setMessage('Route added.');
    await loadCompanyData();
  }

  async function addBus(event: FormEvent) {
    event.preventDefault();
    if (!companyId) return;
    await addDoc(collection(db, 'companies', companyId, 'buses'), {
      plateNumber: busPlate,
      routeLabel: busRouteLabel,
      status: 'active',
      updatedAt: serverTimestamp(),
    });
    setBusPlate('');
    setMessage('Bus added.');
    await loadCompanyData();
  }

  async function addFare(event: FormEvent) {
    event.preventDefault();
    if (!companyId) return;
    await addDoc(collection(db, 'companies', companyId, 'fares'), {
      origin: fareOrigin,
      destination: fareDestination,
      amount: Number(fareAmount),
      currency: 'PHP',
      updatedAt: serverTimestamp(),
    });
    setMessage('Fare added.');
    await loadCompanyData();
  }

  async function deleteItem(collectionName: 'routes' | 'buses' | 'fares', id: string) {
    if (!companyId) return;
    if (!confirm('Delete this record?')) return;
    await deleteDoc(doc(db, 'companies', companyId, collectionName, id));
    setMessage(`${collectionName.slice(0, -1)} removed.`);
    await loadCompanyData();
  }

  async function saveRouteEdit() {
    if (!companyId || !editRoute) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'companies', companyId, 'routes', editRoute.id), {
        name: editRoute.name,
        origin: editRoute.origin,
        destination: editRoute.destination,
        status: editRoute.status,
        updatedAt: serverTimestamp(),
      });
      setEditRoute(null);
      setMessage('Route updated.');
      await loadCompanyData();
    } finally {
      setSaving(false);
    }
  }

  async function saveBusEdit() {
    if (!companyId || !editBus) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'companies', companyId, 'buses', editBus.id), {
        plateNumber: editBus.plateNumber,
        routeLabel: editBus.routeLabel,
        status: editBus.status,
        updatedAt: serverTimestamp(),
      });
      setEditBus(null);
      setMessage('Bus updated.');
      await loadCompanyData();
    } finally {
      setSaving(false);
    }
  }

  async function saveFareEdit() {
    if (!companyId || !editFare) return;
    setSaving(true);
    try {
      await updateDoc(doc(db, 'companies', companyId, 'fares', editFare.id), {
        origin: editFare.origin,
        destination: editFare.destination,
        amount: Number(editFare.amount),
        currency: editFare.currency ?? 'PHP',
        updatedAt: serverTimestamp(),
      });
      setEditFare(null);
      setMessage('Fare updated.');
      await loadCompanyData();
    } finally {
      setSaving(false);
    }
  }

  return (
    <AdminLayout
      title={companyName || (companyId ? companyId : 'No company')}
      role="sub_admin"
      tabs={TABS}
      activeTab={tab}
      onTabChange={setTab}
    >
      <PageHeader
        title="Sub Admin Dashboard"
        subtitle="Manage routes, buses, and fares for your assigned bus company."
      />

      {message && <AlertBanner tone={message.includes('No company') ? 'error' : 'info'}>{message}</AlertBanner>}

      {tab === 'overview' && (
        <div className="grid gap-4 sm:grid-cols-3">
          <StatCard label="Routes" value={routes.length} accent="blue" icon="routes" />
          <StatCard label="Buses" value={buses.length} accent="green" icon="buses" />
          <StatCard label="Fare rows" value={fares.length} accent="violet" icon="fares" />
        </div>
      )}

      {tab === 'routes' && (
        <AdminDataTable
          title="Routes"
          rows={routes}
          rowKey={(r) => r.id}
          searchPlaceholder="Search route…"
          searchFn={(r, q) =>
            [r.name, r.origin, r.destination, r.id].some((v) =>
              String(v ?? '').toLowerCase().includes(q),
            )
          }
          categoryLabel="All Origins"
          categoryFn={(r) => r.origin}
          statusFn={(r) => r.status}
          initialSortKey="name"
          sortFns={{
            id: (r) => r.id,
            name: (r) => r.name,
            origin: (r) => r.origin,
            destination: (r) => r.destination,
            status: (r) => r.status,
          }}
          toolbar={
            <form className="flex flex-nowrap items-center gap-3" onSubmit={addRoute}>
              <Input
                className="min-w-[140px] flex-1 !w-auto"
                placeholder="Route name"
                value={routeName}
                onChange={(e) => setRouteName(e.target.value)}
              />
              <Select
                className="min-w-[140px] flex-1 !w-auto"
                value={routeOrigin}
                onChange={(e) => setRouteOrigin(e.target.value)}
              >
                {LOCATIONS.map((l) => (
                  <option key={l}>{l}</option>
                ))}
              </Select>
              <Select
                className="min-w-[140px] flex-1 !w-auto"
                value={routeDestination}
                onChange={(e) => setRouteDestination(e.target.value)}
              >
                {LOCATIONS.map((l) => (
                  <option key={l}>{l}</option>
                ))}
              </Select>
              <Btn type="submit" variant="primary" className="shrink-0 whitespace-nowrap">
                Add route
              </Btn>
            </form>
          }
          onEdit={setEditRoute}
          onDelete={(r) => deleteItem('routes', r.id)}
          columns={[
            {
              key: 'id',
              label: 'Route ID',
              sortable: true,
              render: (r) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('RTE', r.id)}
                </span>
              ),
            },
            {
              key: 'name',
              label: 'Route name',
              sortable: true,
              render: (r) => <span className="font-semibold text-brand-navy">{r.name}</span>,
            },
            {
              key: 'origin',
              label: 'From',
              sortable: true,
              render: (r) => r.origin,
            },
            {
              key: 'destination',
              label: 'To',
              sortable: true,
              render: (r) => r.destination,
            },
            {
              key: 'status',
              label: 'Status',
              sortable: true,
              render: (r) => <StatusPill status={r.status} />,
            },
          ]}
        />
      )}

      {tab === 'buses' && (
        <AdminDataTable
          title="Buses"
          rows={buses}
          rowKey={(b) => b.id}
          searchPlaceholder="Search bus…"
          searchFn={(b, q) =>
            [b.plateNumber, b.routeLabel, b.id].some((v) => String(v ?? '').toLowerCase().includes(q))
          }
          categoryLabel="All Route labels"
          categoryFn={(b) => b.routeLabel}
          statusFn={(b) => b.status}
          initialSortKey="plate"
          sortFns={{
            id: (b) => b.id,
            plate: (b) => b.plateNumber,
            routeLabel: (b) => b.routeLabel,
            status: (b) => b.status,
          }}
          toolbar={
            <form className="flex flex-nowrap items-center gap-3" onSubmit={addBus}>
              <Input
                className="min-w-[140px] flex-1 !w-auto"
                placeholder="Plate number"
                value={busPlate}
                onChange={(e) => setBusPlate(e.target.value)}
                required
              />
              <Select
                className="min-w-[140px] flex-1 !w-auto"
                value={busRouteLabel}
                onChange={(e) => setBusRouteLabel(e.target.value)}
              >
                {LOCATIONS.map((l) => (
                  <option key={l}>{l}</option>
                ))}
              </Select>
              <Btn type="submit" variant="primary" className="shrink-0 whitespace-nowrap">
                Add bus
              </Btn>
            </form>
          }
          onEdit={setEditBus}
          onDelete={(b) => deleteItem('buses', b.id)}
          columns={[
            {
              key: 'id',
              label: 'Bus ID',
              sortable: true,
              render: (b) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('BUS', b.id)}
                </span>
              ),
            },
            {
              key: 'plate',
              label: 'Plate number',
              sortable: true,
              render: (b) => <span className="font-mono font-semibold">{b.plateNumber}</span>,
            },
            {
              key: 'routeLabel',
              label: 'Route label',
              sortable: true,
              render: (b) => b.routeLabel,
            },
            {
              key: 'status',
              label: 'Status',
              sortable: true,
              render: (b) => <StatusPill status={b.status} />,
            },
          ]}
        />
      )}

      {tab === 'fares' && (
        <AdminDataTable
          title="Fares"
          rows={fares}
          rowKey={(f) => f.id}
          searchPlaceholder="Search fare…"
          searchFn={(f, q) =>
            [f.origin, f.destination, String(f.amount), f.id].some((v) =>
              String(v ?? '').toLowerCase().includes(q),
            )
          }
          categoryLabel="All Origins"
          categoryFn={(f) => f.origin}
          initialSortKey="origin"
          sortFns={{
            id: (f) => f.id,
            origin: (f) => f.origin,
            destination: (f) => f.destination,
            amount: (f) => f.amount,
          }}
          toolbar={
            <form className="flex flex-nowrap items-center gap-3" onSubmit={addFare}>
              <Select
                className="min-w-[140px] flex-1 !w-auto"
                value={fareOrigin}
                onChange={(e) => setFareOrigin(e.target.value)}
              >
                {LOCATIONS.map((l) => (
                  <option key={l}>{l}</option>
                ))}
              </Select>
              <Select
                className="min-w-[140px] flex-1 !w-auto"
                value={fareDestination}
                onChange={(e) => setFareDestination(e.target.value)}
              >
                {LOCATIONS.map((l) => (
                  <option key={l}>{l}</option>
                ))}
              </Select>
              <Input
                className="w-24 shrink-0 !w-24"
                type="number"
                min={1}
                placeholder="Amount"
                value={fareAmount}
                onChange={(e) => setFareAmount(e.target.value)}
              />
              <Btn type="submit" variant="success" className="shrink-0 whitespace-nowrap">
                Add fare
              </Btn>
            </form>
          }
          onEdit={setEditFare}
          onDelete={(f) => deleteItem('fares', f.id)}
          columns={[
            {
              key: 'id',
              label: 'Fare ID',
              sortable: true,
              render: (f) => (
                <span className="font-mono text-xs font-semibold text-brand-blue">
                  {shortId('FAR', f.id)}
                </span>
              ),
            },
            {
              key: 'origin',
              label: 'From',
              sortable: true,
              render: (f) => f.origin,
            },
            {
              key: 'destination',
              label: 'To',
              sortable: true,
              render: (f) => f.destination,
            },
            {
              key: 'amount',
              label: 'Amount',
              sortable: true,
              render: (f) => <span className="font-bold text-brand-green">₱{f.amount}</span>,
            },
          ]}
        />
      )}

      <EditModal
        open={editRoute !== null}
        title="Edit Route"
        onClose={() => setEditRoute(null)}
        onSave={saveRouteEdit}
        saving={saving}
      >
        <ModalField label="Route ID">
          <ModalInput value={editRoute ? shortId('RTE', editRoute.id) : ''} readOnly disabled />
        </ModalField>
        <ModalField label="Route name">
          <ModalInput
            value={editRoute?.name ?? ''}
            onChange={(e) => editRoute && setEditRoute({ ...editRoute, name: e.target.value })}
            required
          />
        </ModalField>
        <ModalField label="From">
          <ModalSelect
            value={editRoute?.origin ?? ''}
            onChange={(e) => editRoute && setEditRoute({ ...editRoute, origin: e.target.value })}
          >
            {LOCATIONS.map((l) => (
              <option key={l}>{l}</option>
            ))}
          </ModalSelect>
        </ModalField>
        <ModalField label="To">
          <ModalSelect
            value={editRoute?.destination ?? ''}
            onChange={(e) => editRoute && setEditRoute({ ...editRoute, destination: e.target.value })}
          >
            {LOCATIONS.map((l) => (
              <option key={l}>{l}</option>
            ))}
          </ModalSelect>
        </ModalField>
        <ModalField label="Status">
          <ModalSelect
            value={editRoute?.status ?? 'active'}
            onChange={(e) => editRoute && setEditRoute({ ...editRoute, status: e.target.value })}
          >
            <option value="active">Active</option>
            <option value="suspended">Suspended</option>
          </ModalSelect>
        </ModalField>
      </EditModal>

      <EditModal
        open={editBus !== null}
        title="Edit Bus"
        onClose={() => setEditBus(null)}
        onSave={saveBusEdit}
        saving={saving}
      >
        <ModalField label="Bus ID">
          <ModalInput value={editBus ? shortId('BUS', editBus.id) : ''} readOnly disabled />
        </ModalField>
        <ModalField label="Plate number">
          <ModalInput
            value={editBus?.plateNumber ?? ''}
            onChange={(e) => editBus && setEditBus({ ...editBus, plateNumber: e.target.value })}
            required
          />
        </ModalField>
        <ModalField label="Route label">
          <ModalSelect
            value={editBus?.routeLabel ?? ''}
            onChange={(e) => editBus && setEditBus({ ...editBus, routeLabel: e.target.value })}
          >
            {LOCATIONS.map((l) => (
              <option key={l}>{l}</option>
            ))}
          </ModalSelect>
        </ModalField>
        <ModalField label="Status">
          <ModalSelect
            value={editBus?.status ?? 'active'}
            onChange={(e) => editBus && setEditBus({ ...editBus, status: e.target.value })}
          >
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
          </ModalSelect>
        </ModalField>
      </EditModal>

      <EditModal
        open={editFare !== null}
        title="Edit Fare"
        onClose={() => setEditFare(null)}
        onSave={saveFareEdit}
        saving={saving}
      >
        <ModalField label="Fare ID">
          <ModalInput value={editFare ? shortId('FAR', editFare.id) : ''} readOnly disabled />
        </ModalField>
        <ModalField label="From">
          <ModalSelect
            value={editFare?.origin ?? ''}
            onChange={(e) => editFare && setEditFare({ ...editFare, origin: e.target.value })}
          >
            {LOCATIONS.map((l) => (
              <option key={l}>{l}</option>
            ))}
          </ModalSelect>
        </ModalField>
        <ModalField label="To">
          <ModalSelect
            value={editFare?.destination ?? ''}
            onChange={(e) => editFare && setEditFare({ ...editFare, destination: e.target.value })}
          >
            {LOCATIONS.map((l) => (
              <option key={l}>{l}</option>
            ))}
          </ModalSelect>
        </ModalField>
        <ModalField label="Amount (PHP)">
          <ModalInput
            type="number"
            min={1}
            value={editFare?.amount ?? ''}
            onChange={(e) =>
              editFare && setEditFare({ ...editFare, amount: Number(e.target.value) || 0 })
            }
            required
          />
        </ModalField>
      </EditModal>
    </AdminLayout>
  );
}
