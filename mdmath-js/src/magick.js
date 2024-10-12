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

const convertBinary = new Promise(async (resolve) => {
    const paths = process.env.PATH.split(':');

    // ImageMagick v7
    for (const path of paths) {
        const magick = `${path}/magick`;
        if (await fileExists(magick)) {
            return resolve(magick);
        }
    }

    // ImageMagick v6
    for (const path of paths) {
        const convert = `${path}/convert`;
        if (await fileExists(convert)) {
            return resolve(convert);
        }
    }

    console.error('Failed to find ImageMagick v6 or v7');
    process.exit(1);
});

/**
 * Converts an SVG string to a PNG file with an optional size.
 *
 * @param {string} svg - The SVG string to be converted.
 * @param {string} filename - The output PNG filename.
 * @param {number} width - The width of the output PNG image. (0 for dynamic)
 * @param {number} height - The height of the output PNG image.
 * @param {boolean} center - Whether to center the image.
 * @returns {Promise<{width: number, height: number}>} - The width and height of the output PNG image.
 */
export async function svg2png(svg, filename, width, height, center = false) {
    const size = `${width}x${height}`;

    const args = ['-background', 'none', '-size', size, 'svg:-'];
    if (center)
        args.push('-gravity', 'Center');
    else
        args.push('-gravity', 'West');

    args.push('-extent', size, `png:${filename}`);

    const convertBin = await convertBinary;
    return new Promise((resolve, reject) => {
        const convert = spawn(convertBin, args);
        convert.on('exit', (code) => {
            if (code !== 0)
                return reject(new Error(`convert exited with code ${code}`));

            resolve({width, height});
        });
        convert.stdin.write(svg);
        convert.stdin.end();
    });
}
