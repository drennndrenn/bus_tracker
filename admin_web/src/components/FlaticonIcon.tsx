/** Flaticon Uicons — https://www.flaticon.com/uicons */
export type TabIconId =
  | 'overview'
  | 'companies'
  | 'payments'
  | 'admins'
  | 'routes'
  | 'buses'
  | 'fares';

type ExtraIconId =
  | 'sign-out'
  | 'check'
  | 'chart-pie'
  | 'bus-alt'
  | 'map-marker'
  | 'user-shield'
  | 'user'
  | 'lock'
  | 'eye'
  | 'eye-crossed'
  | 'shield-check';

export type FlaticonIconName = TabIconId | ExtraIconId;

const ICON_CLASS: Record<FlaticonIconName, string> = {
  overview: 'fi-rr-dashboard',
  companies: 'fi-rr-building',
  payments: 'fi-rr-credit-card',
  admins: 'fi-rr-users-gear',
  routes: 'fi-rr-route',
  buses: 'fi-rr-bus',
  fares: 'fi-rr-coins',
  'sign-out': 'fi-rr-sign-out-alt',
  check: 'fi-rr-check-circle',
  'chart-pie': 'fi-rr-chart-pie',
  'bus-alt': 'fi-rr-bus-alt',
  'map-marker': 'fi-rr-map-marker',
  'user-shield': 'fi-rr-user-shield',
  user: 'fi-rr-user',
  lock: 'fi-rr-lock',
  eye: 'fi-rr-eye',
  'eye-crossed': 'fi-rr-eye-crossed',
  'shield-check': 'fi-rr-shield-check',
};

interface FlaticonIconProps {
  name: FlaticonIconName;
  className?: string;
  title?: string;
}

export function FlaticonIcon({ name, className = '', title }: FlaticonIconProps) {
  return (
    <span
      className={`fi ${ICON_CLASS[name]} inline-flex shrink-0 items-center justify-center leading-none ${className}`}
      aria-hidden={title ? undefined : true}
      title={title}
      role={title ? 'img' : undefined}
    />
  );
}
