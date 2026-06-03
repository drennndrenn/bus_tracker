import { useMemo, useState } from 'react';

export type SortDir = 'asc' | 'desc';

export interface DataTableFilterState {
  search: string;
  category: string;
  status: string;
}

export function useDataTable<T>({
  rows,
  pageSize = 10,
  searchFn,
  categoryFn,
  statusFn,
  sortFns,
  initialSortKey,
}: {
  rows: T[];
  pageSize?: number;
  searchFn?: (row: T, query: string) => boolean;
  categoryFn?: (row: T) => string;
  statusFn?: (row: T) => string;
  sortFns?: Record<string, (row: T) => string | number>;
  initialSortKey?: string;
}) {
  const [filters, setFilters] = useState<DataTableFilterState>({
    search: '',
    category: 'all',
    status: 'all',
  });
  const [sortKey, setSortKey] = useState(initialSortKey ?? '');
  const [sortDir, setSortDir] = useState<SortDir>('asc');
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    const q = filters.search.trim().toLowerCase();
    return rows.filter((row) => {
      if (q && searchFn && !searchFn(row, q)) return false;
      if (filters.category !== 'all' && categoryFn && categoryFn(row) !== filters.category) return false;
      if (filters.status !== 'all' && statusFn && statusFn(row) !== filters.status) return false;
      return true;
    });
  }, [rows, filters, searchFn, categoryFn, statusFn]);

  const sorted = useMemo(() => {
    if (!sortKey || !sortFns?.[sortKey]) return filtered;
    const fn = sortFns[sortKey];
    const copy = [...filtered];
    copy.sort((a, b) => {
      const av = fn(a);
      const bv = fn(b);
      if (typeof av === 'number' && typeof bv === 'number') {
        return sortDir === 'asc' ? av - bv : bv - av;
      }
      return sortDir === 'asc'
        ? String(av).localeCompare(String(bv))
        : String(bv).localeCompare(String(av));
    });
    return copy;
  }, [filtered, sortKey, sortDir, sortFns]);

  const totalPages = Math.max(1, Math.ceil(sorted.length / pageSize));
  const safePage = Math.min(page, totalPages);

  const paginated = useMemo(() => {
    const start = (safePage - 1) * pageSize;
    return sorted.slice(start, start + pageSize);
  }, [sorted, safePage, pageSize]);

  const categoryOptions = useMemo(() => {
    if (!categoryFn) return [];
    const set = new Set(rows.map(categoryFn));
    return Array.from(set).filter(Boolean).sort();
  }, [rows, categoryFn]);

  const statusOptions = useMemo(() => {
    if (!statusFn) return [];
    const set = new Set(rows.map(statusFn));
    return Array.from(set).filter(Boolean).sort();
  }, [rows, statusFn]);

  function toggleSort(key: string) {
    if (sortKey === key) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'));
    } else {
      setSortKey(key);
      setSortDir('asc');
    }
    setPage(1);
  }

  function resetFilters() {
    setFilters({ search: '', category: 'all', status: 'all' });
    setPage(1);
  }

  function setSearch(search: string) {
    setFilters((f) => ({ ...f, search }));
    setPage(1);
  }

  function setCategory(category: string) {
    setFilters((f) => ({ ...f, category }));
    setPage(1);
  }

  function setStatus(status: string) {
    setFilters((f) => ({ ...f, status }));
    setPage(1);
  }

  const rangeStart = sorted.length === 0 ? 0 : (safePage - 1) * pageSize + 1;
  const rangeEnd = Math.min(safePage * pageSize, sorted.length);

  return {
    filters,
    paginated,
    sorted,
    totalPages,
    page: safePage,
    setPage,
    sortKey,
    sortDir,
    toggleSort,
    resetFilters,
    setSearch,
    setCategory,
    setStatus,
    categoryOptions,
    statusOptions,
    rangeStart,
    rangeEnd,
    totalCount: sorted.length,
  };
}
