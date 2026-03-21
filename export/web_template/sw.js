/**
 * Void Hunter - Service Worker
 * 用于PWA离线支持和缓存管理
 */

const CACHE_NAME = 'void-hunter-v1';
const RUNTIME_CACHE = 'void-hunter-runtime-v1';

// 需要预缓存的静态资源
const PRECACHE_URLS = [
    '/',
    '/index.html',
    '/style.css',
    '/loader.js',
    '/manifest.json',
    '/index.js',
    '/index.wasm',
    '/index.pck'
];

// 安装事件 - 预缓存关键资源
self.addEventListener('install', event => {
    console.log('[ServiceWorker] Install');

    event.waitUntil(
        caches.open(CACHE_NAME)
            .then(cache => {
                console.log('[ServiceWorker] Pre-caching assets');
                // 逐个缓存，避免单个失败导致全部失败
                return Promise.all(
                    PRECACHE_URLS.map(url => {
                        return cache.add(url).catch(err => {
                            console.warn(`[ServiceWorker] Failed to cache: ${url}`, err);
                        });
                    })
                );
            })
            .then(() => {
                console.log('[ServiceWorker] Skip waiting');
                return self.skipWaiting();
            })
    );
});

// 激活事件 - 清理旧缓存
self.addEventListener('activate', event => {
    console.log('[ServiceWorker] Activate');

    event.waitUntil(
        caches.keys().then(cacheNames => {
            return Promise.all(
                cacheNames
                    .filter(cacheName => {
                        return cacheName.startsWith('void-hunter-') &&
                               cacheName !== CACHE_NAME &&
                               cacheName !== RUNTIME_CACHE;
                    })
                    .map(cacheName => {
                        console.log('[ServiceWorker] Deleting old cache:', cacheName);
                        return caches.delete(cacheName);
                    })
            );
        }).then(() => {
            console.log('[ServiceWorker] Claiming clients');
            return self.clients.claim();
        })
    );
});

// 请求拦截 - 缓存策略
self.addEventListener('fetch', event => {
    const { request } = event;
    const url = new URL(request.url);

    // 只处理同源请求
    if (url.origin !== location.origin) {
        return;
    }

    // 对于WASM和PCK文件，使用缓存优先策略
    if (request.url.match(/\.(wasm|pck)$/)) {
        event.respondWith(cacheFirst(request));
        return;
    }

    // 对于HTML和JS文件，使用网络优先策略
    if (request.url.match(/\.(html|js)$/)) {
        event.respondWith(networkFirst(request));
        return;
    }

    // 对于其他资源，使用stale-while-revalidate策略
    event.respondWith(staleWhileRevalidate(request));
});

/**
 * 缓存优先策略
 * 适用于：不常变化的资源（WASM, PCK）
 */
async function cacheFirst(request) {
    const cachedResponse = await caches.match(request);

    if (cachedResponse) {
        console.log('[ServiceWorker] Cache hit:', request.url);
        return cachedResponse;
    }

    console.log('[ServiceWorker] Cache miss, fetching:', request.url);

    try {
        const networkResponse = await fetch(request);

        if (networkResponse.ok) {
            const cache = await caches.open(CACHE_NAME);
            cache.put(request, networkResponse.clone());
        }

        return networkResponse;
    } catch (error) {
        console.error('[ServiceWorker] Fetch failed:', error);

        // 返回离线页面或错误响应
        return new Response('Network error', {
            status: 408,
            headers: { 'Content-Type': 'text/plain' }
        });
    }
}

/**
 * 网络优先策略
 * 适用于：需要更新的资源（HTML, JS）
 */
async function networkFirst(request) {
    try {
        const networkResponse = await fetch(request);

        if (networkResponse.ok) {
            const cache = await caches.open(RUNTIME_CACHE);
            cache.put(request, networkResponse.clone());
        }

        return networkResponse;
    } catch (error) {
        console.log('[ServiceWorker] Network failed, trying cache:', request.url);

        const cachedResponse = await caches.match(request);

        if (cachedResponse) {
            return cachedResponse;
        }

        // 返回离线页面
        if (request.headers.get('accept').includes('text/html')) {
            return caches.match('/index.html');
        }

        return new Response('Network error', {
            status: 408,
            headers: { 'Content-Type': 'text/plain' }
        });
    }
}

/**
 * Stale-while-revalidate策略
 * 适用于：可以立即返回但需要更新的资源
 */
async function staleWhileRevalidate(request) {
    const cachedResponse = await caches.match(request);

    const fetchPromise = fetch(request).then(networkResponse => {
        if (networkResponse.ok) {
            const cache = caches.open(RUNTIME_CACHE);
            cache.then(c => c.put(request, networkResponse.clone()));
        }
        return networkResponse;
    }).catch(error => {
        console.log('[ServiceWorker] Background fetch failed:', error);
    });

    return cachedResponse || fetchPromise;
}

// 消息处理
self.addEventListener('message', event => {
    if (event.data && event.data.type === 'SKIP_WAITING') {
        self.skipWaiting();
    }

    if (event.data && event.data.type === 'CLEAR_CACHE') {
        event.waitUntil(
            caches.keys().then(cacheNames => {
                return Promise.all(
                    cacheNames.map(cacheName => caches.delete(cacheName))
                );
            }).then(() => {
                event.ports[0].postMessage({ success: true });
            })
        );
    }
});

// 后台同步（可选）
self.addEventListener('sync', event => {
    if (event.tag === 'sync-game-data') {
        console.log('[ServiceWorker] Syncing game data');
        // event.waitUntil(syncGameData());
    }
});

// 推送通知（可选）
self.addEventListener('push', event => {
    if (event.data) {
        const data = event.data.json();

        const options = {
            body: data.body || 'New notification from Void Hunter',
            icon: '/icon-192.png',
            badge: '/icon-192.png',
            vibrate: [100, 50, 100],
            data: {
                url: data.url || '/'
            }
        };

        event.waitUntil(
            self.registration.showNotification(data.title || 'Void Hunter', options)
        );
    }
});

// 通知点击处理
self.addEventListener('notificationclick', event => {
    event.notification.close();

    event.waitUntil(
        clients.matchAll({ type: 'window' }).then(clientList => {
            // 如果已有窗口，聚焦它
            for (const client of clientList) {
                if (client.url === event.notification.data.url && 'focus' in client) {
                    return client.focus();
                }
            }

            // 否则打开新窗口
            if (clients.openWindow) {
                return clients.openWindow(event.notification.data.url);
            }
        })
    );
});

console.log('[ServiceWorker] Script loaded');
