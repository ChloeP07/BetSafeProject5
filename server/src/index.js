import { createApp } from './app.js';
import { createNflFeed } from './nfl-feed.js';
const port = Number(process.env.PORT || 3000);
const host = process.env.HOST || '127.0.0.1';
const app = createApp({ demoEnabled: process.env.DEMO_CONTROLS !== 'false',
  nflFeed: createNflFeed({ apiKey: process.env.BALLDONTLIE_API_KEY ?? '' }) });
app.listen(port, host, () => console.log(`BetSafe server: http://${host}:${port}`));
