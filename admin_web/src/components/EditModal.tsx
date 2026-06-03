import { useEffect, type FormEvent, type ReactNode } from 'react';
import { Btn, Input, Select } from './ui';

interface EditModalProps {
  open: boolean;
  title: string;
  onClose: () => void;
  onSave?: () => void | Promise<void>;
  saving?: boolean;
  readOnly?: boolean;
  children: ReactNode;
  footerExtra?: ReactNode;
  /** Hide the default Close/Cancel footer button (e.g. when footerExtra has actions). */
  hideFooterClose?: boolean;
}

export function EditModal({
  open,
  title,
  onClose,
  onSave,
  saving = false,
  readOnly = false,
  children,
  footerExtra,
  hideFooterClose = false,
}: EditModalProps) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (readOnly || !onSave) return;
    await onSave();
  }

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby="edit-modal-title"
    >
      <button
        type="button"
        className="absolute inset-0 bg-slate-900/50 backdrop-blur-[2px]"
        onClick={onClose}
        aria-label="Close dialog"
      />
      <form
        onSubmit={handleSubmit}
        className="relative z-10 flex max-h-[90vh] w-full max-w-2xl flex-col overflow-hidden rounded-2xl bg-white shadow-2xl"
      >
        <div className="flex items-center justify-between border-b border-slate-100 px-6 py-4">
          <h2 id="edit-modal-title" className="text-xl font-bold text-brand-navy">
            {title}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
            aria-label="Close"
          >
            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        <div className="overflow-y-auto px-6 py-5">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">{children}</div>
        </div>

        <div className="flex flex-wrap items-center justify-end gap-3 border-t border-slate-100 bg-slate-50/80 px-6 py-4">
          {footerExtra}
          {!hideFooterClose && (
            <Btn type="button" variant={readOnly ? 'primary' : 'ghost'} onClick={onClose} disabled={saving}>
              {readOnly ? 'Close' : 'Cancel'}
            </Btn>
          )}
          {!readOnly && (
            <Btn type="submit" variant="primary" disabled={saving}>
              {saving ? 'Saving…' : 'Save Changes'}
            </Btn>
          )}
        </div>
      </form>
    </div>
  );
}

export function ModalField({
  label,
  children,
  optional,
  span = 1,
}: {
  label: string;
  children: ReactNode;
  optional?: boolean;
  span?: 1 | 2;
}) {
  return (
    <div className={span === 2 ? 'sm:col-span-2' : ''}>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">
        {label}
        {optional && <span className="font-normal text-slate-400"> (Optional)</span>}
      </label>
      {children}
    </div>
  );
}

const fieldClass =
  '!w-full rounded-lg border-slate-200 bg-white focus:border-brand-blue focus:bg-white';

export function ModalInput(props: React.InputHTMLAttributes<HTMLInputElement>) {
  return <Input {...props} className={`${fieldClass} ${props.className ?? ''}`} disabled={props.disabled} readOnly={props.readOnly} />;
}

export function ModalSelect(props: React.SelectHTMLAttributes<HTMLSelectElement>) {
  return <Select {...props} className={`${fieldClass} ${props.className ?? ''}`} />;
}

export function ModalTextarea(props: React.TextareaHTMLAttributes<HTMLTextAreaElement>) {
  return (
    <textarea
      {...props}
      className={`min-h-[88px] w-full resize-y rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm outline-none focus:border-brand-blue focus:ring-2 focus:ring-blue-100 ${props.className ?? ''}`}
    />
  );
}
