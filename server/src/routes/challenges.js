const express = require('express');
const router = express.Router();
const Challenge = require('../models/Challenge');

// Get all challenges
router.get('/all', async (req, res) => {
  try {
    const challenges = await Challenge.find({ 
      is_daily: false,
      is_approved: true // Only return approved challenges
    })
      .select('title description par difficulty tags')
      .sort({ created_at: -1 });

    res.json(challenges);
  } catch (err) {
    console.error('Error fetching challenges:', err);
    res.status(500).json({ error: 'Failed to fetch challenges' });
  }
});

// Get daily challenge
router.get('/daily', async (req, res) => {
  try {
    // Get today's date in UTC, zeroed to midnight UTC
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);

    let dailyChallenge = await Challenge.findOne({
      is_daily: true,
      daily_date: today
    });

    // If no challenge is set for today, get a random approved one and set it as daily
    if (!dailyChallenge) {
      const randomChallenge = await Challenge.findOne({
        is_daily: false,
        is_approved: true // Only use approved challenges for daily challenges
      }).sort({ created_at: -1 });

      if (!randomChallenge) {
        return res.status(404).json({ error: 'No challenges available' });
      }

      // Update the found challenge to make it today's daily challenge
      randomChallenge.is_daily = true;
      randomChallenge.daily_date = today;
      // The challenge is already approved, so no need to change is_approved
      await randomChallenge.save();
      dailyChallenge = randomChallenge; // Use the updated challenge
    }

    // Format date as YYYY-MM-DD in UTC
    const formattedDate = dailyChallenge.daily_date.toISOString().split('T')[0];

    res.json({
      id: dailyChallenge._id,
      title: dailyChallenge.title,
      start_text: dailyChallenge.start_text,
      end_text: dailyChallenge.end_text,
      par: dailyChallenge.par,
      difficulty: dailyChallenge.difficulty,
      description: dailyChallenge.description,
      tags: dailyChallenge.tags,
      daily_date: formattedDate
    });
  } catch (err) {
    console.error('Error fetching daily challenge:', err);
    res.status(500).json({ error: 'Failed to fetch daily challenge' });
  }
});

// Get random challenge by difficulty, tag, or any
router.get('/random', async (req, res) => {
  const { difficulty, tag } = req.query;
  const validDifficulties = ['easy', 'medium', 'hard'];
  let matchCriteria = { is_approved: true }; // Default: match any approved challenge

  if (difficulty) {
    if (!validDifficulties.includes(difficulty.toLowerCase())) {
      return res.status(400).json({ error: 'Invalid difficulty parameter. Use easy, medium, or hard.' });
    }
    matchCriteria.difficulty = difficulty.toLowerCase();
  } else if (tag) {
    // Match approved challenges that contain the specified tag
    matchCriteria.tags = { $in: [tag] };
  }

  try {
    const randomChallenges = await Challenge.aggregate([
      { $match: matchCriteria },
      { $sample: { size: 1 } }
    ]);

    if (!randomChallenges || randomChallenges.length === 0) {
      let errorMessage = 'No challenges found';
      if (difficulty) errorMessage += ` for difficulty: ${difficulty}`;
      if (tag) errorMessage += ` with tag: ${tag}`;
      return res.status(404).json({ error: `${errorMessage}.` });
    }

    const challenge = randomChallenges[0];

    res.json({
      id: challenge._id,
      title: challenge.title,
      start_text: challenge.start_text,
      end_text: challenge.end_text,
      par: challenge.par,
      difficulty: challenge.difficulty,
      description: challenge.description,
      tags: challenge.tags
    });
  } catch (err) {
    console.error(`Error fetching random challenge:`, err);
    res.status(500).json({ error: 'Failed to fetch random challenge' });
  }
});

// Get challenge by specific date (YYYY-MM-DD)
router.get('/date/:date', async (req, res) => {
  const { date } = req.params;
  // Basic validation for YYYY-MM-DD format
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'Invalid date format. Use YYYY-MM-DD.' });
  }

  try {
    // Parse date as UTC midnight
    const targetDate = new Date(date + 'T00:00:00.000Z');
    if (isNaN(targetDate.getTime())) {
      return res.status(400).json({ error: 'Invalid date value.' });
    }

    // Find the challenge marked as daily for the target date
    const challenge = await Challenge.findOne({
      is_daily: true,
      daily_date: targetDate
    });

    if (!challenge) {
      return res.status(404).json({ error: `No daily challenge found for date: ${date}` });
    }

    // Format date as YYYY-MM-DD in UTC
    const formattedDate = challenge.daily_date.toISOString().split('T')[0];

    res.json({
      id: challenge._id,
      title: challenge.title,
      start_text: challenge.start_text,
      end_text: challenge.end_text,
      par: challenge.par,
      difficulty: challenge.difficulty,
      description: challenge.description,
      tags: challenge.tags,
      daily_date: formattedDate
    });
  } catch (err) {
    console.error(`Error fetching challenge for date ${date}:`, err);
    res.status(500).json({ error: 'Failed to fetch challenge by date' });
  }
});

// Get specific challenge by ID
router.get('/:id', async (req, res) => {
  try {
    const challenge = await Challenge.findOne({
      _id: req.params.id,
      is_approved: true // Only return approved challenges
    });
    
    if (!challenge) {
      return res.status(404).json({ error: 'Challenge not found' });
    }

    res.json({
      id: challenge._id,
      title: challenge.title,
      start_text: challenge.start_text,
      end_text: challenge.end_text,
      par: challenge.par,
      difficulty: challenge.difficulty,
      description: challenge.description,
      tags: challenge.tags
    });
  } catch (err) {
    console.error('Error fetching challenge:', err);
    res.status(500).json({ error: 'Failed to fetch challenge' });
  }
});

// Create a new challenge (protected route - would need auth middleware)
router.post('/', async (req, res) => {
  try {
    const challenge = new Challenge({
      title: req.body.title,
      start_text: req.body.start_text,
      end_text: req.body.end_text,
      par: req.body.par,
      difficulty: req.body.difficulty,
      description: req.body.description,
      tags: req.body.tags || [],
      is_approved: false // All new submissions start as unapproved
    });

    await challenge.save();
    res.status(201).json({ 
      message: 'Challenge submitted successfully. It will be reviewed before being made public.',
      id: challenge._id
    });
  } catch (err) {
    console.error('Error creating challenge:', err);
    res.status(500).json({ error: 'Failed to create challenge' });
  }
});

module.exports = router; 