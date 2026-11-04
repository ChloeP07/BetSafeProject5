import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const workflows = {
  setup: [
    ['flutter', ['pub', 'get']],
    ['npm', ['--prefix', 'server', 'ci']],
  ],
  check: [
    ['flutter', ['analyze']],
    ['flutter', ['test']],
    ['npm', ['--prefix', 'server', 'test']],
  ],
};
const steps = workflows[process.argv[2]];
if (!steps) {
  console.error('Use npm run setup or npm run check from the repository root.');
  process.exit(1);
}
for (const [command, args] of steps) {
  console.log(`\n> ${command} ${args.join(' ')}`);
  const result = spawnSync(command, args, {
    cwd: root, stdio: 'inherit', shell: process.platform === 'win32',
  });
  if (result.error) {
    console.error(`Could not run ${command}. Install it and make sure it is on your PATH.`);
    process.exit(1);
  }
  if (result.status !== 0) process.exit(result.status ?? 1);
}
console.log('\nAll steps completed.');
