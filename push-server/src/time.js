// Time-zone helpers built on Intl, so reminders follow each user's local
// clock (including daylight-saving changes).

export function isValidTimeZone(timeZone) {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone });
    return true;
  } catch {
    return false;
  }
}

/** Wall-clock parts of the instant `ms` in `timeZone`. */
function wallClock(ms, timeZone) {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: 'numeric',
    minute: 'numeric',
    second: 'numeric',
  }).formatToParts(new Date(ms));
  const get = (type) => Number(parts.find((p) => p.type === type).value);
  return {
    year: get('year'),
    month: get('month'),
    day: get('day'),
    hour: get('hour'),
    minute: get('minute'),
    second: get('second'),
  };
}

/** Offset (ms) of `timeZone` from UTC at the instant `ms`. */
function offsetAt(ms, timeZone) {
  const w = wallClock(ms, timeZone);
  const asUtc = Date.UTC(w.year, w.month - 1, w.day, w.hour, w.minute, w.second);
  return asUtc - Math.floor(ms / 1000) * 1000;
}

/** UTC instant for a wall-clock time in `timeZone`. */
export function zonedTimeToUtc(year, month, day, hour, minute, timeZone) {
  const guess = Date.UTC(year, month - 1, day, hour, minute);
  let result = guess - offsetAt(guess, timeZone);
  // Re-check once: the offset can differ on either side of a DST change.
  const corrected = guess - offsetAt(result, timeZone);
  if (corrected !== result) result = corrected;
  return result;
}

/** Next instant strictly after `nowMs` when it is hour:minute in `timeZone`. */
export function nextSendAt(hour, minute, timeZone, nowMs) {
  const today = wallClock(nowMs, timeZone);
  for (let addDays = 0; addDays < 3; addDays++) {
    const date = new Date(Date.UTC(today.year, today.month - 1, today.day + addDays));
    const candidate = zonedTimeToUtc(
      date.getUTCFullYear(),
      date.getUTCMonth() + 1,
      date.getUTCDate(),
      hour,
      minute,
      timeZone,
    );
    if (candidate > nowMs) return candidate;
  }
  throw new Error('Could not compute next send time');
}
