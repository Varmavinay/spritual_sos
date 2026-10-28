// Choosing which quote to send.

/** Values the app may send as `source`: one holy book, or "all". */
export const BOOKS = ['all', 'bible', 'gita', 'quran'];

/**
 * A random quote from `book` ("bible", "gita", "quran"), or from all three
 * for "all" or anything unknown.
 */
export function pickQuote(quotes, book, random = Math.random) {
  const pool = quotes.filter((q) => q.book === book);
  const from = pool.length > 0 ? pool : quotes;
  return from[Math.floor(random() * from.length)];
}
