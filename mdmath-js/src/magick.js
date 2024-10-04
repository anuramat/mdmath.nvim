import { spawn } from 'node:child_process';

const scale = 1

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
export const svg2png = (svg, filename, width, height, center = false) => new Promise((resolve, reject) => {
    let size;
    if (width == 0) {
        size = `x${height * scale}`;
    } else {
        size = `${width * scale}x${height * scale}`;
    }    

    const args = ['-background', 'none', '-size', size, 'svg:-'];
    if (center)
        args.push('-gravity', 'center');
    args.push('-extent', size, `png:${filename}`);

    const convert = spawn('magick', args);
    convert.on('exit', (code) => {
        if (code !== 0)
            return reject(new Error(`convert exited with code ${code}`));

        // const identify = spawn('identify', [filename]);

        // const buf = [];
        // identify.stdout.on('data', (data) => {
        //     buf.push(data);
        // });

        // identify.on('exit', (code) => {
        //     if (code !== 0)
        //         return reject(new Error(`identify exited with code ${code}`));

        //     const size = buf.join('').split(' ')[2];
        //     const [width, height] = size.split('x').map(Number);

        //     resolve({width, height});
        // });

        resolve({width, height});
    });
    convert.stdin.write(svg);
    convert.stdin.end();
});
