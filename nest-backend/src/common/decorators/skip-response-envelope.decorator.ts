import { SetMetadata } from '@nestjs/common';

export const SKIP_RESPONSE_ENVELOPE_KEY = 'skipResponseEnvelope';

/** Raw response (no `{ success, data }` wrapper) — use for webhooks that return provider-specific bodies. */
export const SkipResponseEnvelope = () => SetMetadata(SKIP_RESPONSE_ENVELOPE_KEY, true);
