import { createNflFeed } from '../src/nfl-feed.js';
const result = await createNflFeed({ apiKey: process.env.BALLDONTLIE_API_KEY ?? '' }).get();
// Never print credentials, environment contents, request headers, or raw upstream bodies.
if (!result.configured) {
  console.error('BALLDONTLIE_API_KEY is missing in server/.env.');
  process.exitCode = 1;
} else if (result.error) {
  console.error(result.error);
  process.exitCode = 1;
} else {
  console.log(`NFL connection verified: ${result.games.length} games in the schedule window.`);
  console.log(`Fetched: ${result.fetchedAt}. API key remains private.`);
}
