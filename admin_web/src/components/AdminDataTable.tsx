import type { ReactNode } from 'react';
import { useDataTable, type SortDir } from '../hooks/useDataTable';

export type TableColumn<T> = {
  key: string;
  label: string;
  sortable?: boolean;
  className?: string;
  render: (row: T) => ReactNode;
};

export interface AdminDataTableProps<T> {
  title: string;
  rows: T[];
  columns: TableColumn<T>[];
  rowKey: (row: T) => string;
  searchPlaceholder?: string;
  searchFn?: (row: T, query: string) => boolean;
  categoryLabel?: string;
  categoryFn?: (row: T) => string;
  statusFn?: (row: T) => string;
  sortFns?: Record<string, (row: T) => string | number>;
  initialSortKey?: string;
  pageSize?: number;
  toolbar?: ReactNode;
  onEdit?: (row: T) => void;
  onView?: (row: T) => void;
  onDelete?: (row: T) => void;
  renderActions?: (row: T) => ReactNode;
  emptyMessage?: string;
}

function SortIcon({ active, dir }: { active: boolean; dir: SortDir }) {
  return (
    <span className="ml-1 inline-flex flex-col text-[9px] leading-none text-slate-400">
      <span className={active && dir === 'asc' ? 'text-brand-blue' : ''}>▲</span>
      <span className={active && dir === 'desc' ? 'text-brand-blue' : ''}>▼</span>
    </span>
  );
}

