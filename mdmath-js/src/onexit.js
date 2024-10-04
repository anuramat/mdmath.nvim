const callbacks = [];

function run() {
    callbacks.forEach(callback => callback());
}

process.on('exit', (code) => {
    run();
});

['SIGINT', 'SIGTERM', 'SIGHUP'].forEach((signal) => {
    process.on(signal, (_, code) => {
        // Handle as a normal exit
        process.exit(128 + code);
    });
});

export function onExit(callback) {
    callbacks.push(callback);
}
