import { randomBytes, createHash } from 'node:crypto';

const sha256 = createHash('sha256');

/**
 * Computes the SHA-256 hash of the given data.
 * @param {string} data - The input data to be hashed.
 * @returns {string} The SHA-256 hash of the input data as a hexadecimal string.
 */
export function sha256Hash(data) {
    sha256.update(data, 'utf8');
    return sha256.copy().digest('hex');
}
