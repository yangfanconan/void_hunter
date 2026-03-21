/**
 * Void Hunter - Custom WebGL Loader
 * 自定义加载器：进度显示、错误处理、性能优化
 */

// ================================================================================
// 加载器配置
// ================================================================================

const LoaderConfig = {
    // 资源路径
    basePath: '',
    wasmFile: 'index.wasm',
    pckFile: 'index.pck',
    jsFile: 'index.js',

    // 超时设置（毫秒）
    timeout: 300000, // 5分钟

    // 重试设置
    maxRetries: 3,
    retryDelay: 1000,

    // 性能监控
    enablePerformanceMonitor: true,

    // 调试模式
    debug: new URLSearchParams(window.location.search).has('debug')
};

// ================================================================================
// 性能监控器
// ================================================================================

class PerformanceMonitor {
    constructor() {
        this.marks = new Map();
        this.measures = [];
    }

    mark(name) {
        this.marks.set(name, performance.now());
        if (LoaderConfig.debug) {
            console.log(`[Performance] Mark: ${name}`);
        }
    }

    measure(name, startMark, endMark) {
        const start = this.marks.get(startMark);
        const end = this.marks.get(endMark) || performance.now();

        if (start) {
            const duration = end - start;
            this.measures.push({ name, duration });
            if (LoaderConfig.debug) {
                console.log(`[Performance] ${name}: ${duration.toFixed(2)}ms`);
            }
            return duration;
        }
        return 0;
    }

    getReport() {
        return {
            measures: this.measures,
            totalTime: this.measures.reduce((sum, m) => sum + m.duration, 0)
        };
    }
}

const perfMonitor = new PerformanceMonitor();

// ================================================================================
// 资源加载器
// ================================================================================

class ResourceLoader {
    constructor(config = LoaderConfig) {
        this.config = config;
        this.cache = new Map();
        this.abortController = new AbortController();
    }

    /**
     * 加载文件
     */
    async loadFile(url, type = 'arraybuffer', onProgress = null) {
        const startTime = performance.now();
        let retries = 0;

        while (retries < this.config.maxRetries) {
            try {
                const response = await fetch(url, {
                    signal: this.abortController.signal,
                    cache: 'force-cache'
                });

                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }

                // 获取文件大小
                const contentLength = response.headers.get('content-length');
                const total = contentLength ? parseInt(contentLength, 10) : 0;

                // 流式读取以支持进度回调
                if (onProgress && total > 0) {
                    let loaded = 0;
                    const reader = response.body.getReader();
                    const chunks = [];

                    while (true) {
                        const { done, value } = await reader.read();
                        if (done) break;

                        chunks.push(value);
                        loaded += value.length;
                        onProgress(loaded, total);
                    }

                    // 合并数据块
                    const data = new Uint8Array(loaded);
                    let position = 0;
                    for (const chunk of chunks) {
                        data.set(chunk, position);
                        position += chunk.length;
                    }

                    const loadTime = performance.now() - startTime;
                    if (LoaderConfig.debug) {
                        console.log(`[Loader] Loaded ${url} in ${loadTime.toFixed(2)}ms`);
                    }

                    return type === 'arraybuffer' ? data.buffer : data;
                } else {
                    const data = await (type === 'arraybuffer'
                        ? response.arrayBuffer()
                        : response.text());

                    const loadTime = performance.now() - startTime;
                    if (LoaderConfig.debug) {
                        console.log(`[Loader] Loaded ${url} in ${loadTime.toFixed(2)}ms`);
                    }

                    return data;
                }
            } catch (error) {
                retries++;
                if (retries >= this.config.maxRetries) {
                    throw error;
                }
                console.warn(`[Loader] Retry ${retries}/${this.config.maxRetries} for ${url}`);
                await this.delay(this.config.retryDelay * retries);
            }
        }
    }

    /**
     * 加载WebAssembly模块
     */
    async loadWasm(url, onProgress = null) {
        perfMonitor.mark('wasm-load-start');

        const wasmBuffer = await this.loadFile(url, 'arraybuffer', onProgress);

        perfMonitor.mark('wasm-load-end');
        perfMonitor.measure('WASM Download', 'wasm-load-start', 'wasm-load-end');

        return wasmBuffer;
    }

    /**
     * 加载JavaScript脚本
     */
    async loadScript(url, onProgress = null) {
        perfMonitor.mark('js-load-start');

        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = url;
            script.type = 'text/javascript';
            script.async = true;

            script.onload = () => {
                perfMonitor.mark('js-load-end');
                perfMonitor.measure('JS Load & Parse', 'js-load-start', 'js-load-end');
                resolve();
            };

            script.onerror = () => {
                reject(new Error(`Failed to load script: ${url}`));
            };

            document.head.appendChild(script);
        });
    }

    /**
     * 延迟函数
     */
    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    /**
     * 取消所有加载
     */
    abort() {
        this.abortController.abort();
    }
}

