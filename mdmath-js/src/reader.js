import { exec } from 'node:child_process';
import { makeAsyncStream } from './async_stream.js';

function sendNotification(message) {
    exec(`notify-send '${message}'`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error.message}`);
        }
        if (stderr) {
            console.error(`Stderr: ${stderr}`);
        }
    });
}

// FIXME: This should not be a fatal error, instead send a response
// to the client with the error message.
function response_fail(message) {
    console.error(`Error: ${message}`);
    process.exit(1);
}

const reader = {}

reader.listen = function(callback) {
    const stream = makeAsyncStream(process.stdin, ':');

    async function loop() {
        while (await stream.waitReadable()) {
            const identifier = await stream.readString();
            const type = await stream.readString();
            if (type == 'request') {
                const width = await stream.readInt();
                const height = await stream.readInt();

                // TODO: Flags should be a enum
                const flags = await stream.readInt();

                const length = await stream.readInt();
                const data = await stream.readFixedString(length);

                const response = {
                    identifier,
                    type,
                    width,
                    height,
                    flags,
                    data
                };
                callback(response);
            } else if(type == 'fgcolor') {
                const color = (await stream.readString()).toLowerCase();
                if (!color.match(/^#[0-9a-f]{6}$/))
                    response_fail(`Invalid color: ${color}`);

                const response = {
                    identifier,
                    type,
                    color
                };
                callback(response);
            } else if(type == 'scale') {
                const scale = await stream.readFloat();

                const response = {
                    identifier,
                    type,
                    scale
                };
                callback(response);
            } else {
                response_fail(`Identifier ${identifier}: Invalid request type: ${type}`);
            }
        }
    }

    loop();
}

export default reader;
