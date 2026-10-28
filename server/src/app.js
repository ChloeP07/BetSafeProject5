import express from 'express';
import { createStore, snapshot, placePick, advanceDemo } from './store.js';

export function createApp({ store = createStore(), demoEnabled = true } = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(express.json({ limit: '16kb' }));
  app.get('/health', (_req, res) => res.json({ status: 'ok', service: 'betsafe', mode: 'simulation' }));
  app.get('/api/state', (_req, res) => res.json(snapshot(store)));
  app.post('/api/picks', (req, res) => {
    placePick(store, req.body);
    res.status(201).json(snapshot(store));
  });
  app.post('/api/demo/games/:id/advance', (req, res) => {
    if (!demoEnabled) return res.status(404).json({ error: 'Demo controls are disabled.' });
    advanceDemo(store, req.params.id);
    res.json(snapshot(store));
  });
  app.use((_req, res) => res.status(404).json({ error: 'Route not found.' }));
  app.use((error, _req, res, _next) => {
    const status = error.status ?? 500;
    res.status(status).json({ error: status >= 500 ? 'Server error. Please try again.' : error.message });
  });
  return app;
}
