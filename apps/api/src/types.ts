import type { D1Database, DurableObjectNamespace } from '@cloudflare/workers-types';

declare module 'hono' {
  interface ContextVariableMap {
    'db': D1Database;
    'sessionsDO': DurableObjectNamespace;
  }
}

export type AppBindings = {
  DB: D1Database;
  COURSES_DB: D1Database;
  TRANSFERS_DB: D1Database;
  SESSIONS: DurableObjectNamespace;
  BYOK_KEK: string;
  ENV: string;
};

export type AppContext = {
  get<K extends keyof AppBindings>(key: K): AppBindings[K];
  set(key: keyof AppBindings, value: unknown): void;
  var: Record<string, unknown>;
};
