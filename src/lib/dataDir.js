import fs from "node:fs";
import path from "path";
import os from "os";

const APP_NAME = "9router";

function defaultDir() {
  if (process.platform === "win32") {
    return path.join(process.env.APPDATA || path.join(os.homedir(), "AppData", "Roaming"), APP_NAME);
  }
  return path.join(os.homedir(), `.${APP_NAME}`);
}

export function getDataDir() {
  // When in Docker, always use the container-internal data path.
  // This prevents host DATA_DIR env from leaking in and causing permission errors.
  if (fs.existsSync("/.dockerenv")) {
    const dockerDir = "/app/data";
    try {
      fs.mkdirSync(dockerDir, { recursive: true });
      return dockerDir;
    } catch (e) {
      console.error(`[DATA_DIR] Failed to create Docker data directory at ${dockerDir}:`, e);
      // Fallback to default in case of weird permissions, though it's unlikely to work.
      return defaultDir();
    }
  }

  const configured = process.env.DATA_DIR;
  if (!configured) return defaultDir();
  try {
    fs.mkdirSync(configured, { recursive: true });
    return configured;
  } catch (e) {
    if (e?.code === "EACCES" || e?.code === "EPERM") {
      console.warn(`[DATA_DIR] '${configured}' not writable → fallback ~/.${APP_NAME}`);
      return defaultDir();
    }
    throw e;
  }
}

export const DATA_DIR = getDataDir();
