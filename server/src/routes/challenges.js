const express = require('express');
const router = express.Router();
const Challenge = require('../models/Challenge');

// Get daily challenge
router.get('/daily', async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let dailyChallenge = await Challenge.findOne({
      is_daily: true,
      daily_date: today
    });

    // If no challenge is set for today, get a random one and set it as daily
    if (!dailyChallenge) {
      const randomChallenge = await Challenge.findOne({
        is_daily: false
      }).sort({ created_at: -1 });

      if (!randomChallenge) {
        return res.status(404).json({ error: 'No challenges available' });
      }

      // Clone the challenge and set it as daily
      dailyChallenge = new Challenge({
        ...randomChallenge.toObject(),
        _id: undefined,
        is_daily: true,
        daily_date: today
      });
      await dailyChallenge.save();
    }

    res.json({
      id: dailyChallenge._id,
      title: dailyChallenge.title,
      start_text: dailyChallenge.start_text,
      end_text: dailyChallenge.end_text,
      par: dailyChallenge.par,
      difficulty: dailyChallenge.difficulty,
      description: dailyChallenge.description
    });
  } catch (err) {
    console.error('Error fetching daily challenge:', err);
    res.status(500).json({ error: 'Failed to fetch daily challenge' });
  }
});

// Get specific challenge by ID
router.get('/:id', async (req, res) => {
  try {
    const challenge = await Challenge.findById(req.params.id);
    
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
      description: challenge.description
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
      description: req.body.description
    });

    await challenge.save();
    res.status(201).json(challenge);
  } catch (err) {
    console.error('Error creating challenge:', err);
    res.status(500).json({ error: 'Failed to create challenge' });
  }
});

module.exports = router; 