export function AdminDataTable<T>({
  title,
  rows,
  columns,
  rowKey,
  searchPlaceholder = 'Search…',
  searchFn,
  categoryLabel = 'All Categories',
  categoryFn,
  statusFn,
  sortFns,
  initialSortKey,
  pageSize = 5,
  toolbar,
  onEdit,
  onView,
  onDelete,
  renderActions,
  emptyMessage = 'No records found.',
}: AdminDataTableProps<T>) {
  const table = useDataTable({
    rows,
    pageSize,
    searchFn,
    categoryFn,
    statusFn,
    sortFns,
    initialSortKey,
  });

  const showCategory = Boolean(categoryFn);
  const showStatus = Boolean(statusFn);
  const showActions = Boolean(renderActions || onEdit || onView || onDelete);

  return (
    <section className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
      <div className="border-b border-slate-100 px-6 py-5">
        <h3 className="text-xl font-bold text-brand-navy">{title}</h3>
      </div>

      {(toolbar || searchFn || showCategory || showStatus) && (
        <div className="space-y-4 border-b border-slate-100 px-6 py-4">
          {toolbar}
          <div className="flex flex-wrap items-center gap-3">
            {searchFn && (
              <div className="relative min-w-[200px] flex-1">
                <svg
                  className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  aria-hidden
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M21 21l-4.35-4.35M11 18a7 7 0 100-14 7 7 0 000 14z"
                  />
                </svg>
                <input
                  type="search"
                  value={table.filters.search}
                  onChange={(e) => table.setSearch(e.target.value)}
                  placeholder={searchPlaceholder}
                  className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm outline-none focus:border-brand-blue focus:ring-2 focus:ring-blue-100"
                />
              </div>
            )}
            {showCategory && (
              <select
                value={table.filters.category}
                onChange={(e) => table.setCategory(e.target.value)}
                className="min-w-[140px] rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm outline-none focus:border-brand-blue focus:ring-2 focus:ring-blue-100"
              >
                <option value="all">{categoryLabel}</option>
                {table.categoryOptions.map((opt) => (
                  <option key={opt} value={opt}>
                    {opt}
                  </option>
                ))}
              </select>
            )}
            {showStatus && (
              <select
                value={table.filters.status}
                onChange={(e) => table.setStatus(e.target.value)}
                className="min-w-[120px] rounded-lg border border-slate-200 bg-white px-3 py-2.5 text-sm outline-none focus:border-brand-blue focus:ring-2 focus:ring-blue-100"
              >
                <option value="all">All Status</option>
                {table.statusOptions.map((opt) => (
                  <option key={opt} value={opt}>
                    {opt.charAt(0).toUpperCase() + opt.slice(1)}
                  </option>
                ))}
              </select>
            )}
            <button
              type="button"
              onClick={table.resetFilters}
              className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
            >
              <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
                />
              </svg>
              Reset Filters
            </button>
          </div>
        </div>
      )}

      <div className="overflow-x-auto">
        <table className="w-full min-w-[720px] text-left text-sm">
          <thead>
            <tr className="border-b border-slate-100 bg-slate-50/80">
              {columns.map((col) => (
                <th
                  key={col.key}
                  className={`px-5 py-3.5 text-xs font-bold uppercase tracking-wide text-brand-navy ${col.className ?? ''}`}
                >
                  {col.sortable && sortFns?.[col.key] ? (
                    <button
                      type="button"
                      onClick={() => table.toggleSort(col.key)}
                      className="inline-flex items-center hover:text-primary"
                    >
                      {col.label}
                      <SortIcon active={table.sortKey === col.key} dir={table.sortDir} />
                    </button>
                  ) : (
                    col.label
                  )}
                </th>
              ))}
              {showActions && (
                <th className="px-5 py-3.5 text-right text-xs font-bold uppercase tracking-wide text-brand-navy">
                  Actions
                </th>
              )}
            </tr>
          </thead>
          <tbody>
            {table.paginated.length === 0 ? (
              <tr>
                <td
                  colSpan={columns.length + (showActions ? 1 : 0)}
                  className="px-5 py-12 text-center text-slate-500"
                >
                  {emptyMessage}
                </td>
              </tr>
            ) : (
              table.paginated.map((row) => (
                <tr key={rowKey(row)} className="border-b border-slate-50 transition hover:bg-slate-50/60">
                  {columns.map((col) => (
                    <td key={col.key} className={`px-5 py-4 text-slate-700 ${col.className ?? ''}`}>
                      {col.render(row)}
                    </td>
                  ))}
                  {showActions && (
                    <td className="px-5 py-4">
                      <div className="flex items-center justify-end gap-2">
                        {renderActions ? (
                          renderActions(row)
                        ) : (
                          <>
                            {onView && (
                              <button
                                type="button"
                                onClick={() => onView(row)}
                                className="inline-flex items-center gap-1.5 rounded-lg border-2 border-slate-300 px-3 py-1.5 text-xs font-bold text-slate-700 transition hover:bg-slate-50"
                              >
                                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                                  />
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                                  />
                                </svg>
                                View
                              </button>
                            )}
                            {onEdit && (
                              <button
                                type="button"
                                onClick={() => onEdit(row)}
                                className="inline-flex items-center gap-1.5 rounded-lg border-2 border-brand-blue px-3 py-1.5 text-xs font-bold text-brand-blue transition hover:bg-blue-50"
                              >
                                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"
                                  />
                                </svg>
                                Edit
                              </button>
                            )}
                            {onDelete && (
                              <button
                                type="button"
                                onClick={() => onDelete(row)}
                                className="inline-flex items-center gap-1.5 rounded-lg border-2 border-red-500 px-3 py-1.5 text-xs font-bold text-red-600 transition hover:bg-red-50"
                              >
                                <svg className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                  <path
                                    strokeLinecap="round"
                                    strokeLinejoin="round"
                                    strokeWidth={2}
                                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                                  />
                                </svg>
                                Delete
                              </button>
                            )}
                          </>
                        )}
                      </div>
                    </td>
                  )}
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      <div className="flex flex-wrap items-center justify-between gap-4 border-t border-slate-100 px-6 py-4">
        <p className="text-sm text-slate-500">
          Showing {table.rangeStart} to {table.rangeEnd} of {table.totalCount} entries
        </p>
        <div className="flex items-center gap-1">
          <PaginationBtn
            disabled={table.page <= 1}
            onClick={() => table.setPage(table.page - 1)}
          >
            ‹ Previous
          </PaginationBtn>
          {pageNumbers(table.page, table.totalPages).map((p) =>
            p === '…' ? (
              <span key={`ellipsis-${p}`} className="px-2 text-slate-400">
                …
              </span>
            ) : (
              <PaginationBtn
                key={p}
                active={table.page === p}
                onClick={() => table.setPage(p as number)}
              >
                {p}
              </PaginationBtn>
            ),
          )}
          <PaginationBtn
            disabled={table.page >= table.totalPages}
            onClick={() => table.setPage(table.page + 1)}
          >
            Next ›
          </PaginationBtn>
        </div>
      </div>
    </section>
  );
}

function PaginationBtn({
  children,
  active,
  disabled,
  onClick,
}: {
  children: ReactNode;
  active?: boolean;
  disabled?: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={`min-w-[36px] rounded-lg px-3 py-2 text-sm font-semibold transition disabled:cursor-not-allowed disabled:opacity-40 ${
        active
          ? 'bg-primary text-white shadow-sm'
          : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
      }`}
    >
      {children}
    </button>
  );
}

function pageNumbers(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const pages: (number | '…')[] = [1];
  if (current > 3) pages.push('…');
  for (let p = Math.max(2, current - 1); p <= Math.min(total - 1, current + 1); p++) {
    pages.push(p);
  }
  if (current < total - 2) pages.push('…');
  pages.push(total);
  return pages;
}
