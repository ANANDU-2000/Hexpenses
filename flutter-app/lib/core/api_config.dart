/// Local-only mode (no Nest, no login): run with
/// `flutter run -d chrome --dart-define=NO_API=true` (or `DEV_OFFLINE_UI=true`).
///
/// Compile-time API root (override with `--dart-define=API_BASE=http://host:port/api`).
/// Default uses 127.0.0.1 — on Windows/browser this is often more reliable than `localhost`.
/// On **web**, [web/index.html] also sets `window.MONEYFLOW_API_BASE` (runtime, no rebuild).
const kApiBase = String.fromEnvironment(
  'API_BASE',
  defaultValue: 'http://127.0.0.1:4000/api',
);

/// Skip login and open the main shell (for UI / layout work only). Data calls will fail without a backend.
const kDevOfflineUi = bool.fromEnvironment('DEV_OFFLINE_UI', defaultValue: false);

/// Full local-only mode: no Nest server, no login. Dashboard/expenses use Drift + bundled demo categories & a seed account.
const kNoApiFromEnv = bool.fromEnvironment('NO_API', defaultValue: false);

bool get kNoApiMode => kNoApiFromEnv || kDevOfflineUi;
