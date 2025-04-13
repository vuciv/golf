const express = require('express');
const router = express.Router();
const Solution = require('../models/Solution');
const Challenge = require('../models/Challenge');

// Submit a solution
router.post('/', async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.body.challenge_id);
    if (!challenge) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    const solution = new Solution({
      challenge: challenge._id,
      keystrokes: req.body.keystrokes,
      keylog: req.body.keylog,
      time_taken: req.body.time_taken,
      score: req.body.score,
      user_id: req.body.user_id // Would come from auth middleware in production
    });

    await solution.save();
    res.status(201).json(solution);
  } catch (err) {
    console.error('Error submitting solution:', err);
    res.status(500).json({ error: 'Failed to submit solution' });
  }
});

// Get leaderboard for a challenge
router.get('/leaderboard/:challenge_id', async (req, res) => {
  try {
    const solutions = await Solution.find({ challenge: req.params.challenge_id })
      .sort({ keystrokes: 1, time_taken: 1 })
      .limit(10)
      .select('keystrokes time_taken score user_id submitted_at keylog');

    res.json(solutions);
  } catch (err) {
    console.error('Error fetching leaderboard:', err);
    res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
});

module.exports = router; 