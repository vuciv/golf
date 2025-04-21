const Solution = require("../models/Solution");

/**
 * Cleans up solutions with suspiciously low keystroke counts
 * that may be fraudulent or erroneous.
 *
 * @param {number} minKeystrokes Minimum valid keystroke count (default: 5)
 * @returns {Promise<number>} Count of deleted solutions
 */
async function cleanupInvalidSolutions(minKeystrokes = 5) {
  console.log(
    `[Cleanup] Starting cleanup of solutions with less than ${minKeystrokes} keystrokes...`
  );

  try {
    // Find solutions with keystrokes less than min threshold
    const result = await Solution.deleteMany({
      keystrokes: { $lt: minKeystrokes },
    });

    console.log(
      `[Cleanup] Successfully deleted ${result.deletedCount} invalid solutions`
    );
    return result.deletedCount;
  } catch (err) {
    console.error("[Cleanup] Error cleaning up invalid solutions:", err);
    throw err;
  }
}

module.exports = {
  cleanupInvalidSolutions,
};
