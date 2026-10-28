import assert from 'node:assert/strict';
import { test } from 'node:test';

import { isValidTimeZone, nextSendAt } from '../src/time.js';

const iso = (ms) => new Date(ms).toISOString();

test('later today when the time has not passed yet', () => {
  // 07:00 in Sydney (AEST, UTC+10) on 2026-07-15.
  const now = Date.parse('2026-07-14T21:00:00Z');
  assert.equal(iso(nextSendAt(8, 0, 'Australia/Sydney', now)), '2026-07-14T22:00:00.000Z');
});

test('tomorrow when the time has already passed (no instant notification)', () => {
  // 09:00 in Sydney; an 08:00 reminder is due tomorrow, not now.
  const now = Date.parse('2026-07-14T23:00:00Z');
  assert.equal(iso(nextSendAt(8, 0, 'Australia/Sydney', now)), '2026-07-15T22:00:00.000Z');
});

test('exactly at the reminder minute schedules the next day', () => {
  const now = Date.parse('2026-07-14T22:00:00Z');
  assert.equal(iso(nextSendAt(8, 0, 'Australia/Sydney', now)), '2026-07-15T22:00:00.000Z');
});

test('follows daylight saving (Sydney moves to UTC+11 on 2026-10-04)', () => {
  const now = Date.parse('2026-10-03T23:00:00Z'); // 09:00 AEST on Oct 4 (already AEDT)
  // 08:00 AEDT on Oct 5 is 21:00 UTC on Oct 4.
  assert.equal(iso(nextSendAt(8, 0, 'Australia/Sydney', now)), '2026-10-04T21:00:00.000Z');
});

test('half-hour time zones and minutes', () => {
  const now = Date.parse('2026-01-01T00:00:00Z'); // 05:30 in Kolkata
  assert.equal(iso(nextSendAt(6, 45, 'Asia/Kolkata', now)), '2026-01-01T01:15:00.000Z');
});

test('time zone validation', () => {
  assert.ok(isValidTimeZone('America/New_York'));
  assert.ok(!isValidTimeZone('Not/AZone'));
});
