import { spawn, exec } from 'node:child_process';
import { stat } from 'node:fs';

/**
 * Checks if a file exists.
 * 
 * @param {string} filename - The name of the file to check.
 * @returns {Promise<boolean>} A promise that resolves to true if the file exists, false otherwise.
 */
export const fileExists = (filename) => new Promise((resolve, reject) => {
    stat(filename, (err, stats) => {
        if (err)
            return resolve(false);

        resolve(stats.isFile());
    });
});

const magickBinary = new Promise(async (resolve) => {
    const paths = process.env.PATH.split(':');

    // ImageMagick v7
    for (const path of paths) {
        const magick = `${path}/magick`;
        if (await fileExists(magick)) {
            return resolve({
                convert: magick,
                identify: magick,
                isV7: true
            })
        }
    }

    // ImageMagick v6
    let convertPath = null;
    for (const path of paths) {
        if (await fileExists(`${path}/convert`)) {
            convertPath = path;
            break;
        }
    }
    if (convertPath === null) {
        console.error('Failed to find ImageMagick v6/v7');
        process.exit(1);
    }

    const convert = `${convertPath}/convert`;
    let identify = `${convertPath}/identify`;

    // Most of the time, the convert and identify binaries are in the same directory. So we will first
    // try to find `identify` in the same directory as `convert`. If that fails, we will try to find
    // another path that contains `identify`.
    if (!await fileExists(identify)) {
        identify = null;
        for (const path of paths) {
            if (await fileExists(`${path}/identify`)) {
                identify = `${path}/identify`;
                break;
            }
        }
        if (identify === null) {
            console.error('Failed to find ImageMagick v6/v7 (found convert, but not identify)');
            process.exit(1);
        }
    }

    return resolve({
        convert,
        identify,
        isV7: false
    });
});

export async function svgDimensions(svg, {density} = {}) {
    const magick = await magickBinary;

    const args = ['-ping'];
    if (density)
        args.push('-density', density);
    args.push('-format', '%w %h');
    args.push('svg:-');
    if (magick.isV7)
        args.unshift('identify');

    return new Promise((resolve, reject) => {
        const identify = spawn(magick.identify, args);
        let data = '';
        identify.stdout.on('data', (chunk) => data += chunk);
        identify.on('exit', (code) => {
            // TODO: improve error handling
            if (code !== 0)
                return reject(new Error(`identify exited with code ${code}`));

            const [width, height] = data.trim().split(' ').map(Number);
            resolve({width, height});
        });
        identify.stdin.write(svg);
        identify.stdin.end();
    });
}

/**
 * Converts an SVG string to a PNG file with an optional size.
 *
 * @param {string} svg - The SVG string to be converted.
 * @param {string} filename - The output PNG filename.
 * @param {number} width - The width of the output PNG image. (0 for dynamic)
 * @param {number} height - The height of the output PNG image.
 * @param {Object} flags - Settings for the conversion.
 * @param {boolean} flags.resize - Whether to resize the image.
 * @param {boolean} flags.center - Whether to center the image.
 * @param {number?} flags.density - The density of the image.
 * @returns {Promise<{width: number, height: number}>} - The width and height of the output PNG image.
 */
export async function svg2png(svg, filename, width, height, flags) {
    const size = `${width}x${height}`;

    const args = ['-background', 'none'];
    if (flags.resize)
        args.push('-size', flags.size);
    if (flags.density)
        args.push('-density', flags.density);
    args.push('svg:-');
    if (flags.center)
        args.push('-gravity', 'Center');
    else
        args.push('-gravity', 'West');
    args.push('-extent', size);
    args.push(`png:${filename}`);

    const magick = await magickBinary;
    return new Promise((resolve, reject) => {
        const convert = spawn(magick.convert, args);
        convert.on('exit', (code) => {
            // TODO: improve error handling
            if (code !== 0)
                return reject(new Error(`convert exited with code ${code}`));

            resolve({width, height});
        });
        convert.stdin.write(svg);
        convert.stdin.end();
    });
}
