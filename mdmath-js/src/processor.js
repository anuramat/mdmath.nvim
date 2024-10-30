import fs from 'fs';
import mathjax from 'mathjax';
import reader from './reader.js';
import { svg2png } from './magick.js';

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

let imageScale = 1;

let MathJax = undefined;

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

function write(identifier, data) {
    process.stdout.write(`${identifier}:data:${data.length}:${data}`);
}

function writeError(identifier, error) {
    process.stdout.write(`${identifier}:error:${error.length}:${error}`);
}

/**
  * @param {string} identifier
  * @param {string} equation
*/
async function processEquation(identifier, width, height, center, equation) {
    if (!equation || equation.trim().length === 0)
        return writeError(identifier, 'Equation is empty')

    width *= imageScale;
    height *= imageScale;

    const equation_key = `${equation}_${width}x${height}`;
    if (equation_key in equationMap) {
        const equationObj = equationMap[equation_key];
        return write(identifier, equationObj.filename);
    }

    let {svg, error} = await equationToSVG(equation);
    if (!svg)
        return writeError(identifier, error)
    svg = svg.replace(/currentColor/g, fgColor);

    const hash = sha256Hash(equation).slice(0, 7);

    const filename = `${IMG_DIR}/${hash}_${width}x${height}.png`;
    try {
        await svg2png(svg, filename, width, height, center);
    } catch (err) {
        return writeError(identifier, 'System: ' + err.message);
    }

    const equationObj = {equation, filename};
    equations.push(equationObj);
    equationMap[equation_key] = equationObj;

    write(identifier, filename);
}

function processAll(request) {
    if (request.type === 'request') {
        return processEquation(
            request.identifier,
            request.width,
            request.height,
            request.center,
            request.data
        );
    } else if (request.type === 'fgcolor') {
        // FIXME: Invalidate cache when color changes
        fgColor = request.color;
    } else if (request.type === 'scale') {
        imageScale = request.scale;
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
