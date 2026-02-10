enum FetchPolicy {
  // Cache Only: Only fetch from the cache, never from the network.
  cacheOnly,

  // Network Only: Only fetch from the network, never from the cache.
  networkOnly,

  // Cache First: Try to fetch from the cache first, if not available, then fetch from the network.
  cacheFirst,

  // Network First: Try to fetch from the network first, if it fails, then fetch from the cache.
  networkFirst,

  // Stale While Revalidate: Return cached data immediately, then fetch from the network and update the cache.
  staleWhileRevalidate,
}
