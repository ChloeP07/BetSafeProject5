import { spawn, spawnSync } from 'node:child_process';
import { existsSync, readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { parseEnv } from 'node:util';

const root = fileURLToPath(new URL('../', import.meta.url));
const serverRoot = fileURLToPath(new URL('../server/', import.meta.url));
const requested = process.argv[2];
if (requested === '--help') {
  console.log('Usage: npm run android -- [android-device-id]');
  console.log('Start an Android Studio emulator first. The launcher reuses a healthy BetSafe server or starts one locally.');
  process.exit(0);
}

const windows = process.platform === 'win32';
const devicesResult = spawnSync('flutter', ['devices', '--machine'], {
  cwd: root, encoding: 'utf8', shell: windows, timeout: 30_000,
});
if (devicesResult.error || devicesResult.status !== 0) {
  console.error('Could not list Flutter devices. Check flutter doctor and that Flutter is on your PATH.');
  process.exit(1);
}
let devices;
try {
  devices = JSON.parse(devicesResult.stdout).filter((device) => device.isSupported && device.targetPlatform?.startsWith('android'));
} catch {
  console.error('Flutter did not return a readable device list. Run flutter devices manually.');
  process.exit(1);
}
const device = requested ? devices.find((item) => item.id === requested) : devices.length === 1 ? devices[0] : null;
if (!device) {
  console.error(devices.length === 0
    ? 'No Android device is running. Start one in Android Studio → Device Manager, then retry.'
    : 'Choose an Android device: npm run android -- <device-id>');
  for (const item of devices) console.log(`${item.id}: ${item.name}`);
  process.exit(1);
}

const envPath = `${serverRoot}.env`;
const localConfig = existsSync(envPath) ? parseEnv(readFileSync(envPath, 'utf8')) : {};
const port = process.env.PORT ?? localConfig.PORT ?? '3000';
if (!/^\d+$/.test(port) || Number(port) < 1 || Number(port) > 65535) {
  console.error('Set PORT to a valid number in server/.env.');
  process.exit(1);
}
const address = `http://127.0.0.1:${port}`;
async function health() {
  try {
    const response = await fetch(`${address}/health`, { signal: AbortSignal.timeout(800) });
    const result = await response.json();
    return response.ok && result.service === 'betsafe' && result.status === 'ok';
  } catch { return false; }
}
let server;
let flutter;
let stopping = false;
function stop(code) {
  if (stopping) return;
  stopping = true;
  flutter?.kill('SIGTERM');
  server?.kill('SIGTERM');
  process.exitCode = code;
}
process.on('SIGINT', () => stop(130));
process.on('SIGTERM', () => stop(143));
if (await health()) {
  console.log(`Using existing BetSafe server at ${address}. It will stay running when Flutter closes.`);
} else {
  console.log(`Starting BetSafe server at ${address}…`);
  server = spawn(process.execPath, ['--env-file-if-exists=.env', 'src/index.js'], { cwd: serverRoot, stdio: 'inherit' });
  server.on('error', () => { console.error('Could not start the Node server.'); stop(1); });
  let ready = false;
  for (let attempt = 0; attempt < 30 && !stopping; attempt++) {
    if (await health()) { ready = true; break; }
    if (server.exitCode !== null) break;
    await new Promise((resolve) => setTimeout(resolve, 300));
  }
  if (!ready) {
    console.error('The server did not start. Check the port and run npm run server for details.');
    stop(1);
  }
}
if (!stopping) {
  // Android emulator uses 10.0.2.2 to reach the host. For phones, use the documented LAN address.
  const emulator = device.emulator === true;
  const args = ['run', '-d', device.id];
  if (emulator) args.push(`--dart-define=API_BASE_URL=http://10.0.2.2:${port}`);
  else if (!process.env.API_BASE_URL) {
    console.error('For a physical phone, set API_BASE_URL to your Mac/PC LAN server address and HOST=0.0.0.0 in server/.env.');
    stop(1);
  } else args.push(`--dart-define=API_BASE_URL=${process.env.API_BASE_URL}`);
  if (!stopping) {
    console.log(`Launching BetSafe on ${device.name}. Press q to stop Flutter.`);
    flutter = spawn('flutter', args, { cwd: root, stdio: 'inherit', shell: windows });
    flutter.on('error', () => { console.error('Could not start Flutter.'); stop(1); });
    flutter.on('exit', (code) => stop(code ?? 1));
  }
}