// ================================================================================
// 进度管理器
// ================================================================================

class ProgressManager {
    constructor() {
        this.resources = new Map();
        this.totalSize = 0;
        this.loadedSize = 0;
        this.onUpdateCallback = null;
    }

    /**
     * 添加资源
     */
    addResource(name, size) {
        this.resources.set(name, { size, loaded: 0 });
        this.totalSize += size;
    }

    /**
     * 更新资源加载进度
     */
    updateProgress(name, loaded) {
        const resource = this.resources.get(name);
        if (resource) {
            const previousLoaded = resource.loaded;
            resource.loaded = loaded;
            this.loadedSize += (loaded - previousLoaded);
            this.notifyUpdate();
        }
    }

    /**
     * 完成资源加载
     */
    completeResource(name) {
        const resource = this.resources.get(name);
        if (resource) {
            resource.loaded = resource.size;
            this.notifyUpdate();
        }
    }

    /**
     * 获取总进度（0-1）
     */
    getProgress() {
        return this.totalSize > 0 ? this.loadedSize / this.totalSize : 0;
    }

    /**
     * 获取进度百分比
     */
    getPercentage() {
        return Math.round(this.getProgress() * 100);
    }

    /**
     * 设置更新回调
     */
    onUpdate(callback) {
        this.onUpdateCallback = callback;
    }

    /**
     * 通知更新
     */
    notifyUpdate() {
        if (this.onUpdateCallback) {
            this.onUpdateCallback(this.loadedSize, this.totalSize);
        }
    }

    /**
     * 重置
     */
    reset() {
        this.resources.clear();
        this.totalSize = 0;
        this.loadedSize = 0;
    }
}

// ================================================================================
// 缓存管理器
// ================================================================================

class CacheManager {
    constructor() {
        this.cacheName = 'void-hunter-cache-v1';
    }

    /**
     * 检查Service Worker缓存
     */
    async checkCache() {
        if ('caches' in window) {
            const cache = await caches.open(this.cacheName);
            return cache;
        }
        return null;
    }

    /**
     * 缓存资源
     */
    async cacheResource(url, response) {
        const cache = await this.checkCache();
        if (cache) {
            await cache.put(url, response);
        }
    }

    /**
     * 从缓存获取资源
     */
    async getCachedResource(url) {
        const cache = await this.checkCache();
        if (cache) {
            return await cache.match(url);
        }
        return null;
    }

    /**
     * 清除缓存
     */
    async clearCache() {
        if ('caches' in window) {
            await caches.delete(this.cacheName);
        }
    }
}

// ================================================================================
// 错误处理器
// ================================================================================

class ErrorHandler {
    constructor() {
        this.errors = [];
        this.maxErrors = 100;
    }

    /**
     * 记录错误
     */
    logError(error, context = '') {
        const errorInfo = {
            message: error.message || error,
            stack: error.stack,
            context,
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent
        };

        this.errors.push(errorInfo);

        if (this.errors.length > this.maxErrors) {
            this.errors.shift();
        }

        console.error(`[Error] ${context}:`, error);

        // 发送错误报告（可选）
        this.reportError(errorInfo);
    }

    /**
     * 显示错误界面
     */
    showError(title, message) {
        const errorScreen = document.getElementById('error-screen');
        const errorTitle = document.getElementById('error-title');
        const errorMessage = document.getElementById('error-message');

        if (errorScreen && errorTitle && errorMessage) {
            errorTitle.textContent = title;
            errorMessage.textContent = message;
            errorScreen.style.display = 'flex';
        }
    }

    /**
     * 发送错误报告
     */
    async reportError(errorInfo) {
        // 可以实现错误报告到服务器
        // 例如: await fetch('/api/error-report', { method: 'POST', body: JSON.stringify(errorInfo) });
    }

    /**
     * 获取错误报告
     */
    getErrorReport() {
        return this.errors;
    }
}

// ================================================================================
// 主加载器类
// ================================================================================

class GameLoader {
    constructor() {
        this.resourceLoader = new ResourceLoader();
        this.progressManager = new ProgressManager();
        this.cacheManager = new CacheManager();
        this.errorHandler = new ErrorHandler();

        this.isLoaded = false;
        this.isLoading = false;
    }

