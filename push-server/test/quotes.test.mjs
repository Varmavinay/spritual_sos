import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import { pickQuote } from '../src/quotes.js';

const quotes = JSON.parse(readFileSync(new URL('../src/quotes.json', import.meta.url), 'utf8'));

test('quotes come from the chosen holy book', () => {
  for (const book of ['bible', 'gita', 'quran']) {
    for (let i = 0; i < 50; i++) assert.equal(pickQuote(quotes, book).book, book);
  }
});

test('"all" and unknown values choose from every book', () => {
  const books = new Set();
  for (let i = 0; i < 60; i++) books.add(pickQuote(quotes, 'all', () => i / 60).book);
  assert.deepEqual([...books].sort(), ['bible', 'gita', 'quran']);
  assert.ok(pickQuote(quotes, 'unknown'));
});
