const mongoose = require('mongoose');

const challengeSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  start_text: {
    type: String,
    required: true
  },
  end_text: {
    type: String,
    required: true
  },
  par: {
    type: Number,
    required: true,
    min: 1
  },
  difficulty: {
    type: String,
    enum: ['easy', 'medium', 'hard'],
    default: 'medium'
  },
  description: {
    type: String,
    trim: true
  },
  tags: {
    type: [String],
    default: []
  },
  created_at: {
    type: Date,
    default: Date.now
  },
  is_daily: {
    type: Boolean,
    default: false
  },
  daily_date: {
    type: Date
  }
});

// Index for faster daily challenge queries
challengeSchema.index({ is_daily: 1, daily_date: -1 });

const Challenge = mongoose.model('Challenge', challengeSchema);

module.exports = Challenge; 