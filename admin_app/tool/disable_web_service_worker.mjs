import { readFile, rm, writeFile } from 'node:fs/promises';

const bootstrapPath = new URL('../build/web/flutter_bootstrap.js', import.meta.url);
const serviceWorkerPath = new URL('../build/web/flutter_service_worker.js', import.meta.url);

let bootstrap = await readFile(bootstrapPath, 'utf8');
bootstrap = bootstrap.replace(
  /_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*"[^"]*"\s*\/\*[\s\S]*?\*\/\s*\}\s*\}\);/,
  '_flutter.loader.load();',
);

await writeFile(bootstrapPath, bootstrap);
await rm(serviceWorkerPath, { force: true });
