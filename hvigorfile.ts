import { appTasks } from '@ohos/hvigor-ohos-plugin';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Normalize SDK home to DevEco SDK root directory.
 * Accepts values like:
 *   - /Applications/DevEco-Studio.app/Contents/sdk
 *   - /Applications/DevEco-Studio.app/Contents/sdk/default/hms
 *   - /Applications/DevEco-Studio.app/Contents/sdk/default/openharmony
 * and always returns .../Contents/sdk
 */
function normalizeSdkRoot(input?: string): string | undefined {
  if (!input) return undefined;
  const cleaned = input.trim();
  if (!cleaned) return undefined;
  const sdkAnchor = `${path.sep}Contents${path.sep}sdk`;
  const idx = cleaned.indexOf(sdkAnchor);
  if (idx < 0) return cleaned; // not a DevEco path; return as-is
  // keep up to sdkAnchor
  return cleaned.substring(0, idx + sdkAnchor.length);
}

function readLocalProperties(): Record<string, string> {
  const propsPath = path.resolve(__dirname, 'local.properties');
  if (!fs.existsSync(propsPath)) return {};
  const content = fs.readFileSync(propsPath, 'utf-8');
  const result: Record<string, string> = {};
  content.split(/\r?\n/).forEach((line) => {
    const l = line.trim();
    if (!l || l.startsWith('#')) return;
    const eq = l.indexOf('=');
    if (eq <= 0) return;
    const k = l.substring(0, eq).trim();
    const v = l.substring(eq + 1).trim();
    if (k && v) result[k] = v;
  });
  return result;
}

// Ensure hvigor always receives correct SDK root
(() => {
  try {
    const props = readLocalProperties();
    const candidates = [
      process.env.DEVECO_SDK_HOME,
      process.env.OHOS_BASE_SDK_HOME,
      process.env.ARKUIX_SDK_HOME,
      props['hwsdk.dir'],
      props['sdk.dir'],
      props['arkui-x.dir'],
    ];
    // pick first defined and normalize
    const first = candidates.find((p) => !!p);
    const normalized = normalizeSdkRoot(first);
    const fallback = '/Applications/DevEco-Studio.app/Contents/sdk';
    const finalHome = normalized || fallback;

    // Only set when empty or invalid
    const setIfInvalid = (key: string) => {
      const cur = process.env[key];
      const normCur = normalizeSdkRoot(cur);
      if (!normCur) {
        process.env[key] = finalHome;
        return;
      }
      // if it points beyond sdk (e.g., .../default/hms), replace with root
      if (normCur !== cur) {
        process.env[key] = normCur;
      }
    };

    setIfInvalid('DEVECO_SDK_HOME');
    setIfInvalid('OHOS_BASE_SDK_HOME');
    setIfInvalid('ARKUIX_SDK_HOME');
  } catch (e) {
    // silent; fallback to hvigor defaults
  }
})();

export default {
  system: appTasks,
  plugins: []
}
