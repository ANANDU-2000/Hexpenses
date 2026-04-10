import { Logger } from '@nestjs/common';
import axios from 'axios';

const log = new Logger('WhatsappExpenseParser');

export type ParsedExpenseLine = { label: string; amount: number; raw: string };

/**
 * Rule-based expense line parsing: "Fuel 500", currency prefixes, amount-first, "rent: 12000".
 */
export function parseExpenseLineRuleBased(line: string): ParsedExpenseLine | null {
  const raw = line.trim();
  if (!raw) return null;

  let s = raw.replace(/\s+/g, ' ');
  s = s.replace(/^[\u20b9\u00a3$€rs\.\s,]+/i, '').trim();
  s = s.replace(/[\u20b9\u00a3$€]/g, '').trim();

  let m = s.match(/^(.+?)[\s:\-–—,]+(\d+(?:[.,]\d{1,2})?)\s*$/);
  if (m) {
    const label = m[1].trim().replace(/[:,\-–—]+$/, '').trim();
    const amount = parseAmount(m[2]);
    if (label && amount !== null) return { label, amount, raw };
  }

  m = s.match(/^(\d+(?:[.,]\d{1,2})?)\s+(.+)$/);
  if (m) {
    const amount = parseAmount(m[1]);
    const label = m[2].trim();
    if (label && amount !== null) return { label, amount, raw };
  }

  return null;
}

function parseAmount(part: string): number | null {
  const n = Number(part.replace(',', '.'));
  if (Number.isNaN(n) || n <= 0) return null;
  return Math.round(n * 100) / 100;
}

/** Optional OpenAI JSON extraction when rules fail. */
export async function parseExpenseLineWithOpenAI(
  line: string,
  apiKey: string | undefined,
  model: string,
  categoryHints: string[],
): Promise<ParsedExpenseLine | null> {
  if (!apiKey?.trim()) return null;
  const hints =
    categoryHints.length > 0
      ? `User category names (prefer one): ${categoryHints.slice(0, 40).join(', ')}.`
      : '';
  try {
    const res = await axios.post(
      'https://api.openai.com/v1/chat/completions',
      {
        model,
        response_format: { type: 'json_object' },
        messages: [
          {
            role: 'system',
            content:
              'Extract an expense from a short WhatsApp message. Reply JSON only: {"label":string,"amount":number} or {"label":null,"amount":null} if not an expense.',
          },
          {
            role: 'user',
            content: `${hints}\nMessage: ${JSON.stringify(line)}`,
          },
        ],
        temperature: 0.1,
        max_tokens: 120,
      },
      {
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
        timeout: 12_000,
      },
    );
    const text = res.data?.choices?.[0]?.message?.content;
    if (!text || typeof text !== 'string') return null;
    const parsed = JSON.parse(text) as { label?: string | null; amount?: number | null };
    if (
      parsed.label == null ||
      parsed.amount == null ||
      typeof parsed.amount !== 'number' ||
      parsed.amount <= 0
    ) {
      return null;
    }
    return { label: String(parsed.label).trim(), amount: parsed.amount, raw: line.trim() };
  } catch (e) {
    log.warn(`OpenAI expense parse failed: ${(e as Error).message}`);
    return null;
  }
}
