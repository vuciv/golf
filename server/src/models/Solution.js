const mongoose = require("mongoose");

const solutionSchema = new mongoose.Schema({
  challenge: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Challenge",
    required: true,
  },
  keystrokes: {
    type: Number,
    required: true,
    min: 1,
  },
  keylog: [
    {
      key: String,
      timestamp: {
        type: Date,
        required: false,
      },
    },
  ],
  time_taken: {
    type: Number, // in seconds
    required: true,
  },
  score: {
    type: Number,
    required: true,
  },
  submitted_at: {
    type: Date,
    default: Date.now,
  },
  user_id: {
    type: String,
    required: true,
  },
});

// Index for faster leaderboard queries
solutionSchema.index({ challenge: 1, keystrokes: 1 });

const Solution = mongoose.model("Solution", solutionSchema);

module.exports = Solution;
