// History of the daily messages shown on this browser, kept in IndexedDB.
// Loaded by both the service worker (push_sw.js), which adds a record for
// every notification, and the page (index.html), where the app reads them.
(() => {
  const DB = 'spiritual-sos';
  const STORE = 'deliveries';
  const MAX = 365;

  function open() {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB, 1);
      request.onupgradeneeded = () => request.result.createObjectStore(STORE, { keyPath: 'at' });
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  function done(tx) {
    return new Promise((resolve, reject) => {
      tx.oncomplete = () => resolve();
      tx.onerror = tx.onabort = () => reject(tx.error);
    });
  }

  async function list() {
    const db = await open();
    try {
      const request = db.transaction(STORE).objectStore(STORE).getAll();
      return await new Promise((resolve, reject) => {
        request.onsuccess = () => resolve(request.result);
        request.onerror = () => reject(request.error);
      });
    } finally {
      db.close();
    }
  }

  self.sosHistory = {
    /** Records that quote `id` was shown now. */
    async add(id) {
      const db = await open();
      try {
        const tx = db.transaction(STORE, 'readwrite');
        const store = tx.objectStore(STORE);
        store.put({ id, at: Date.now() });
        // Keep the newest MAX records.
        const keys = store.getAllKeys();
        keys.onsuccess = () => keys.result.slice(0, Math.max(0, keys.result.length - MAX))
          .forEach((key) => store.delete(key));
        await done(tx);
      } finally {
        db.close();
      }
    },
    /** All records as JSON: [{ id, at }], oldest first. */
    async listJson() {
      return JSON.stringify(await list());
    },
  };
})();