    /**
     * 初始化加载
     */
    async initialize() {
        perfMonitor.mark('init-start');

        try {
            // 设置进度回调
            this.progressManager.onUpdate((loaded, total) => {
                this.updateLoadingUI(loaded, total);
            });

            // 估算文件大小（实际大小需要服务器提供）
            this.progressManager.addResource('wasm', 20 * 1024 * 1024); // 20MB
            this.progressManager.addResource('js', 1 * 1024 * 1024);    // 1MB
            this.progressManager.addResource('pck', 25 * 1024 * 1024);  // 25MB

            perfMonitor.mark('init-end');
            perfMonitor.measure('Initialization', 'init-start', 'init-end');

            return true;
        } catch (error) {
            this.errorHandler.logError(error, 'Initialization');
            return false;
        }
    }

    /**
     * 加载游戏
     */
    async loadGame() {
        if (this.isLoading || this.isLoaded) return;

        this.isLoading = true;
        perfMonitor.mark('load-start');

        try {
            // 加载JavaScript引擎
            await this.loadEngine();

            // 加载WebAssembly模块
            await this.loadWasmModule();

            // 等待Godot引擎初始化
            await this.waitForEngine();

            this.isLoaded = true;
            perfMonitor.mark('load-end');
            perfMonitor.measure('Total Load Time', 'load-start', 'load-end');

            if (LoaderConfig.enablePerformanceMonitor) {
                const report = perfMonitor.getReport();
                console.log('[Performance Report]', report);
            }

            return true;
        } catch (error) {
            this.errorHandler.logError(error, 'Game Loading');
            this.errorHandler.showError(
                '加载失败',
                `游戏加载失败: ${error.message}\n请刷新页面重试。`
            );
            return false;
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * 加载引擎
     */
    async loadEngine() {
        perfMonitor.mark('engine-load-start');

        try {
            await this.resourceLoader.loadScript(
                LoaderConfig.basePath + LoaderConfig.jsFile
            );

            this.progressManager.completeResource('js');
            perfMonitor.mark('engine-load-end');
            perfMonitor.measure('Engine Load', 'engine-load-start', 'engine-load-end');
        } catch (error) {
            throw new Error(`Failed to load engine: ${error.message}`);
        }
    }

    /**
     * 加载WebAssembly模块
     */
    async loadWasmModule() {
        perfMonitor.mark('wasm-module-load-start');

        try {
            const wasmBuffer = await this.resourceLoader.loadWasm(
                LoaderConfig.basePath + LoaderConfig.wasmFile,
                (loaded, total) => {
                    this.progressManager.updateProgress('wasm', loaded);
                }
            );

            this.progressManager.completeResource('wasm');
            perfMonitor.mark('wasm-module-load-end');
            perfMonitor.measure('WASM Module Load', 'wasm-module-load-start', 'wasm-module-load-end');

            return wasmBuffer;
        } catch (error) {
            throw new Error(`Failed to load WASM: ${error.message}`);
        }
    }

    /**
     * 等待引擎就绪
     */
    async waitForEngine() {
        return new Promise((resolve, reject) => {
            const maxWait = LoaderConfig.timeout;
            const startTime = Date.now();

            const checkEngine = () => {
                if (typeof Engine !== 'undefined') {
                    resolve();
                } else if (Date.now() - startTime > maxWait) {
                    reject(new Error('Engine initialization timeout'));
                } else {
                    setTimeout(checkEngine, 100);
                }
            };

            checkEngine();
        });
    }

    /**
     * 更新加载UI
     */
    updateLoadingUI(loaded, total) {
        const progressBar = document.getElementById('progress-fill');
        const progressText = document.getElementById('progress-text');

        if (progressBar && progressText) {
            const percent = Math.round((loaded / total) * 100);
            progressBar.style.width = percent + '%';
            progressText.textContent = percent + '%';
        }
    }

    /**
     * 取消加载
     */
    cancel() {
        this.resourceLoader.abort();
        this.isLoading = false;
    }
}

// ================================================================================
// 全局初始化
// ================================================================================

// 创建全局加载器实例
const gameLoader = new GameLoader();

// 导出加载器
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        GameLoader,
        ResourceLoader,
        ProgressManager,
        CacheManager,
        ErrorHandler,
        PerformanceMonitor
    };
}

// 自动初始化
document.addEventListener('DOMContentLoaded', async () => {
    if (LoaderConfig.debug) {
        console.log('[Loader] DOM Content Loaded');
        console.log('[Loader] Configuration:', LoaderConfig);
    }

    const initialized = await gameLoader.initialize();
    if (initialized) {
        await gameLoader.loadGame();
    }
});

// 处理页面卸载
window.addEventListener('beforeunload', () => {
    gameLoader.cancel();
});

// 处理错误
window.addEventListener('error', (event) => {
    gameLoader.errorHandler.logError(event.error, 'Global Error');
});

window.addEventListener('unhandledrejection', (event) => {
    gameLoader.errorHandler.logError(event.reason, 'Unhandled Promise Rejection');
});
