import fs from 'fs';
import mathjax from 'mathjax';
import reader from './reader.js';
import { svgDimensions, svg2png } from './magick.js';

import { exec } from 'node:child_process';
import { sha256Hash } from './util.js';
import { randomBytes } from 'node:crypto';
import { onExit } from './onexit.js';

// To prevent conflicts with other instances
const DIRECTORY_SUFFIX = randomBytes(3).toString('hex');

// TODO: Portable directory instead of Unix-specific
const IMG_DIR = `/tmp/nvim-mdmath-${DIRECTORY_SUFFIX}`;

/** @typedef {{equation: string, filename: string}} Equation */

/** @type {Equation[]} */
const equations = [];

/** @type {Object.<string, Equation>} */
const equationMap = {};

const svgCache = {};

let fgColor = '#ff00ff';

let internalScale = 1;

const imgRatio = 0.1

let MathJax = undefined;

function sendNotification(message) {
    exec(`notify-send "Processor.js" '${message}'`, (error, stdout, stderr) => {
        if (error) {
            console.error(`Error: ${error.message}`);
        }
        if (stderr) {
            console.error(`Stderr: ${stderr}`);
        }
    });
}

class MathError extends Error {
    constructor(message) {
        super(message);
        this.name = 'MathError';
    }
}

function mkdirSync(path) {
    try {
        fs.mkdirSync(path, { recursive: true });
    } catch (err) {
        if (err.code !== 'EEXIST') 
            throw err;
    }
}

/**
 * @param {string} equation
 * @returns {Promise<{svg: string} | {error: string}>}
 */
async function equationToSVG(equation) {
    if (equation in svgCache)
        return svgCache[equation];

    try {
        const svg = await MathJax.tex2svgPromise(equation);
        return svgCache[equation] = {
            svg: MathJax.startup.adaptor.innerHTML(svg)
        }
    } catch (err) {
        if (err instanceof MathError) {
            return svgCache[equation] = {
                error: err.message
            }
        } else {

        }

        throw err;
    }
}

function write(identifier, width, height, data) {
    process.stdout.write(`${identifier}:image:${width}:${height}:${data.length}:${data}`);
}

function writeError(identifier, error) {
    process.stdout.write(`${identifier}:error:0:0:${error.length}:${error}`);
}

function parseViewbox(svgString) {
    const viewboxMatch = svgString.match(/viewBox="([^"]+)"/);
    if (!viewboxMatch) return null;

    const [minX, minY, width, height] = viewboxMatch[1].split(' ').map(parseFloat);
    return { minX, minY, width, height };
}

async function saveFile(filename, data) {
    return new Promise((resolve, reject) => {
        fs.writeFile(filename, data, (err) => {
            if (err) {
                reject(err);
            } else {
                resolve();
            }
        });
    });
}

/**
  * @param {string} identifier
  * @param {string} equation
*/
async function processEquation(identifier, equation, cWidth, cHeight, width, height, flags) {
    if (!equation || equation.trim().length === 0)
        return writeError(identifier, 'Equation is empty')

    const equation_key = `${equation}_${cWidth}*${width}x${cHeight}*${height}_${flags}`;
    if (equation_key in equationMap) {
        const equationObj = equationMap[equation_key];
        return write(identifier, equationObj.width, equationObj.height, equationObj.filename);
    }

    let {svg, error} = await equationToSVG(equation);
    if (!svg)
        return writeError(identifier, error)

    svg = svg
        .replace(/currentColor/g, fgColor)
        .replace(/style="[^"]+"/, '')

    const isDynamic = !!(flags & 1);

    let density = null;
    if (isDynamic) {
        // We want to obtain SVG dimensions, we can't rely on viewBox, since for some reason the image 
        // may be cropped, so we are going to use `identify` to get the image size.
        // Also this should be fast, since we can use `identify ping` to get the image without loading it.
        // TODO: Is this fast in ImageMagick v6 too?
        // TODO: Is there a better solution?
        const constant = 10;

        density = constant * cHeight * internalScale;
        const {width: svgWidth, height: svgHeight} = await svgDimensions(svg, {density: density});

        const newWidth = (svgWidth / internalScale) / cWidth;
        const newHeight = (svgHeight / internalScale) / cHeight;
        
        width = Math.ceil(newWidth);
        height = Math.ceil(newHeight);

        sendNotification(`SVG width: ${svgWidth}, SVG height: ${svgHeight}`);
    }

    const hash = sha256Hash(equation).slice(0, 7);

    const iWidth = width * cWidth * internalScale;
    const iHeight = height * cHeight * internalScale;
    
    const isCenter = !!(flags & 2);
    const filename = `${IMG_DIR}/${hash}_${iWidth}x${iHeight}.png`;

    try {
        await svg2png(svg, filename, iWidth, iHeight, {
            resize: true,
            resize: !isDynamic,
            center: isCenter,
            density: density,
        });
    } catch (err) {
        return writeError(identifier, 'System: ' + err.message);
    }

    const equationObj = {equation, filename, width, height};
    equations.push(equationObj);
    equationMap[equation_key] = equationObj;

    write(identifier, width, height, filename);
}

function processAll(request) {
    if (request.type === 'request') {
        return processEquation(
            request.identifier,
            request.data,
            request.cellWidth,
            request.cellHeight,
            request.width,
            request.height,
            request.flags
        );                                                                                                                                                               
  7         // TODO: Display a warning if dimensions ar
    } else if (request.type === 'fgcolor') {
        // FIXME: Invalidate cache when color changes
        fgColor = request.color;
    } else if (request.type === 'scale') {
        // FIXME: Invalidate cache when scale changes
        internalScale = request.scale;
    }
}

function main() {
    mkdirSync(IMG_DIR);

    onExit(() => {
        equations.forEach(({filename}) => {
            try {
                fs.unlinkSync(filename);
            } catch (err) {}
        });

        try {
            fs.rmdirSync(IMG_DIR);
        } catch (err) {}
    });

    mathjax.init({
        loader: { load: ['input/tex', 'output/svg'] },
        tex: {
            formatError: (_, err) => {
                throw new MathError(err.message);
            }
        }
    }).then((MathJax_) => {
        MathJax = MathJax_;
        reader.listen(processAll);
    }).catch((err) => {
        console.error(err);
        process.exit(1);
    });
}

main();
