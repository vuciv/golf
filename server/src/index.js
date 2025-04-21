const express = require("express");
const cors = require("cors");
const morgan = require("morgan");
const helmet = require("helmet");
const mongoose = require("mongoose");
const path = require("path");
require("dotenv").config();

const challengesRouter = require("./routes/challenges");
const solutionsRouter = require("./routes/solutions");
const { cleanupInvalidSolutions } = require("./utils/cleanup");

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(
  helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        scriptSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com"],
        styleSrc: ["'self'", "'unsafe-inline'", "https://cdn.tailwindcss.com"],
        connectSrc: ["'self'", "https://cdn.tailwindcss.com"],
      },
    },
  })
); // Security headers with CSP configured
app.use(cors()); // Enable CORS
app.use(morgan("dev")); // Logging
app.use(express.json()); // Parse JSON bodies

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, "../public")));

// Routes
app.use("/v1/challenges", challengesRouter);
app.use("/v1/solutions", solutionsRouter);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});

// Connect to MongoDB
mongoose
  .connect(process.env.MONGODB_URI || "mongodb://localhost/vimgolf")
  .then(() => {
    console.log("Connected to MongoDB");

    // Run cleanup tasks after successful database connection
    cleanupInvalidSolutions()
      .then((count) => {
        if (count > 0) {
          console.log(
            `Server startup: Removed ${count} invalid solutions with less than 5 keystrokes`
          );
        } else {
          console.log("Server startup: No invalid solutions found");
        }
      })
      .catch((err) =>
        console.error("Failed to clean up invalid solutions:", err)
      );
  })
  .catch((err) => console.error("MongoDB connection error:", err));

// Start server
app.listen(port, () => {
  console.log(`VimGolf server listening at http://localhost:${port}`);
});
